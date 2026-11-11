#!/usr/bin/env bats
# Section H: quality gates come from the project when a command is exact.

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

@test "empty project marks template gates unverified" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    assert_file_contains "$TEST_DIR/AGENTS.md" 'UNVERIFIED: confirm golangci-lint run ./...'
    assert_file_contains "$TEST_DIR/AGENTS.md" 'UNVERIFIED: confirm go test -race'
    assert_file_contains "$TEST_DIR/AGENTS.md" 'Coverage\*\*: Minimum 80%'
}

@test "package.json scripts replace the template and cite the file" {
    printf '%s\n' '{"scripts":{"lint":"eslint .","test":"vitest","build":"tsc","coverage":"vitest run --coverage","lint:fix":"eslint . --fix"}}' \
        > "$TEST_DIR/package.json"
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    assert_file_contains "$TEST_DIR/AGENTS.md" '1\. \*\*Lint\*\*: `npm run lint` (package.json)'
    assert_file_contains "$TEST_DIR/AGENTS.md" '2\. \*\*Build\*\*: `npm run build` (package.json)'
    assert_file_contains "$TEST_DIR/AGENTS.md" '3\. \*\*Test\*\*: `npm run test` (package.json)'
    assert_file_contains "$TEST_DIR/AGENTS.md" '4\. \*\*Coverage\*\*: `npm run coverage` (package.json)'
    assert_file_not_contains "$TEST_DIR/AGENTS.md" 'lint:fix'
    assert_file_not_contains "$TEST_DIR/AGENTS.md" 'UNVERIFIED'
    assert_file_not_contains "$TEST_DIR/AGENTS.md" 'Minimum 80%'
}

@test "Makefile fills only the commands package.json did not define" {
    printf '%s\n' '{"scripts":{"test":"vitest"}}' > "$TEST_DIR/package.json"
    printf '%s\n' 'test: deps' '	go test ./...' 'lint:' '	golangci-lint run' > "$TEST_DIR/Makefile"
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    assert_file_contains "$TEST_DIR/AGENTS.md" '3\. \*\*Test\*\*: `npm run test` (package.json)'
    assert_file_contains "$TEST_DIR/AGENTS.md" '1\. \*\*Lint\*\*: `make lint` (Makefile)'
    assert_file_not_contains "$TEST_DIR/AGENTS.md" 'make test'
}

@test "justfile and pyproject and a workflow step supply commands in order" {
    printf '%s\n' 'build:' '	go build ./...' > "$TEST_DIR/justfile"
    printf '%s\n' '[project.scripts]' 'lint = "ruff check ."' 'test = "pkg.mod:main"' > "$TEST_DIR/pyproject.toml"
    mkdir -p "$TEST_DIR/.github/workflows"
    printf '%s\n' 'jobs:' '  check:' '    steps:' '      - name: test' '        run: uv run pytest' \
        > "$TEST_DIR/.github/workflows/ci.yml"
    run "$GENERATE_SCRIPT" --language=python --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    assert_file_contains "$TEST_DIR/AGENTS.md" '2\. \*\*Build\*\*: `just build` (justfile)'
    assert_file_contains "$TEST_DIR/AGENTS.md" '1\. \*\*Lint\*\*: `ruff check .` (pyproject.toml)'
    assert_file_contains "$TEST_DIR/AGENTS.md" '3\. \*\*Test\*\*: `uv run pytest` (.github/workflows/ci.yml)'
    assert_file_not_contains "$TEST_DIR/AGENTS.md" 'pkg.mod:main'
}

@test "shell still omits the coverage percentage when no coverage command exists" {
    run "$GENERATE_SCRIPT" --language=shell --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    assert_file_not_contains "$TEST_DIR/AGENTS.md" 'Coverage'
    assert_file_contains "$TEST_DIR/AGENTS.md" 'UNVERIFIED: confirm bats test/'
}

@test "upgrade keeps existing shell gates and does not invent npm" {
    cat > "$TEST_DIR/AGENTS.md" << 'EOF'
# AI Agent Guidelines - Demo

> **Languages**: shell,javascript
> **Type**: cli-tools

<!-- GOLDEN:framework:start -->

## Quality Gates

Before ANY commit:
1. **Lint**: `shellcheck *.sh`
2. **Build**: `bash -n *.sh`
3. **Test**: `bats test/`

<!-- GOLDEN:framework:end -->

## Project-Specific Rules

Keep this sentence.
EOF
    run "$GENERATE_SCRIPT" --upgrade --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    added=$(printf '%s\n' "$output" | grep '^+' || true)
    [[ "$added" == *'1. **Lint**: `shellcheck *.sh`'* ]]
    [[ "$added" == *'2. **Build**: `bash -n *.sh`'* ]]
    [[ "$added" == *'3. **Test**: `bats test/`'* ]]
    [[ "$added" != *'UNVERIFIED: confirm'* ]]
    [[ "$output" != *'npm run'* ]]
    [[ "$output" != *'npm test'* ]]
    [[ "$output" == *'--- Gates left unset ---'* ]]
    [[ "$output" == *'javascript'* ]]
    grep -q 'Keep this sentence.' "$TEST_DIR/AGENTS.md"
}

@test "upgrade keeps a custom command that matches no language template" {
    cat > "$TEST_DIR/AGENTS.md" << 'EOF'
# AI Agent Guidelines - Demo

> **Languages**: shell,javascript
> **Type**: cli-tools

<!-- GOLDEN:framework:start -->

## Quality Gates

1. **Lint**: `shellcheck *.sh`
2. **Build**: `bash -n *.sh`
3. **Test**: `bash tools/test-all.sh`

<!-- GOLDEN:framework:end -->
EOF
    run "$GENERATE_SCRIPT" --upgrade --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    added=$(printf '%s\n' "$output" | grep '^+' || true)
    [[ "$added" == *'3. **Test**: `bash tools/test-all.sh`'* ]]
    [[ "$added" != *'bats test/'* ]]
    [[ "$added" != *'npm test'* ]]
}

@test "upgrade prefers a detected command over the command already in the file" {
    cat > "$TEST_DIR/AGENTS.md" << 'EOF'
# AI Agent Guidelines - Demo

> **Languages**: shell
> **Type**: cli-tools

<!-- GOLDEN:framework:start -->

## Quality Gates

1. **Test**: `bats test/`

<!-- GOLDEN:framework:end -->
EOF
    printf '%s\n' 'test:' '	true' > "$TEST_DIR/Makefile"
    run "$GENERATE_SCRIPT" --upgrade --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *'3. **Test**: `make test` (Makefile)'* ]]
    added=$(printf '%s\n' "$output" | grep '^+' || true)
    [[ "$added" != *'bats test/'* ]]
}
