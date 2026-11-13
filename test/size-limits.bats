#!/usr/bin/env bats
# SIZE LIMIT enforcement tests - P0 Critical
# These tests enforce HARD LIMITS on output file sizes
# Any output over the limit is an immediate test failure

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# =============================================================================
# Progressive mode size limits (max 100 lines)
# =============================================================================

@test "SIZE LIMIT: Progressive mode NEVER exceeds 100 lines" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    assert_progressive_size "$TEST_DIR/AGENTS.md"
}

@test "SIZE LIMIT: Progressive mode with single language under limit" {
    for lang in go python javascript shell dart-flutter; do
        rm -rf "$TEST_DIR"
        mkdir -p "$TEST_DIR"
        
        run "$GENERATE_SCRIPT" --language="$lang" --path="$TEST_DIR"
        [ "$status" -eq 0 ]
        
        assert_progressive_size "$TEST_DIR/AGENTS.md"
    done
}

@test "SIZE LIMIT: Progressive mode with ALL languages stays under limit" {
    run "$GENERATE_SCRIPT" --language=go,python,javascript,shell,dart-flutter --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    assert_progressive_size "$TEST_DIR/AGENTS.md"
}

@test "SIZE LIMIT: Progressive mode with all project types under limit" {
    for ptype in cli-tools web-apps mobile-apps genesis-tools; do
        rm -rf "$TEST_DIR"
        mkdir -p "$TEST_DIR"
        
        run "$GENERATE_SCRIPT" --language=go --type="$ptype" --path="$TEST_DIR"
        [ "$status" -eq 0 ]
        
        assert_progressive_size "$TEST_DIR/AGENTS.md"
    done
}

# =============================================================================
# Full mode deprecation
# =============================================================================

@test "SIZE LIMIT: Full mode shows DEPRECATION warning" {
    run "$GENERATE_SCRIPT" --language=go --full --dry-run --path="$TEST_DIR"

    # Should show deprecation warning (case insensitive)
    [[ "$output" == *"DEPRECATED"* ]] || [[ "$output" == *"deprecated"* ]] || \
    [[ "$output" == *"Deprecated"* ]]
}

# =============================================================================
# Upgrade size behavior
# =============================================================================

@test "SIZE LIMIT: Upgrade of file with markers produces reasonable size" {
    create_agents_with_markers "$TEST_DIR"

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]

    # Result should still be progressive (under 100 lines)
    assert_progressive_size "$TEST_DIR/AGENTS.md"
}

@test "SIZE LIMIT: Generated file is dramatically smaller than bloated input" {
    # Create a bloated 600-line fixture
    create_bloated_fixture "$TEST_DIR" 600
    local original_managed
    original_managed=$(awk '
        index($0, "<!-- GOLDEN:framework:start -->") { inside = 1; next }
        index($0, "<!-- GOLDEN:framework:end -->") { inside = 0; next }
        inside { count++ }
        END { print count + 0 }
    ' "$TEST_DIR/AGENTS.md")
    
    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    local new_managed
    new_managed=$(awk '
        index($0, "<!-- GOLDEN:framework:start -->") { inside = 1; next }
        index($0, "<!-- GOLDEN:framework:end -->") { inside = 0; next }
        inside { count++ }
        END { print count + 0 }
    ' "$TEST_DIR/AGENTS.md")
    
    [ "$new_managed" -lt $((original_managed / 3)) ]
    [ "$new_managed" -lt 120 ]
    grep -q 'UNIQUE_MARKER_CUSTOM_RULE_1' "$TEST_DIR/AGENTS.md"
}

