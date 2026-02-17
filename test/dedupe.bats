#!/usr/bin/env bats
# Deduplication Tests for generate-agents.sh

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# Helper: Create Agents.md with markers and bloated project section
create_bloated_agents() {
    local dir="$1"
    local project_lines="${2:-200}"
    mkdir -p "$dir"
    
    cat > "$dir/Agents.md" << 'EOF'
# AI Agent Guidelines

<!-- GOLDEN:framework:start -->
## Framework Section
This is the framework content.
<!-- GOLDEN:framework:end -->

---

## Project-Specific Rules

EOF
    
    # Add bloated project content
    for i in $(seq 1 "$project_lines"); do
        echo "Line $i of project-specific content that is probably redundant." >> "$dir/Agents.md"
    done
}

# Helper: Create Agents.md with markers and minimal project section
create_minimal_agents() {
    local dir="$1"
    mkdir -p "$dir"
    
    cat > "$dir/Agents.md" << 'EOF'
# AI Agent Guidelines

<!-- GOLDEN:framework:start -->
## Framework Section
This is the framework content.
<!-- GOLDEN:framework:end -->

---

## Project-Specific Guidelines

Production URL: https://example.com
Build: `npm run build`
Deploy: `./scripts/deploy.sh`
EOF
}

# Test 1: --dedupe requires --path
@test "--dedupe requires --path flag" {
    run "$GENERATE_SCRIPT" --dedupe
    [ "$status" -ne 0 ]
    [[ "$output" == *"--dedupe requires --path"* ]]
}

# Test 2: --dedupe requires existing AGENTS.md
@test "--dedupe requires existing Agents.md" {
    mkdir -p "$TEST_DIR"
    # No AGENTS.md file

    run "$GENERATE_SCRIPT" --dedupe --path="$TEST_DIR"
    [ "$status" -ne 0 ]
    [[ "$output" == *"No AGENTS.md found"* ]]
}

# Test 3: --dedupe requires files WITH markers
@test "--dedupe requires files with framework markers" {
    mkdir -p "$TEST_DIR"
    echo "# Manual Guide" > "$TEST_DIR/Agents.md"

    run "$GENERATE_SCRIPT" --dedupe --path="$TEST_DIR"
    [ "$status" -ne 0 ]
    [[ "$output" == *"does not have framework markers"* ]]
    [[ "$output" == *"--adopt"* ]]
}

# Test 4: --dedupe reports line counts
@test "--dedupe reports project-specific line count" {
    create_bloated_agents "$TEST_DIR" 200

    run "$GENERATE_SCRIPT" --dedupe --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Project-specific section:"* ]]
    [[ "$output" == *"lines"* ]]
}

# Test 5: --dedupe creates ADOPT-PROMPT.md for bloated files
@test "--dedupe creates ADOPT-PROMPT.md for bloated project section" {
    create_bloated_agents "$TEST_DIR" 200

    run "$GENERATE_SCRIPT" --dedupe --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/ADOPT-PROMPT.md" ]
    [[ "$output" == *"Created: $TEST_DIR/ADOPT-PROMPT.md"* ]]
}

# Test 6: --dedupe skips minimal files
@test "--dedupe skips files already within target" {
    create_minimal_agents "$TEST_DIR"

    run "$GENERATE_SCRIPT" --dedupe --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"already within target"* ]]
    [[ "$output" == *"No deduplication needed"* ]]
    # Should NOT create ADOPT-PROMPT.md
    [ ! -f "$TEST_DIR/ADOPT-PROMPT.md" ]
}

# Test 7: --dedupe shows warning for bloated files
@test "--dedupe warns when project section exceeds target" {
    create_bloated_agents "$TEST_DIR" 150

    run "$GENERATE_SCRIPT" --dedupe --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"exceeds target"* ]]
    [[ "$output" == *"Target for complex projects: 50-100 lines"* ]]
}

# Test 8: --dedupe adds to existing .gitignore
@test "--dedupe adds ADOPT-PROMPT.md to existing .gitignore" {
    create_bloated_agents "$TEST_DIR" 200
    echo "node_modules/" > "$TEST_DIR/.gitignore"

    run "$GENERATE_SCRIPT" --dedupe --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    grep -q "ADOPT-PROMPT.md" "$TEST_DIR/.gitignore"
    grep -q "node_modules/" "$TEST_DIR/.gitignore"
}

# Test 9: --dedupe creates .gitignore if missing
@test "--dedupe creates .gitignore if missing" {
    create_bloated_agents "$TEST_DIR" 200
    rm -f "$TEST_DIR/.gitignore"

    run "$GENERATE_SCRIPT" --dedupe --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/.gitignore" ]
    grep -q "ADOPT-PROMPT.md" "$TEST_DIR/.gitignore"
}

# Test 10: --dedupe shows next steps
@test "--dedupe shows next steps for deduplication" {
    create_bloated_agents "$TEST_DIR" 200

    run "$GENERATE_SCRIPT" --dedupe --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"NEXT STEPS"* ]]
    [[ "$output" == *"Open ADOPT-PROMPT.md"* ]]
    [[ "$output" == *"Target: Reduce"* ]]
}

# Test 11: --dedupe does NOT modify original Agents.md
@test "--dedupe does not modify Agents.md" {
    create_bloated_agents "$TEST_DIR" 200
    original_hash=$(md5sum "$TEST_DIR/Agents.md" | cut -d' ' -f1)

    run "$GENERATE_SCRIPT" --dedupe --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    
    new_hash=$(md5sum "$TEST_DIR/Agents.md" | cut -d' ' -f1)
    [ "$original_hash" = "$new_hash" ]
}

# Test 12: --dedupe boundary test at exactly 100 lines
@test "--dedupe treats 100 lines as within target" {
    create_bloated_agents "$TEST_DIR" 90  # 90 + ~10 header = ~100

    run "$GENERATE_SCRIPT" --dedupe --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"already within target"* ]]
}

