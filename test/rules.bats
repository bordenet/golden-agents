#!/usr/bin/env bats
# Section C: scoped rules for Claude, Cursor, and Copilot.
# Language rules carry a path glob. Invariants and security always load.
# A hand-written rule without the sentinel is left alone.

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

@test "progressive generation writes scoped rules and drops the exchange trigger" {
    run "$GENERATE_SCRIPT" --language=go --type=cli-tools --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    grep -q 'paths:' "$TEST_DIR/.claude/rules/go.md"
    grep -q '\*\*/\*.go' "$TEST_DIR/.claude/rules/go.md"
    grep -q 'golangci-lint' "$TEST_DIR/.claude/rules/go.md"
    grep -qxF '<!-- golden-agents:generated -->' "$TEST_DIR/.claude/rules/go.md"
    grep -q 'globs:' "$TEST_DIR/.cursor/rules/go.mdc"
    grep -q 'alwaysApply: false' "$TEST_DIR/.cursor/rules/go.mdc"
    grep -q 'applyTo:' "$TEST_DIR/.github/instructions/go.instructions.md"
    grep -q 'alwaysApply: true' "$TEST_DIR/.cursor/rules/security.mdc"
    grep -q 'alwaysApply: true' "$TEST_DIR/.cursor/rules/invariants.mdc"
    grep -q 'Critical Invariants' "$TEST_DIR/.claude/rules/invariants.md"
    ! grep -q '^paths:' "$TEST_DIR/.claude/rules/invariants.md"
    grep -q 'alwaysApply: true' "$TEST_DIR/.cursor/rules/cli-tools.mdc"
    ! grep -q '50 exchanges' "$TEST_DIR/AGENTS.md"
    ! grep -q 'context-management' "$TEST_DIR/AGENTS.md"
    [ ! -e "$TEST_DIR/.golden-agents/modules/context-management.md" ]
    grep -q 'CI or a hook' "$TEST_DIR/AGENTS.md"
}

@test "dry-run writes no rule files" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"would write .claude/rules/go.md"* ]]
    [ ! -e "$TEST_DIR/.claude" ]
    [ ! -e "$TEST_DIR/.cursor" ]
    [ ! -e "$TEST_DIR/.github/instructions" ]
}

@test "a hand-written cursor rule is left in place" {
    mkdir -p "$TEST_DIR/.cursor/rules"
    printf '# Our Go rules\nUse the team linter config.\n' > "$TEST_DIR/.cursor/rules/go.mdc"
    cp "$TEST_DIR/.cursor/rules/go.mdc" "$TEST_DIR/go.before"

    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    cmp "$TEST_DIR/go.before" "$TEST_DIR/.cursor/rules/go.mdc"
    [[ "$output" == *"left .cursor/rules/go.mdc"* ]]
    grep -q 'golangci-lint' "$TEST_DIR/.claude/rules/go.md"
}

@test "upgrade --apply refreshes a generated rule and preview writes nothing" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    printf '\nlocal edit\n' >> "$TEST_DIR/.claude/rules/go.md"
    cp "$TEST_DIR/.claude/rules/go.md" "$TEST_DIR/rule.before"

    run "$GENERATE_SCRIPT" --upgrade --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"would update .claude/rules/go.md"* ]]
    cmp "$TEST_DIR/rule.before" "$TEST_DIR/.claude/rules/go.md"

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    grep -q 'golangci-lint' "$TEST_DIR/.claude/rules/go.md"
    ! grep -q 'local edit' "$TEST_DIR/.claude/rules/go.md"
}
