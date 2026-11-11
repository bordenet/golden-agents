#!/usr/bin/env bats
# Self-Management Tests - Bootstrap block and bloat detection

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# Test 1: New file contains self-manage block
@test "new file contains self-manage block" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    assert_file_contains "$TEST_DIR/AGENTS.md" "GOLDEN:self-manage:start"
    assert_file_contains "$TEST_DIR/AGENTS.md" ">250 lines"
}

# Test 2: Self-manage block appears before framework markers
@test "self-manage block appears before framework markers" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    # Get line numbers
    local self_manage_line framework_line
    self_manage_line=$(grep -n "GOLDEN:self-manage:start" "$TEST_DIR/AGENTS.md" | head -1 | cut -d: -f1)
    framework_line=$(grep -n "GOLDEN:framework:start" "$TEST_DIR/AGENTS.md" | head -1 | cut -d: -f1)
    
    # Self-manage should come before framework
    [ "$self_manage_line" -lt "$framework_line" ]
}

# Test 3: Self-manage block contains bootstrap instructions
@test "self-manage block contains bootstrap instructions" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    assert_file_contains "$TEST_DIR/AGENTS.md" "Before ANY Task"
    assert_file_contains "$TEST_DIR/AGENTS.md" "Load.*invariants.md"
}

# Test 4: Self-manage block is properly closed
@test "self-manage block is properly closed" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    assert_file_contains "$TEST_DIR/AGENTS.md" "GOLDEN:self-manage:end"
}

# Test 5: Upgrade adds self-manage block to existing file
@test "upgrade adds self-manage block to existing file" {
    # Create an existing file WITH framework markers but WITHOUT self-manage block
    create_agents_with_markers "$TEST_DIR"

    # Verify no self-manage block initially
    run grep "GOLDEN:self-manage" "$TEST_DIR/AGENTS.md"
    [ "$status" -ne 0 ]

    # Run upgrade
    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]

    # Verify self-manage block was added
    assert_file_contains "$TEST_DIR/AGENTS.md" "GOLDEN:self-manage:start"
    assert_file_contains "$TEST_DIR/AGENTS.md" ">250 lines"
}

# Test 6: Upgrade preserves existing self-manage block
@test "upgrade preserves existing self-manage block" {
    # Generate a fresh file (which has self-manage block)
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]

    # Verify self-manage block exists
    assert_file_contains "$TEST_DIR/AGENTS.md" "GOLDEN:self-manage:start"

    # Count self-manage markers before upgrade
    local before_count
    before_count=$(grep -c "GOLDEN:self-manage:start" "$TEST_DIR/AGENTS.md")

    # Run upgrade
    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]

    # Verify exactly one self-manage block (not duplicated)
    local after_count
    after_count=$(grep -c "GOLDEN:self-manage:start" "$TEST_DIR/AGENTS.md")
    [ "$after_count" -eq 1 ]
}

# Test 7: Self-manage block appears before framework markers after upgrade
@test "self-manage block appears before framework markers after upgrade" {
    # Create existing file without self-manage block
    create_agents_with_markers "$TEST_DIR"

    # Run upgrade
    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]

    # Get line numbers
    local self_manage_line framework_line
    self_manage_line=$(grep -n "GOLDEN:self-manage:start" "$TEST_DIR/AGENTS.md" | head -1 | cut -d: -f1)
    framework_line=$(grep -n "GOLDEN:framework:start" "$TEST_DIR/AGENTS.md" | head -1 | cut -d: -f1)

    # Self-manage should come before framework
    [ "$self_manage_line" -lt "$framework_line" ]
}

# Test 8: Upgrade detects bloated file and creates migration prompt
@test "upgrade detects bloated file and creates migration prompt" {
    create_bloated_agents_with_markers "$TEST_DIR" 300

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/MODULAR-MIGRATION-PROMPT.md" ]
    [[ "$output" == *"exceeds 250 lines"* ]] || [[ "$output" == *"bloat"* ]]
}

# Test 9: Non-bloated file does not trigger migration prompt
@test "non-bloated file does not trigger migration prompt" {
    # Create a normal-sized file with markers
    create_agents_with_markers "$TEST_DIR"

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    # Should NOT create migration prompt
    [ ! -f "$TEST_DIR/MODULAR-MIGRATION-PROMPT.md" ]
}

# Test 10: Upgrade creates .ai-guidance directory for bloated files
@test "upgrade creates .ai-guidance directory for bloated files" {
    create_bloated_agents_with_markers "$TEST_DIR" 300

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -d "$TEST_DIR/.ai-guidance" ]
}

# Test 11: Upgrade creates invariants.md for bloated files
@test "upgrade creates invariants.md for bloated files" {
    create_bloated_agents_with_markers "$TEST_DIR" 300

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/.ai-guidance/invariants.md" ]
    # Verify it contains expected content
    assert_file_contains "$TEST_DIR/.ai-guidance/invariants.md" "Critical Invariants"
    assert_file_contains "$TEST_DIR/.ai-guidance/invariants.md" "Self-Management Protocol"
}

# Test 12: Non-bloated file does not trigger modular migration
# (.ai-guidance/ then holds only invariants.md, which every run creates when absent)
@test "non-bloated file does not trigger modular migration" {
    create_agents_with_markers "$TEST_DIR"

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ ! -e "$TEST_DIR/MODULAR-MIGRATION-PROMPT.md" ]
    [ "$(ls -A "$TEST_DIR/.ai-guidance")" = "invariants.md" ]
}

# Test 13: Self-manage block references all guidance files (recursive)
@test "self-manage block references all guidance files" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    # Should reference checking .ai-guidance/*.md files
    assert_file_contains "$TEST_DIR/AGENTS.md" ".ai-guidance/\*.md"
}

# Test 14: Self-manage block includes 250-line threshold for sub-files
@test "self-manage block tells the agent to draft a diff for a human" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    assert_file_contains "$TEST_DIR/AGENTS.md" 'draft a diff'
    assert_file_contains "$TEST_DIR/AGENTS.md" 'Do not apply it'
    assert_file_contains "$TEST_DIR/AGENTS.md" 'A human merges it'
    assert_file_not_contains "$TEST_DIR/AGENTS.md" 'no human intervention'
    assert_file_contains "$TEST_DIR/.ai-guidance/invariants.md" 'Do not apply the diff'
}

@test "upgrade replaces the self-manage block and leaves project text" {
    create_agents_with_markers "$TEST_DIR"
    printf '\nProject rule that stays.\n' >> "$TEST_DIR/AGENTS.md"
    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    assert_file_contains "$TEST_DIR/AGENTS.md" 'draft a diff'
    assert_file_contains "$TEST_DIR/AGENTS.md" 'Project rule that stays.'
    local count
    count=$(grep -c 'GOLDEN:self-manage:start' "$TEST_DIR/AGENTS.md")
    [ "$count" -eq 1 ]
}

@test "self-manage block includes 250-line threshold for sub-files" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    # Should mention 250-line threshold for sub-files
    assert_file_contains "$TEST_DIR/AGENTS.md" ">250 lines"
}

# Test 15: invariants.md includes self-management protocol
@test "invariants.md includes self-management protocol" {
    create_bloated_agents_with_markers "$TEST_DIR" 300

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/.ai-guidance/invariants.md" ]

    # Should include self-management thresholds (all are 250 lines now)
    assert_file_contains "$TEST_DIR/.ai-guidance/invariants.md" "Self-Management"
    assert_file_contains "$TEST_DIR/.ai-guidance/invariants.md" "250 lines"
}

# Test 16: invariants.md includes sub-directory splitting guidance
@test "invariants.md includes sub-directory splitting guidance" {
    create_bloated_agents_with_markers "$TEST_DIR" 300

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/.ai-guidance/invariants.md" ]

    # Should include guidance for splitting sub-files into sub-directories
    assert_file_contains "$TEST_DIR/.ai-guidance/invariants.md" "sub-directory"
}

# Test 17: Upgrade never overwrites an existing .ai-guidance/invariants.md
@test "upgrade keeps a customized .ai-guidance/invariants.md byte-for-byte" {
    create_bloated_agents_with_markers "$TEST_DIR" 300
    mkdir -p "$TEST_DIR/.ai-guidance"
    printf '# Our invariants\nUNIQUE_CUSTOM_INVARIANT\n' > "$TEST_DIR/.ai-guidance/invariants.md"
    cp "$TEST_DIR/.ai-guidance/invariants.md" "$TEST_DIR/invariants.orig"

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    cmp "$TEST_DIR/invariants.orig" "$TEST_DIR/.ai-guidance/invariants.md"
    [[ "$output" == *"Kept existing"*"invariants.md"* ]]
}

# Test 18: Fresh generation creates the invariants file it tells agents to load
@test "fresh generation creates .ai-guidance/invariants.md from the template" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    cmp "$SCRIPT_DIR/templates/core/invariants.md" "$TEST_DIR/.ai-guidance/invariants.md"
}

# Test 19: Fresh generation keeps an existing invariants file
@test "fresh generation keeps an existing .ai-guidance/invariants.md" {
    mkdir -p "$TEST_DIR/.ai-guidance"
    printf '# Ours\nUNIQUE_OURS\n' > "$TEST_DIR/.ai-guidance/invariants.md"
    cp "$TEST_DIR/.ai-guidance/invariants.md" "$TEST_DIR/inv.orig"

    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    cmp "$TEST_DIR/inv.orig" "$TEST_DIR/.ai-guidance/invariants.md"
}

# Test 20: Upgrade of a non-bloated file creates a missing invariants file
@test "upgrade --apply creates missing .ai-guidance/invariants.md" {
    create_agents_with_markers "$TEST_DIR"

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    cmp "$SCRIPT_DIR/templates/core/invariants.md" "$TEST_DIR/.ai-guidance/invariants.md"
}

# Test 21: Dry runs do not create the invariants file
@test "dry runs do not create .ai-guidance/invariants.md" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR" --dry-run
    [ "$status" -eq 0 ]
    create_agents_with_markers "$TEST_DIR"
    run "$GENERATE_SCRIPT" --upgrade --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ ! -e "$TEST_DIR/.ai-guidance" ]
}
