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
    echo "See AGENTS.md" > "$TEST_DIR/CLAUDE.md"
    
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR" --dry-run
    [ "$status" -eq 0 ]
}

# Test 3: Detects existing AGENTS.md without markers
@test "detects existing AGENTS.md without markers" {
    create_agents_without_markers "$TEST_DIR"
    
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -ne 0 ]
    [[ "$output" == *"existing"* ]] || [[ "$output" == *"--migrate"* ]]
}

# Test 4: Allows overwriting AGENTS.md WITH markers (upgrade path)
@test "allows overwriting AGENTS.md with markers" {
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

# Test 6: --migrate creates MIGRATION-PROMPT.md
@test "--migrate creates MIGRATION-PROMPT.md" {
    mkdir -p "$TEST_DIR"
    cat > "$TEST_DIR/CLAUDE.md" << 'EOF'
# Project Guide

Substantial content here that needs migration into the new framework.

## Custom Rules
- Rule 1: Always use feature branches
- Rule 2: Require 2 approvals for PRs
EOF

    run "$GENERATE_SCRIPT" --migrate --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/MIGRATION-PROMPT.md" ]
    [ -f "$TEST_DIR/AGENTS.md" ]
}

# Test 7: MIGRATION-PROMPT.md contains existing content
@test "MIGRATION-PROMPT.md contains existing content" {
    mkdir -p "$TEST_DIR"
    cat > "$TEST_DIR/CLAUDE.md" << 'EOF'
# My Unique Project Guide

This is project-specific content with a unique marker ABC123XYZ that we can search for.
Additional lines to ensure we exceed the 100 byte threshold for detection.
EOF

    run "$GENERATE_SCRIPT" --migrate --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    grep -q "ABC123XYZ" "$TEST_DIR/MIGRATION-PROMPT.md"
}

# Test 8: MIGRATION-PROMPT.md has deletion note
@test "MIGRATION-PROMPT.md has deletion note" {
    mkdir -p "$TEST_DIR"
    cat > "$TEST_DIR/CLAUDE.md" << 'EOF'
# Project Guide

Substantial content here for testing purposes that exceeds the 100 byte threshold.
More content to make absolutely sure we exceed that threshold.
EOF

    run "$GENERATE_SCRIPT" --migrate --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    grep -qi "delete" "$TEST_DIR/MIGRATION-PROMPT.md"
}

# Test 9: .gitignore updated with MIGRATION-PROMPT.md
@test ".gitignore includes MIGRATION-PROMPT.md" {
    mkdir -p "$TEST_DIR"
    cat > "$TEST_DIR/CLAUDE.md" << 'EOF'
# Project Guide

Substantial content here for testing purposes that exceeds the 100 byte threshold.
More content to make absolutely sure we exceed that threshold.
EOF

    run "$GENERATE_SCRIPT" --migrate --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    grep -q "MIGRATION-PROMPT.md" "$TEST_DIR/.gitignore"
}

# Test 10: --migrate with no existing content skips prompt generation
@test "--migrate with no existing content skips prompt generation" {
    mkdir -p "$TEST_DIR"
    # No CLAUDE.md or AGENTS.md

    run "$GENERATE_SCRIPT" --migrate --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/AGENTS.md" ]
    [ ! -f "$TEST_DIR/MIGRATION-PROMPT.md" ]
}

