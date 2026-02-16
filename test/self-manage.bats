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
    assert_file_contains "$TEST_DIR/Agents.md" "GOLDEN:self-manage:start"
    assert_file_contains "$TEST_DIR/Agents.md" ">150 lines"
}

# Test 2: Self-manage block appears before framework markers
@test "self-manage block appears before framework markers" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    # Get line numbers
    local self_manage_line framework_line
    self_manage_line=$(grep -n "GOLDEN:self-manage:start" "$TEST_DIR/Agents.md" | head -1 | cut -d: -f1)
    framework_line=$(grep -n "GOLDEN:framework:start" "$TEST_DIR/Agents.md" | head -1 | cut -d: -f1)
    
    # Self-manage should come before framework
    [ "$self_manage_line" -lt "$framework_line" ]
}

# Test 3: Self-manage block contains bootstrap instructions
@test "self-manage block contains bootstrap instructions" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    assert_file_contains "$TEST_DIR/Agents.md" "Before ANY Task"
    assert_file_contains "$TEST_DIR/Agents.md" "Load.*invariants.md"
}

# Test 4: Self-manage block is properly closed
@test "self-manage block is properly closed" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    assert_file_contains "$TEST_DIR/Agents.md" "GOLDEN:self-manage:end"
}

# Test 5: Upgrade adds self-manage block to existing file
@test "upgrade adds self-manage block to existing file" {
    # Create an existing file WITH framework markers but WITHOUT self-manage block
    create_agents_with_markers "$TEST_DIR"

    # Verify no self-manage block initially
    run grep "GOLDEN:self-manage" "$TEST_DIR/Agents.md"
    [ "$status" -ne 0 ]

    # Run upgrade
    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]

    # Verify self-manage block was added
    assert_file_contains "$TEST_DIR/Agents.md" "GOLDEN:self-manage:start"
    assert_file_contains "$TEST_DIR/Agents.md" ">150 lines"
}

# Test 6: Upgrade preserves existing self-manage block
@test "upgrade preserves existing self-manage block" {
    # Generate a fresh file (which has self-manage block)
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]

    # Verify self-manage block exists
    assert_file_contains "$TEST_DIR/Agents.md" "GOLDEN:self-manage:start"

    # Count self-manage markers before upgrade
    local before_count
    before_count=$(grep -c "GOLDEN:self-manage:start" "$TEST_DIR/Agents.md")

    # Run upgrade
    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]

    # Verify exactly one self-manage block (not duplicated)
    local after_count
    after_count=$(grep -c "GOLDEN:self-manage:start" "$TEST_DIR/Agents.md")
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
    self_manage_line=$(grep -n "GOLDEN:self-manage:start" "$TEST_DIR/Agents.md" | head -1 | cut -d: -f1)
    framework_line=$(grep -n "GOLDEN:framework:start" "$TEST_DIR/Agents.md" | head -1 | cut -d: -f1)

    # Self-manage should come before framework
    [ "$self_manage_line" -lt "$framework_line" ]
}

# Test 8: Upgrade detects bloated file and creates migration prompt
@test "upgrade detects bloated file and creates migration prompt" {
    create_bloated_agents_with_markers "$TEST_DIR" 200

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/MODULAR-MIGRATION-PROMPT.md" ]
    [[ "$output" == *"exceeds 150 lines"* ]] || [[ "$output" == *"bloat"* ]]
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
    create_bloated_agents_with_markers "$TEST_DIR" 200

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -d "$TEST_DIR/.ai-guidance" ]
}

# Test 11: Upgrade creates invariants.md for bloated files
@test "upgrade creates invariants.md for bloated files" {
    create_bloated_agents_with_markers "$TEST_DIR" 200

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/.ai-guidance/invariants.md" ]
    # Verify it contains expected content
    assert_file_contains "$TEST_DIR/.ai-guidance/invariants.md" "Critical Invariants"
    assert_file_contains "$TEST_DIR/.ai-guidance/invariants.md" "Self-Management Protocol"
}

# Test 12: Non-bloated file does not create .ai-guidance
@test "non-bloated file does not create .ai-guidance" {
    create_agents_with_markers "$TEST_DIR"

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ ! -d "$TEST_DIR/.ai-guidance" ]
}

# Test 13: Self-manage block references all guidance files (recursive)
@test "self-manage block references all guidance files" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    # Should reference checking .ai-guidance/*.md files
    assert_file_contains "$TEST_DIR/Agents.md" ".ai-guidance/\*.md"
}

# Test 14: Self-manage block includes 250-line threshold for sub-files
@test "self-manage block includes 250-line threshold for sub-files" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    # Should mention 250-line threshold for sub-files
    assert_file_contains "$TEST_DIR/Agents.md" ">250 lines"
}

# Test 15: invariants.md includes self-management protocol
@test "invariants.md includes self-management protocol" {
    create_bloated_agents_with_markers "$TEST_DIR" 200

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/.ai-guidance/invariants.md" ]

    # Should include self-management thresholds (all are 250 lines now)
    assert_file_contains "$TEST_DIR/.ai-guidance/invariants.md" "Self-Management"
    assert_file_contains "$TEST_DIR/.ai-guidance/invariants.md" "250 lines"
}

# Test 16: invariants.md includes sub-directory splitting guidance
@test "invariants.md includes sub-directory splitting guidance" {
    create_bloated_agents_with_markers "$TEST_DIR" 200

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/.ai-guidance/invariants.md" ]

    # Should include guidance for splitting sub-files into sub-directories
    assert_file_contains "$TEST_DIR/.ai-guidance/invariants.md" "sub-directory"
}
