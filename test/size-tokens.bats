#!/usr/bin/env bats
# Section F: token estimate plus the 250-line lock. 200 is help text only.

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

@test "SIZE: help names the 200-line soft ceiling and keeps the 250 lock" {
    run "$GENERATE_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"200 lines is the soft ceiling"* ]]
    [[ "$output" == *"scoped rules"* ]]
    [[ "$output" == *"MAX_GUIDANCE_LINES stays 250"* ]]
    # shellcheck disable=SC2046
    ! grep -E '^[A-Za-z_][A-Za-z0-9_]*=200$' $(implementation_files)
    # shellcheck disable=SC2046
    grep -q '^MAX_GUIDANCE_LINES=250$' $(implementation_files)
}

@test "SIZE: progressive output stays under 250 lines and prints a token estimate" {
    run "$GENERATE_SCRIPT" --language=go,python,javascript,shell,dart-flutter --type=cli-tools --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    local lines bytes expect
    lines=$(wc -l < "$TEST_DIR/AGENTS.md" | tr -d ' ')
    bytes=$(wc -c < "$TEST_DIR/AGENTS.md" | tr -d ' ')
    expect=$(( (bytes + 3) / 4 ))
    [ "$lines" -le 250 ]
    [[ "$output" == *"Lines: $lines"* ]]
    [[ "$output" == *"Tokens (estimate): $expect"* ]]
}

@test "SIZE: upgrade apply prints the same token estimate" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    local bytes expect
    bytes=$(wc -c < "$TEST_DIR/AGENTS.md" | tr -d ' ')
    expect=$(( (bytes + 3) / 4 ))
    [[ "$output" == *"Tokens (estimate): $expect"* ]]
}
