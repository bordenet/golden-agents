#!/usr/bin/env bats
# .gitignore append tests
# Every append site must keep existing entries intact when the file lacks a
# trailing newline.

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    printf 'dist' > "$TEST_DIR/.gitignore"
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# assert_gitignore_lines <entry...>
# Asserts "dist" and each entry appear as whole lines.
assert_gitignore_lines() {
    grep -qxF "dist" "$TEST_DIR/.gitignore" || { cat "$TEST_DIR/.gitignore" >&2; return 1; }
    local entry
    for entry in "$@"; do
        grep -qxF "$entry" "$TEST_DIR/.gitignore" || { cat "$TEST_DIR/.gitignore" >&2; return 1; }
    done
}

@test "GITIGNORE: --migrate appends on its own line when file lacks trailing newline" {
    create_realistic_claude_md "$TEST_DIR"
    run "$GENERATE_SCRIPT" --migrate --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    assert_gitignore_lines "MIGRATION-PROMPT.md"
}

@test "GITIGNORE: --adopt appends both entries on their own lines" {
    create_agents_without_markers "$TEST_DIR"
    run "$GENERATE_SCRIPT" --adopt --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    assert_gitignore_lines "ADOPT-PROMPT.md" "AGENTS.md.original"
}

@test "GITIGNORE: --dedupe appends on its own line" {
    create_bloated_agents_with_markers "$TEST_DIR" 150
    run "$GENERATE_SCRIPT" --dedupe --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    assert_gitignore_lines "ADOPT-PROMPT.md"
}

@test "GITIGNORE: upgrade modular prompt appends on its own line" {
    create_bloated_agents_with_markers "$TEST_DIR" 300
    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    assert_gitignore_lines "MODULAR-MIGRATION-PROMPT.md"
}

@test "GITIGNORE: an entry already present is not added again" {
    printf 'dist\nMIGRATION-PROMPT.md\n' > "$TEST_DIR/.gitignore"
    create_realistic_claude_md "$TEST_DIR"
    run "$GENERATE_SCRIPT" --migrate --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ "$(grep -cxF 'MIGRATION-PROMPT.md' "$TEST_DIR/.gitignore")" -eq 1 ]
}
