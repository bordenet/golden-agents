#!/usr/bin/env bats
# Migration Tests for generate-agents.sh

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# Test 1: Detects existing CLAUDE.md with substantial content
@test "detects existing CLAUDE.md with substantial content" {
    mkdir -p "$TEST_DIR"
    # Create CLAUDE.md with >100 bytes of content
    cat > "$TEST_DIR/CLAUDE.md" << 'EOF'
# Project Guide

This is substantial project-specific content that should not be lost.

## Rules
- Do this
- Do that
- Another important rule here
EOF
    
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -ne 0 ]
    [[ "$output" == *"existing"* ]] || [[ "$output" == *"CLAUDE.md"* ]] || [[ "$output" == *"--migrate"* ]]
}

# Test 2: Ignores small redirect CLAUDE.md (<100 bytes)
@test "ignores small redirect CLAUDE.md" {
    mkdir -p "$TEST_DIR"
    echo "See Agents.md" > "$TEST_DIR/CLAUDE.md"
    
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR" --dry-run
    [ "$status" -eq 0 ]
}

# Test 3: Detects existing Agents.md without markers
@test "detects existing Agents.md without markers" {
    create_agents_without_markers "$TEST_DIR"
    
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -ne 0 ]
    [[ "$output" == *"existing"* ]] || [[ "$output" == *"--migrate"* ]]
}

# Test 4: Allows overwriting Agents.md WITH markers (upgrade path)
@test "allows overwriting Agents.md with markers" {
    create_agents_with_markers "$TEST_DIR"
    
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR" --dry-run
    [ "$status" -eq 0 ]
}

# Test 5: --migrate bypasses the block
@test "--migrate bypasses existing content block" {
    mkdir -p "$TEST_DIR"
    cat > "$TEST_DIR/CLAUDE.md" << 'EOF'
# Project Guide
Substantial content that would normally block generation.
More content to exceed 100 bytes threshold.
EOF
    
    run "$GENERATE_SCRIPT" --migrate --language=go --path="$TEST_DIR" --dry-run
    [ "$status" -eq 0 ]
}

