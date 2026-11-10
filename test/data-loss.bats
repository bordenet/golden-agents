#!/usr/bin/env bats
# DATA LOSS verification tests - P0 Critical
# These tests verify ZERO DATA LOSS during all operations
# Any content loss is an immediate test failure

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# =============================================================================
# DATA LOSS: Migration tests
# =============================================================================

@test "DATA LOSS: Migration preserves all unique content lines in prompt" {
    create_realistic_claude_md "$TEST_DIR"
    local original_count
    original_count=$(count_unique_content_lines "$TEST_DIR/CLAUDE.md")
    
    run "$GENERATE_SCRIPT" --migrate --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    # All original content must appear in MIGRATION-PROMPT.md
    local prompt_count
    prompt_count=$(count_unique_content_lines "$TEST_DIR/MIGRATION-PROMPT.md")
    
    # MIGRATION-PROMPT should have MORE lines (adds instructions)
    [ "$prompt_count" -ge "$original_count" ]
}

@test "DATA LOSS: Migration prompt contains all 6 unique markers" {
    create_realistic_claude_md "$TEST_DIR"
    
    run "$GENERATE_SCRIPT" --migrate --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    # Check each marker individually
    assert_content_preserved "$TEST_DIR/MIGRATION-PROMPT.md" "UNIQUE_MARKER_ARCHITECTURE" "migration"
    assert_content_preserved "$TEST_DIR/MIGRATION-PROMPT.md" "UNIQUE_MARKER_GIT_WORKFLOW" "migration"
    assert_content_preserved "$TEST_DIR/MIGRATION-PROMPT.md" "UNIQUE_MARKER_CODE_STYLE" "migration"
    assert_content_preserved "$TEST_DIR/MIGRATION-PROMPT.md" "UNIQUE_MARKER_TESTING" "migration"
    assert_content_preserved "$TEST_DIR/MIGRATION-PROMPT.md" "UNIQUE_MARKER_AI_BEHAVIOR" "migration"
    assert_content_preserved "$TEST_DIR/MIGRATION-PROMPT.md" "UNIQUE_MARKER_DOMAIN_KNOWLEDGE" "migration"
}

# =============================================================================
# DATA LOSS: Upgrade tests
# =============================================================================

@test "DATA LOSS: Upgrade preserves project-specific section exactly" {
    create_agents_with_markers "$TEST_DIR"
    echo "UNIQUE_PROJECT_CONTENT_LINE_1" >> "$TEST_DIR/AGENTS.md"
    echo "UNIQUE_PROJECT_CONTENT_LINE_2" >> "$TEST_DIR/AGENTS.md"
    echo "UNIQUE_PROJECT_CONTENT_LINE_3" >> "$TEST_DIR/AGENTS.md"
    
    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    assert_content_preserved "$TEST_DIR/AGENTS.md" "UNIQUE_PROJECT_CONTENT_LINE_1" "upgrade"
    assert_content_preserved "$TEST_DIR/AGENTS.md" "UNIQUE_PROJECT_CONTENT_LINE_2" "upgrade"
    assert_content_preserved "$TEST_DIR/AGENTS.md" "UNIQUE_PROJECT_CONTENT_LINE_3" "upgrade"
}

@test "DATA LOSS: Backup file is byte-for-byte identical to original" {
    create_agents_with_markers "$TEST_DIR"
    local original_hash
    original_hash=$(md5sum "$TEST_DIR/AGENTS.md" 2>/dev/null | cut -d' ' -f1 || md5 -q "$TEST_DIR/AGENTS.md")
    
    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    local backup_hash
    backup_hash=$(md5sum "$TEST_DIR/AGENTS.md.backup" 2>/dev/null | cut -d' ' -f1 || md5 -q "$TEST_DIR/AGENTS.md.backup")
    
    [ "$original_hash" = "$backup_hash" ]
}

# =============================================================================
# DATA LOSS: Adoption tests
# =============================================================================

@test "DATA LOSS: Adoption appends ALL original content lines" {
    mkdir -p "$TEST_DIR"
    
    # Create file with known content
    {
        echo "# Original Guide"
        for i in $(seq 1 20); do
            echo "Original line $i with unique content ADOPT_MARKER_$i"
        done
    } > "$TEST_DIR/AGENTS.md"
    
    run "$GENERATE_SCRIPT" --adopt --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    # Verify all markers present
    for i in $(seq 1 20); do
        assert_content_preserved "$TEST_DIR/AGENTS.md" "ADOPT_MARKER_$i" "adoption line $i"
    done
}

@test "DATA LOSS: Adoption creates backup with original content" {
    mkdir -p "$TEST_DIR"
    echo "# My Original Guide" > "$TEST_DIR/AGENTS.md"
    echo "UNIQUE_ORIGINAL_CONTENT_XYZ" >> "$TEST_DIR/AGENTS.md"
    
    run "$GENERATE_SCRIPT" --adopt --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    # Verify backup exists and contains original
    assert_file_exists "$TEST_DIR/AGENTS.md.original"
    assert_content_preserved "$TEST_DIR/AGENTS.md.original" "UNIQUE_ORIGINAL_CONTENT_XYZ" "backup"
}


# =============================================================================
# DATA LOSS: Migration must back up AGENTS.md before replacing it
# =============================================================================

@test "DATA LOSS: --migrate backs up AGENTS.md without markers to timestamped .bak" {
    create_realistic_claude_md "$TEST_DIR"
    printf '# Team guide\nUNIQUE_AGENTS_ONLY_CONTENT\n' > "$TEST_DIR/AGENTS.md"
    cp "$TEST_DIR/AGENTS.md" "$TEST_DIR/agents.orig"

    run "$GENERATE_SCRIPT" --migrate --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]

    local baks
    baks=$(find "$TEST_DIR" -maxdepth 1 -name 'AGENTS.md.*.bak')
    [ "$(echo "$baks" | grep -c .)" -eq 1 ]
    cmp "$TEST_DIR/agents.orig" "$baks"
}

@test "DATA LOSS: --migrate backs up AGENTS.md with markers when no CLAUDE.md exists" {
    create_agents_with_markers "$TEST_DIR"
    cp "$TEST_DIR/AGENTS.md" "$TEST_DIR/agents.orig"

    run "$GENERATE_SCRIPT" --migrate --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]

    local baks
    baks=$(find "$TEST_DIR" -maxdepth 1 -name 'AGENTS.md.*.bak')
    [ "$(echo "$baks" | grep -c .)" -eq 1 ]
    cmp "$TEST_DIR/agents.orig" "$baks"
}

@test "DATA LOSS: --migrate --dry-run writes no AGENTS.md backup" {
    printf '# Team guide\nUNIQUE_AGENTS_ONLY_CONTENT\n' > "$TEST_DIR/AGENTS.md"

    run "$GENERATE_SCRIPT" --migrate --language=go --path="$TEST_DIR" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"Would back up"*"AGENTS.md"* ]]
    [ -z "$(find "$TEST_DIR" -maxdepth 1 -name '*.bak')" ]
}
