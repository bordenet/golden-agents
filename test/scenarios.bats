#!/usr/bin/env bats
# SCENARIO-based tests - P0 Critical
# These tests verify END-TO-END workflows, not just individual features
# Each scenario represents a real-world user journey that MUST succeed

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# =============================================================================
# SCENARIO 1: Greenfield project gets usable progressive Agents.md
# =============================================================================
@test "SCENARIO: Greenfield project gets usable progressive Agents.md" {
    mkdir -p "$TEST_DIR/new-project"
    
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR/new-project"
    [ "$status" -eq 0 ]
    
    # Verify file exists and is usable
    assert_file_exists "$TEST_DIR/new-project/Agents.md"
    assert_progressive_size "$TEST_DIR/new-project/Agents.md"
    assert_file_contains "$TEST_DIR/new-project/Agents.md" "GOLDEN:framework:start"
    assert_file_contains "$TEST_DIR/new-project/Agents.md" "GOLDEN:framework:end"
}

# =============================================================================
# SCENARIO 2: Migrate substantial CLAUDE.md without data loss
# =============================================================================
@test "SCENARIO: Migrate substantial CLAUDE.md without data loss" {
    create_realistic_claude_md "$TEST_DIR"
    
    run "$GENERATE_SCRIPT" --migrate --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    # Verify MIGRATION-PROMPT.md exists and preserves all content markers
    assert_file_exists "$TEST_DIR/MIGRATION-PROMPT.md"
    assert_content_preserved "$TEST_DIR/MIGRATION-PROMPT.md" "UNIQUE_MARKER_ARCHITECTURE" "migration"
    assert_content_preserved "$TEST_DIR/MIGRATION-PROMPT.md" "UNIQUE_MARKER_GIT_WORKFLOW" "migration"
    assert_content_preserved "$TEST_DIR/MIGRATION-PROMPT.md" "UNIQUE_MARKER_CODE_STYLE" "migration"
    assert_content_preserved "$TEST_DIR/MIGRATION-PROMPT.md" "UNIQUE_MARKER_TESTING" "migration"
    assert_content_preserved "$TEST_DIR/MIGRATION-PROMPT.md" "UNIQUE_MARKER_AI_BEHAVIOR" "migration"
    assert_content_preserved "$TEST_DIR/MIGRATION-PROMPT.md" "UNIQUE_MARKER_DOMAIN_KNOWLEDGE" "migration"
    
    # Verify Agents.md is usable size
    assert_progressive_size "$TEST_DIR/Agents.md"
}

# =============================================================================
# SCENARIO 3: Adopt existing Agents.md without data loss
# =============================================================================
@test "SCENARIO: Adopt existing Agents.md without data loss" {
    mkdir -p "$TEST_DIR"
    cat > "$TEST_DIR/Agents.md" << 'EOF'
# My Existing Guide

Custom content line 1: UNIQUE_ADOPT_MARKER_1
Custom content line 2: UNIQUE_ADOPT_MARKER_2
Custom content line 3: UNIQUE_ADOPT_MARKER_3

## Important Rules
- Rule A
- Rule B
- Rule C
EOF
    
    run "$GENERATE_SCRIPT" --adopt --language=python --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    # Verify all markers preserved
    assert_content_preserved "$TEST_DIR/Agents.md" "UNIQUE_ADOPT_MARKER_1" "adoption"
    assert_content_preserved "$TEST_DIR/Agents.md" "UNIQUE_ADOPT_MARKER_2" "adoption"
    assert_content_preserved "$TEST_DIR/Agents.md" "UNIQUE_ADOPT_MARKER_3" "adoption"
    
    # Verify framework markers added
    assert_file_contains "$TEST_DIR/Agents.md" "GOLDEN:framework:start"
    assert_file_contains "$TEST_DIR/Agents.md" "GOLDEN:framework:end"
}

# =============================================================================
# SCENARIO 4: Upgrade preserves project-specific content
# =============================================================================
@test "SCENARIO: Upgrade preserves all project-specific content" {
    create_agents_with_markers "$TEST_DIR"
    
    # Add unique content to test preservation
    echo "" >> "$TEST_DIR/Agents.md"
    echo "### Special Project Content" >> "$TEST_DIR/Agents.md"
    echo "UNIQUE_UPGRADE_MARKER_1" >> "$TEST_DIR/Agents.md"
    echo "UNIQUE_UPGRADE_MARKER_2" >> "$TEST_DIR/Agents.md"
    
    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    # Verify unique content preserved
    assert_content_preserved "$TEST_DIR/Agents.md" "UNIQUE_UPGRADE_MARKER_1" "upgrade"
    assert_content_preserved "$TEST_DIR/Agents.md" "UNIQUE_UPGRADE_MARKER_2" "upgrade"
    assert_content_preserved "$TEST_DIR/Agents.md" "My Custom Rule" "upgrade"
    assert_content_preserved "$TEST_DIR/Agents.md" "feature branches" "upgrade"
}

# =============================================================================
# SCENARIO 5: Progressive mode stays under size limit with all languages
# =============================================================================
@test "SCENARIO: Progressive mode with all languages stays under 100 lines" {
    run "$GENERATE_SCRIPT" --language=go,python,javascript,shell,dart-flutter \
        --path="$TEST_DIR"
    [ "$status" -eq 0 ]

    assert_progressive_size "$TEST_DIR/Agents.md"

    # Verify all languages mentioned
    assert_file_contains "$TEST_DIR/Agents.md" "go"
    assert_file_contains "$TEST_DIR/Agents.md" "python"
    assert_file_contains "$TEST_DIR/Agents.md" "javascript"
}
