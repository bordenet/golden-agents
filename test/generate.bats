#!/usr/bin/env bats
# P2: New File Generation Tests
# Tests for generating new AGENTS.md files

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# Test 1: Progressive mode generates minimal file (default)
@test "progressive mode generates reasonable file size" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]

    assert_file_exists "$TEST_DIR/AGENTS.md"
    assert_progressive_size "$TEST_DIR/AGENTS.md"
}

# Test 2: Explicit progressive flag works
@test "explicit progressive flag works" {
    run "$GENERATE_SCRIPT" --language=go --progressive --path="$TEST_DIR"
    [ "$status" -eq 0 ]

    assert_file_exists "$TEST_DIR/AGENTS.md"
    # Progressive mode generates ~60-80 lines (minimal core with on-demand loading)
    local line_count
    line_count=$(wc -l < "$TEST_DIR/AGENTS.md" | tr -d ' ')
    [ "$line_count" -gt 40 ]  # Must have some content
    [ "$line_count" -lt 100 ] # Progressive should be under 100 lines
}

# Test 3: Output contains start marker
@test "generated file contains start marker" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]

    assert_file_contains "$TEST_DIR/AGENTS.md" "GOLDEN:framework:start"
}

# Test 4: Output contains end marker
@test "generated file contains end marker" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]

    assert_file_contains "$TEST_DIR/AGENTS.md" "GOLDEN:framework:end"
}

# Test 5: Output contains language header
@test "generated file contains language header" {
    run "$GENERATE_SCRIPT" --language=python --path="$TEST_DIR"
    [ "$status" -eq 0 ]

    assert_file_contains "$TEST_DIR/AGENTS.md" "python"
}

# Test 6: Output contains type header
@test "generated file contains type header" {
    run "$GENERATE_SCRIPT" --language=go --type=cli-tools --path="$TEST_DIR"
    [ "$status" -eq 0 ]

    assert_file_contains "$TEST_DIR/AGENTS.md" "cli-tools"
}

# Test 7: Creates output directory if missing
@test "creates output directory if missing" {
    local new_dir="$TEST_DIR/nonexistent/nested/dir"

    run "$GENERATE_SCRIPT" --language=go --path="$new_dir"
    [ "$status" -eq 0 ]

    assert_dir_exists "$new_dir"
    assert_file_exists "$new_dir/AGENTS.md"
}

# Test 8: Project name from directory
@test "project name derived from directory" {
    local project_dir="$TEST_DIR/my-cool-project"
    mkdir -p "$project_dir"

    run "$GENERATE_SCRIPT" --language=go --path="$project_dir"
    [ "$status" -eq 0 ]

    assert_file_contains "$project_dir/AGENTS.md" "my-cool-project"
}

# Test 9: Custom project name
@test "custom project name used when provided" {
    run "$GENERATE_SCRIPT" --language=go --name=CustomProjectName --path="$TEST_DIR"
    [ "$status" -eq 0 ]

    assert_file_contains "$TEST_DIR/AGENTS.md" "CustomProjectName"
}

# Test 10: Multiple languages in header
@test "multiple languages appear in header" {
    run "$GENERATE_SCRIPT" --language=go,python,javascript --path="$TEST_DIR"
    [ "$status" -eq 0 ]

    # All languages should appear
    assert_file_contains "$TEST_DIR/AGENTS.md" "go"
    assert_file_contains "$TEST_DIR/AGENTS.md" "python"
    assert_file_contains "$TEST_DIR/AGENTS.md" "javascript"
}


# Test 11: Multi-language projects get gates for every language
@test "multi-language generation emits labeled gates for each language" {
    run "$GENERATE_SCRIPT" --language=go,python,javascript --type=cli-tools --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    local f="$TEST_DIR/AGENTS.md"
    assert_file_contains "$f" '^- \*\*go\*\*$'
    assert_file_contains "$f" '^- \*\*python\*\*$'
    assert_file_contains "$f" '^- \*\*javascript\*\*$'
    assert_file_contains "$f" 'golangci-lint run'
    assert_file_contains "$f" 'pylint --fail-under'
    assert_file_contains "$f" 'npm run lint'
    assert_progressive_size "$f"
}

# Test 12: Single-language gate format is unchanged
@test "single-language generation keeps the unlabeled gate list" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    grep -A1 -x 'Before a commit:' "$TEST_DIR/AGENTS.md" | grep -q '^1\. \*\*Lint\*\*: `golangci-lint run ./...`$'
}

# Test 13: Too many languages for per-language gates falls back to naming them
@test "generation names uncovered languages when per-language gates exceed the line budget" {
    run "$GENERATE_SCRIPT" --language=go,python,javascript,shell,dart-flutter --type=cli-tools --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    assert_file_contains "$TEST_DIR/AGENTS.md" 'gates shown for go; add equivalents for python, javascript, shell, dart-flutter'
    assert_progressive_size "$TEST_DIR/AGENTS.md"
}

# Test 14: No coverage line when the language has no coverage target
@test "shell generation omits the coverage gate instead of printing N/A%" {
    run "$GENERATE_SCRIPT" --language=shell --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    assert_file_not_contains "$TEST_DIR/AGENTS.md" 'N/A%'
    assert_file_not_contains "$TEST_DIR/AGENTS.md" 'Coverage'
    assert_file_contains "$TEST_DIR/AGENTS.md" '3\. \*\*Test\*\*: `bats test/`'
}

# Test 15: Coverage line stays for languages with a target
@test "go generation keeps the coverage gate" {
    run "$GENERATE_SCRIPT" --language=go,shell --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    assert_file_contains "$TEST_DIR/AGENTS.md" 'Coverage\*\*: Minimum 80%'
    assert_file_not_contains "$TEST_DIR/AGENTS.md" 'N/A%'
}
