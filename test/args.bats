#!/usr/bin/env bats
# P1: Argument Parsing Tests
# Tests for command-line argument handling and validation

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# Test 1: --help shows usage
@test "--help shows usage information" {
    run "$GENERATE_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"SYNOPSIS"* ]]
}

# Test 2: -h shows usage
@test "-h shows usage information" {
    run "$GENERATE_SCRIPT" -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"SYNOPSIS"* ]]
}

# Test 3: --version shows version
@test "--version shows version" {
    run "$GENERATE_SCRIPT" --version
    [ "$status" -eq 0 ]
    # Match version pattern v1.x.x or v2.x.x etc
    [[ "$output" =~ v[0-9]+\.[0-9]+ ]]
}

# Test 4: -v shows version
@test "-v shows version" {
    run "$GENERATE_SCRIPT" -v
    [ "$status" -eq 0 ]
    [[ "$output" =~ v[0-9]+\.[0-9]+ ]]
}

# Test 5: Unknown flag fails
@test "unknown flag fails with error" {
    run "$GENERATE_SCRIPT" --invalid-option
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown"* ]] || [[ "$output" == *"unknown"* ]] || [[ "$output" == *"unrecognized"* ]]
}

# Test 6: Missing --language fails (for new file generation)
@test "missing --language fails for new file" {
    run "$GENERATE_SCRIPT" --path="$TEST_DIR" --dry-run
    [ "$status" -ne 0 ]
    [[ "$output" == *"language"* ]] || [[ "$output" == *"--language"* ]]
}

# Test 7: --apply without --upgrade fails
@test "--apply without --upgrade fails" {
    run "$GENERATE_SCRIPT" --apply --language=go --path="$TEST_DIR"
    [ "$status" -ne 0 ]
    [[ "$output" == *"--upgrade"* ]] || [[ "$output" == *"requires"* ]]
}

# Test 8: Multiple languages accepted
@test "multiple languages accepted" {
    run "$GENERATE_SCRIPT" --language=go,python --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"go"* ]] || [[ "$output" == *"python"* ]]
}

# Test 9: --progressive flag accepted (explicit default)
@test "--progressive flag accepted" {
    run "$GENERATE_SCRIPT" --language=go --progressive --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"progressive"* ]]
}

# Test 10: --dry-run shows output without writing
@test "--dry-run shows output without writing" {
    cd "$TEST_DIR"
    run "$GENERATE_SCRIPT" --language=go --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN"* ]]
    [ ! -f "$TEST_DIR/Agents.md" ]  # Should not create file in test dir
}

# Test 11-16: Language alias resolution
@test "js alias resolves to javascript" {
    run "$GENERATE_SCRIPT" --language=js --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"javascript"* ]]
}

@test "node alias resolves to javascript" {
    run "$GENERATE_SCRIPT" --language=node --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"javascript"* ]]
}

@test "ts alias resolves to javascript" {
    run "$GENERATE_SCRIPT" --language=ts --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"javascript"* ]]
}

@test "bash alias resolves to shell" {
    run "$GENERATE_SCRIPT" --language=bash --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"shell"* ]]
}

@test "flutter alias resolves to dart-flutter" {
    run "$GENERATE_SCRIPT" --language=flutter --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"dart-flutter"* ]]
}

@test "mixed aliases resolve correctly" {
    run "$GENERATE_SCRIPT" --language=js,go,bash --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"javascript"* ]]
    [[ "$output" == *"go"* ]]
    [[ "$output" == *"shell"* ]]
}

# Test 17: Missing language shows available options
@test "missing language shows available options" {
    run "$GENERATE_SCRIPT" --path="$TEST_DIR" 2>&1
    [ "$status" -ne 0 ]
    # Should list available languages
    [[ "$output" == *"javascript"* ]]
    [[ "$output" == *"go"* ]]
    [[ "$output" == *"python"* ]]
    # Should show aliases
    [[ "$output" == *"js"* ]] || [[ "$output" == *"node"* ]]
    # Should show project types
    [[ "$output" == *"cli-tools"* ]] || [[ "$output" == *"web-apps"* ]]
}

