#!/usr/bin/env bats
# Section B: selected templates are copied into the consumer repo.
# Triggers point at those relative paths, not $HOME/.golden-agents.

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

@test "progressive generation copies selected modules and points triggers at them" {
    run "$GENERATE_SCRIPT" --language=go --type=cli-tools --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    cmp "$SCRIPT_DIR/templates/languages/go.md" "$TEST_DIR/.golden-agents/modules/go.md"
    cmp "$SCRIPT_DIR/templates/workflows/security.md" "$TEST_DIR/.golden-agents/modules/security.md"
    cmp "$SCRIPT_DIR/templates/workflows/testing.md" "$TEST_DIR/.golden-agents/modules/testing.md"
    cmp "$SCRIPT_DIR/templates/project-types/cli-tools.md" "$TEST_DIR/.golden-agents/modules/cli-tools.md"
    [ ! -e "$TEST_DIR/.golden-agents/modules/python.md" ]
    grep -q 'Read `.golden-agents/modules/go.md`' "$TEST_DIR/AGENTS.md"
    grep -q 'Read `.golden-agents/modules/security.md`' "$TEST_DIR/AGENTS.md"
    grep -q 'Read `.golden-agents/modules/cli-tools.md`' "$TEST_DIR/AGENTS.md"
    ! grep -q 'HOME/.golden-agents' "$TEST_DIR/AGENTS.md"
}

@test "modules comment records the sha256 of each copied file" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    local hash
    hash=$(sha256sum "$TEST_DIR/.golden-agents/modules/go.md" | awk '{ print $1 }')
    grep -q "go=${hash}" "$TEST_DIR/AGENTS.md"
    grep -q '<!-- golden-agents:modules ' "$TEST_DIR/AGENTS.md"
}

@test "dry-run writes no module files" {
    run "$GENERATE_SCRIPT" --language=go --type=cli-tools --path="$TEST_DIR" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"would write .golden-agents/modules/go.md"* ]]
    [ ! -e "$TEST_DIR/.golden-agents" ]
    [ ! -e "$TEST_DIR/AGENTS.md" ]
}

@test "full mode does not copy modules or mention HOME" {
    run "$GENERATE_SCRIPT" --full --language=shell --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ ! -e "$TEST_DIR/.golden-agents" ]
    ! grep -q 'golden-agents:modules' "$TEST_DIR/AGENTS.md"
    ! grep -q 'HOME/.golden-agents' "$TEST_DIR/AGENTS.md"
}

@test "upgrade preview shows a module hash diff and writes nothing" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    printf '\nlocal edit\n' >> "$TEST_DIR/.golden-agents/modules/go.md"
    cp "$TEST_DIR/AGENTS.md" "$TEST_DIR/agents.before"
    cp "$TEST_DIR/.golden-agents/modules/go.md" "$TEST_DIR/go.before"

    run "$GENERATE_SCRIPT" --upgrade --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"would update .golden-agents/modules/go.md"* ]]
    [[ "$output" == *"have"* ]]
    [[ "$output" == *"template"* ]]
    cmp "$TEST_DIR/agents.before" "$TEST_DIR/AGENTS.md"
    cmp "$TEST_DIR/go.before" "$TEST_DIR/.golden-agents/modules/go.md"
}

@test "upgrade --apply replaces a changed module with the template bytes" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    printf '\nlocal edit\n' >> "$TEST_DIR/.golden-agents/modules/testing.md"

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    cmp "$SCRIPT_DIR/templates/workflows/testing.md" "$TEST_DIR/.golden-agents/modules/testing.md"
}
