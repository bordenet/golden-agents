#!/usr/bin/env bats
# --self-test and --no-backup coverage

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

@test "self-test passes on a healthy checkout" {
    run "$GENERATE_SCRIPT" --self-test
    [ "$status" -eq 0 ]
    [[ "$output" == *PASS* ]]
}

@test "--no-backup alone fails" {
    run "$GENERATE_SCRIPT" --no-backup
    [ "$status" -ne 0 ]
    [[ "$output" == *"--no-backup requires"* ]] || [[ "$output" == *"requires --apply"* ]]
}

@test "upgrade --apply --no-backup skips backup" {
    create_agents_with_markers "$TEST_DIR"

    run "$GENERATE_SCRIPT" --upgrade --apply --no-backup --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ ! -f "$TEST_DIR/AGENTS.md.backup" ]
    [[ "$output" == *"Skipping"* || "$output" == *"--no-backup"* || "$output" == *"Skipped"* ]]
}
