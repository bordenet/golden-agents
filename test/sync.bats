#!/usr/bin/env bats
# P3: Sync Tests
# Tests for git sync functionality

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# Test 1: Sync in git repo succeeds
@test "sync succeeds in git repository" {
    # Run from the actual golden-agents directory (which is a git repo)
    cd "$SCRIPT_DIR"
    
    run "$GENERATE_SCRIPT" --sync
    [ "$status" -eq 0 ]
    [[ "$output" == *"updated"* ]] || [[ "$output" == *"Templates"* ]] || [[ "$output" == *"Already"* ]]
}

# Test 2: Sync in non-git directory fails
@test "sync fails when not in git repo" {
    # Create a copy of the script in a non-git directory
    cp "$GENERATE_SCRIPT" "$TEST_DIR/generate-agents.sh"
    chmod +x "$TEST_DIR/generate-agents.sh"
    
    cd "$TEST_DIR"
    run ./generate-agents.sh --sync
    
    [ "$status" -ne 0 ]
    [[ "$output" == *"git"* ]] || [[ "$output" == *"Not a git repo"* ]] || [[ "$output" == *"clone"* ]]
}

