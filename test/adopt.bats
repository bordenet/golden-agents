#!/usr/bin/env bats
# Adoption Tests for generate-agents.sh

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# Test 1: --adopt requires --language
@test "--adopt requires --language flag" {
    mkdir -p "$TEST_DIR"
    echo "# Existing Guide" > "$TEST_DIR/AGENTS.md"

    run "$GENERATE_SCRIPT" --adopt --path="$TEST_DIR"
    [ "$status" -ne 0 ]
    [[ "$output" == *"--adopt requires --language"* ]]
}

# Test 2: --adopt requires existing AGENTS.md
@test "--adopt requires existing AGENTS.md" {
    mkdir -p "$TEST_DIR"
    # No AGENTS.md file

    run "$GENERATE_SCRIPT" --adopt --language=go --path="$TEST_DIR"
    [ "$status" -ne 0 ]
    [[ "$output" == *"No AGENTS.md found"* ]]
}

# Test 3: --adopt refuses files with markers
@test "--adopt refuses files with framework markers" {
    create_agents_with_markers "$TEST_DIR"

    run "$GENERATE_SCRIPT" --adopt --language=go --path="$TEST_DIR"
    [ "$status" -ne 0 ]
    [[ "$output" == *"already has framework markers"* ]]
    [[ "$output" == *"--upgrade"* ]]
}

# Test 4: --adopt creates backup
@test "--adopt creates AGENTS.md.original backup" {
    mkdir -p "$TEST_DIR"
    cat > "$TEST_DIR/AGENTS.md" << 'EOF'
# Existing Project Guide

This is our existing project guidance.
EOF

    run "$GENERATE_SCRIPT" --adopt --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/AGENTS.md.original" ]
    grep -q "Existing Project Guide" "$TEST_DIR/AGENTS.md.original"
}

# Test 5: --adopt appends original content
@test "--adopt appends original content under Preserved section" {
    mkdir -p "$TEST_DIR"
    cat > "$TEST_DIR/AGENTS.md" << 'EOF'
# Existing Guide

Unique marker: ADOPT_TEST_12345

Custom rules here.
EOF

    run "$GENERATE_SCRIPT" --adopt --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    grep -q "## Preserved Project Content" "$TEST_DIR/AGENTS.md"
    grep -q "ADOPT_TEST_12345" "$TEST_DIR/AGENTS.md"
}

# Test 6: --adopt creates ADOPT-PROMPT.md
@test "--adopt creates ADOPT-PROMPT.md" {
    mkdir -p "$TEST_DIR"
    echo "# Existing Guide" > "$TEST_DIR/AGENTS.md"

    run "$GENERATE_SCRIPT" --adopt --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/ADOPT-PROMPT.md" ]
}

# Test 7: ADOPT-PROMPT.md contains deduplication instructions
@test "ADOPT-PROMPT.md contains deduplication instructions" {
    mkdir -p "$TEST_DIR"
    echo "# Existing Guide" > "$TEST_DIR/AGENTS.md"

    run "$GENERATE_SCRIPT" --adopt --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    grep -qi "deduplicate" "$TEST_DIR/ADOPT-PROMPT.md"
    grep -q "0-20 lines" "$TEST_DIR/ADOPT-PROMPT.md" || grep -q "20-50 lines" "$TEST_DIR/ADOPT-PROMPT.md"
}

# Test 8: --adopt updates .gitignore
@test "--adopt adds files to .gitignore" {
    mkdir -p "$TEST_DIR"
    echo "# Existing Guide" > "$TEST_DIR/AGENTS.md"

    run "$GENERATE_SCRIPT" --adopt --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/.gitignore" ]
    grep -q "ADOPT-PROMPT.md" "$TEST_DIR/.gitignore"
    grep -q "AGENTS.md.original" "$TEST_DIR/.gitignore"
}

# Test 9: --adopt preserves framework markers in output
@test "--adopt generates file with framework markers" {
    mkdir -p "$TEST_DIR"
    echo "# Existing Guide" > "$TEST_DIR/AGENTS.md"

    run "$GENERATE_SCRIPT" --adopt --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    grep -q "GOLDEN:framework:start" "$TEST_DIR/AGENTS.md"
    grep -q "GOLDEN:framework:end" "$TEST_DIR/AGENTS.md"
}

# Test 10: --adopt output includes next steps
@test "--adopt output includes next steps" {
    mkdir -p "$TEST_DIR"
    echo "# Existing Guide" > "$TEST_DIR/AGENTS.md"

    run "$GENERATE_SCRIPT" --adopt --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Next steps"* ]]
    [[ "$output" == *"ADOPT-PROMPT.md"* ]]
}

# Test 11: --adopt appends to existing .gitignore
@test "--adopt appends to existing .gitignore" {
    mkdir -p "$TEST_DIR"
    echo "# Existing Guide" > "$TEST_DIR/AGENTS.md"
    echo "node_modules/" > "$TEST_DIR/.gitignore"

    run "$GENERATE_SCRIPT" --adopt --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    grep -q "node_modules/" "$TEST_DIR/.gitignore"
    grep -q "ADOPT-PROMPT.md" "$TEST_DIR/.gitignore"
}

# Test 12: --adopt works with different languages
@test "--adopt works with python language" {
    mkdir -p "$TEST_DIR"
    echo "# Python Project Guide" > "$TEST_DIR/AGENTS.md"

    run "$GENERATE_SCRIPT" --adopt --language=python --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/AGENTS.md" ]
    [ -f "$TEST_DIR/ADOPT-PROMPT.md" ]
}

