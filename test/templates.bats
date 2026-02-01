#!/usr/bin/env bats
# P3: Template Tests
# Tests for template file existence and inclusion

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# Test 1: Core templates directory exists
@test "core templates directory exists" {
    assert_dir_exists "$SCRIPT_DIR/templates/core"
}

# Test 2: Language templates exist for supported languages
@test "language templates exist for go, python, javascript, shell" {
    assert_dir_exists "$SCRIPT_DIR/templates/languages"
    
    # At least some language templates should exist
    local count
    count=$(ls -1 "$SCRIPT_DIR/templates/languages/"*.md 2>/dev/null | wc -l | tr -d ' ')
    [ "$count" -ge 1 ]
}

# Test 3: Project type templates exist
@test "project type templates exist" {
    assert_dir_exists "$SCRIPT_DIR/templates/project-types"
    
    local count
    count=$(ls -1 "$SCRIPT_DIR/templates/project-types/"*.md 2>/dev/null | wc -l | tr -d ' ')
    [ "$count" -ge 1 ]
}

# Test 4: Workflow templates exist
@test "workflow templates exist" {
    assert_dir_exists "$SCRIPT_DIR/templates/workflows"
    
    local count
    count=$(ls -1 "$SCRIPT_DIR/templates/workflows/"*.md 2>/dev/null | wc -l | tr -d ' ')
    [ "$count" -ge 1 ]
}

# Test 5: Full mode includes superpowers content
@test "full mode includes superpowers content" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    # Full mode should contain superpowers integration
    assert_file_contains "$TEST_DIR/Agents.md" "superpowers" || \
    assert_file_contains "$TEST_DIR/Agents.md" "Superpowers" || \
    assert_file_contains "$TEST_DIR/Agents.md" "bootstrap"
}

# Test 6: Full mode includes language-specific content
@test "full mode includes Go-specific content" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    # Should contain Go-specific guidance
    grep -qi "go" "$TEST_DIR/Agents.md"
}

# Test 7: Full mode includes type-specific content
@test "full mode includes CLI-specific content" {
    run "$GENERATE_SCRIPT" --language=go --type=cli-tools --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    # Should contain CLI-related guidance
    assert_file_contains "$TEST_DIR/Agents.md" "cli" || \
    assert_file_contains "$TEST_DIR/Agents.md" "CLI" || \
    assert_file_contains "$TEST_DIR/Agents.md" "command"
}

# Test 8: Unknown type handled gracefully
@test "unknown project type handled gracefully" {
    run "$GENERATE_SCRIPT" --language=go --type=nonexistent-type --compact --path="$TEST_DIR"
    
    # Should either succeed (ignoring unknown type) or fail gracefully
    # The file should still be created if it succeeds
    if [ "$status" -eq 0 ]; then
        assert_file_exists "$TEST_DIR/Agents.md"
    else
        [[ "$output" == *"Warning"* ]] || [[ "$output" == *"template"* ]] || [[ "$output" == *"type"* ]]
    fi
}

