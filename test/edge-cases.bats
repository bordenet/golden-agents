#!/usr/bin/env bats
# Edge Case Tests
# Tests for unusual inputs, permissions, and boundary conditions

load 'test_helper'

# Helper: Skip test if running as root
skip_if_root() {
    if [[ "$(id -u)" -eq 0 ]]; then
        skip "Test not applicable when running as root"
    fi
}

# Helper: Skip test on Windows (Git Bash/MSYS/Cygwin)
skip_if_windows() {
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        skip "Test not applicable on Windows (chmod behaves differently)"
    fi
    # Also check uname as fallback
    if [[ "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* ]]; then
        skip "Test not applicable on Windows (chmod behaves differently)"
    fi
}

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    # Restore permissions before cleanup
    [[ -d "$TEST_DIR" ]] && chmod -R u+rwx "$TEST_DIR" 2>/dev/null || true
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# Test 1: Unicode characters in project name
@test "unicode characters in project name handled" {
    local project_dir="$TEST_DIR/проект-日本語"
    mkdir -p "$project_dir"

    run "$GENERATE_SCRIPT" --language=go --path="$project_dir"
    [ "$status" -eq 0 ]
    assert_file_exists "$project_dir/Agents.md"
}

# Test 2: Spaces in path
@test "spaces in path handled correctly" {
    local project_dir="$TEST_DIR/my project with spaces"
    mkdir -p "$project_dir"

    run "$GENERATE_SCRIPT" --language=python --path="$project_dir"
    [ "$status" -eq 0 ]
    assert_file_exists "$project_dir/Agents.md"
}

# Test 3: Special characters in project name (but valid for filesystem)
@test "special characters in project name handled" {
    local project_dir="$TEST_DIR/my-project_v2.0"
    mkdir -p "$project_dir"

    run "$GENERATE_SCRIPT" --language=go --path="$project_dir"
    [ "$status" -eq 0 ]
    assert_file_contains "$project_dir/Agents.md" "my-project_v2.0"
}

# Test 4: Empty project name defaults to directory name
@test "empty --name uses directory name" {
    local project_dir="$TEST_DIR/fallback-name"
    mkdir -p "$project_dir"

    run "$GENERATE_SCRIPT" --language=go --name="" --path="$project_dir"
    [ "$status" -eq 0 ]
    # Should contain directory name, not empty
    assert_file_contains "$project_dir/Agents.md" "fallback-name"
}

# Test 5: Very long project name (edge of filesystem limits)
@test "long project name handled" {
    local long_name="this-is-a-very-long-project-name-that-might-cause-issues"

    run "$GENERATE_SCRIPT" --language=go --name="$long_name" --path="$TEST_DIR" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"$long_name"* ]]
}

# Test 6: Read-only directory fails gracefully
@test "read-only directory fails with clear error" {
    skip_if_root  # Root can write anywhere
    skip_if_windows  # Windows handles file permissions differently

    local readonly_dir="$TEST_DIR/readonly"
    mkdir -p "$readonly_dir"
    chmod a-w "$readonly_dir"

    run "$GENERATE_SCRIPT" --language=go --path="$readonly_dir"
    [ "$status" -ne 0 ]

    # Restore for cleanup
    chmod u+w "$readonly_dir"
}
