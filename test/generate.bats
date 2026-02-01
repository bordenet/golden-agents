#!/usr/bin/env bats
# P2: New File Generation Tests
# Tests for generating new Agents.md files

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# Test 1: Compact mode generates ~130 lines
@test "compact mode generates reasonable file size" {
    run "$GENERATE_SCRIPT" --language=go --compact --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    assert_file_exists "$TEST_DIR/Agents.md"
    assert_line_count_between "$TEST_DIR/Agents.md" 80 200
}

# Test 2: Full mode generates larger file
@test "full mode generates larger file than compact" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    assert_file_exists "$TEST_DIR/Agents.md"
    # Full mode should be significantly larger
    local line_count
    line_count=$(wc -l < "$TEST_DIR/Agents.md" | tr -d ' ')
    [ "$line_count" -gt 200 ]
}

# Test 3: Output contains start marker
@test "generated file contains start marker" {
    run "$GENERATE_SCRIPT" --language=go --compact --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    assert_file_contains "$TEST_DIR/Agents.md" "GOLDEN:framework:start"
}

# Test 4: Output contains end marker
@test "generated file contains end marker" {
    run "$GENERATE_SCRIPT" --language=go --compact --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    assert_file_contains "$TEST_DIR/Agents.md" "GOLDEN:framework:end"
}

# Test 5: Output contains language header
@test "generated file contains language header" {
    run "$GENERATE_SCRIPT" --language=python --compact --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    assert_file_contains "$TEST_DIR/Agents.md" "python"
}

# Test 6: Output contains type header
@test "generated file contains type header" {
    run "$GENERATE_SCRIPT" --language=go --type=cli-tools --compact --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    assert_file_contains "$TEST_DIR/Agents.md" "cli-tools"
}

# Test 7: Creates output directory if missing
@test "creates output directory if missing" {
    local new_dir="$TEST_DIR/nonexistent/nested/dir"
    
    run "$GENERATE_SCRIPT" --language=go --compact --path="$new_dir"
    [ "$status" -eq 0 ]
    
    assert_dir_exists "$new_dir"
    assert_file_exists "$new_dir/Agents.md"
}

# Test 8: Project name from directory
@test "project name derived from directory" {
    local project_dir="$TEST_DIR/my-cool-project"
    mkdir -p "$project_dir"
    
    run "$GENERATE_SCRIPT" --language=go --compact --path="$project_dir"
    [ "$status" -eq 0 ]
    
    assert_file_contains "$project_dir/Agents.md" "my-cool-project"
}

# Test 9: Custom project name
@test "custom project name used when provided" {
    run "$GENERATE_SCRIPT" --language=go --compact --name=CustomProjectName --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    assert_file_contains "$TEST_DIR/Agents.md" "CustomProjectName"
}

# Test 10: Multiple languages in header
@test "multiple languages appear in header" {
    run "$GENERATE_SCRIPT" --language=go,python,javascript --compact --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    # All languages should appear
    assert_file_contains "$TEST_DIR/Agents.md" "go"
    assert_file_contains "$TEST_DIR/Agents.md" "python"
    assert_file_contains "$TEST_DIR/Agents.md" "javascript"
}

