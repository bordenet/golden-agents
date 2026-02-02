# Migration Feature Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add `--migrate` flag and language aliases to golden-agents, enabling safe migration of existing project guidance into the framework.

**Architecture:** 
- Add language alias resolution (js→javascript, node→javascript, etc.)
- Add interactive menu when `--language` not provided
- Detect existing guidance files (CLAUDE.md, AGENTS.md, Agents.md)
- Block generation when existing content found (require `--migrate`)
- Generate framework Agents.md + MIGRATION-PROMPT.md with LLM instructions

**Tech Stack:** Bash 4.0+, BATS for testing, cross-platform (macOS, Linux, Windows Git Bash/WSL)

---

## Task 1: Add Language Alias Resolution

**Files:**
- Modify: `generate-agents.sh:117-140` (after argument parsing)
- Test: `test/args.bats` (add new tests)

**Step 1: Write the failing test**

Add to `test/args.bats`:

```bash
# Test: Language aliases resolve correctly
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
```

**Step 2: Run test to verify it fails**

Run: `cd test && bats args.bats`
Expected: FAIL - aliases not recognized

**Step 3: Write the alias resolution function**

Add after line 115 in `generate-agents.sh`:

```bash
# Resolve language aliases to canonical names
resolve_language_alias() {
    local lang="$1"
    case "$lang" in
        js|javascript|node|nodejs|ts|typescript) echo "javascript" ;;
        py|python|python3) echo "python" ;;
        bash|sh|zsh|shell) echo "shell" ;;
        flutter|dart|dart-flutter) echo "dart-flutter" ;;
        golang|go) echo "go" ;;
        *) echo "$lang" ;;
    esac
}

# Resolve all languages in comma-separated list
resolve_languages() {
    local input="$1"
    local resolved=""
    local IFS=','
    for lang in $input; do
        local canonical
        canonical=$(resolve_language_alias "$lang")
        if [[ -z "$resolved" ]]; then
            resolved="$canonical"
        else
            # Avoid duplicates
            if [[ ! ",$resolved," == *",$canonical,"* ]]; then
                resolved="$resolved,$canonical"
            fi
        fi
    done
    echo "$resolved"
}
```

**Step 4: Apply alias resolution after argument parsing**

Add after the argument parsing loop (around line 140):

```bash
# Resolve language aliases
if [[ -n "$LANGUAGES" ]]; then
    LANGUAGES=$(resolve_languages "$LANGUAGES")
fi
```

**Step 5: Run test to verify it passes**

Run: `cd test && bats args.bats`
Expected: PASS

**Step 6: Commit**

```bash
git add generate-agents.sh test/args.bats
git commit -m "feat: add language aliases (js, node, ts, bash, flutter, etc.)"
```

---

## Task 2: Add Interactive Language Menu

**Files:**
- Modify: `generate-agents.sh` (add interactive menu function)
- Test: `test/args.bats` (test menu output format)

**Step 1: Write the failing test**

Add to `test/args.bats`:

```bash
# Test: Missing language shows menu (non-interactive check)
@test "missing language shows available options" {
    run "$GENERATE_SCRIPT" --path="$TEST_DIR" --dry-run 2>&1
    [ "$status" -ne 0 ]
    # Should list available languages
    [[ "$output" == *"javascript"* ]] || [[ "$output" == *"go"* ]] || [[ "$output" == *"python"* ]]
}
```

**Step 2: Run test to verify current behavior**

Run: `cd test && bats args.bats -f "missing language"`

**Step 3: Update error message to show available languages**

Modify the error handling (around line 555) to show options:

```bash
# Validate required arguments for new file generation
if [[ "$UPGRADE" != "true" && "$SYNC" != "true" && -z "$LANGUAGES" ]]; then
    echo "[ERROR] --language is required for new file generation" >&2
    echo "" >&2
    echo "Available languages:" >&2
    echo "  go          - Go projects" >&2
    echo "  javascript  - JavaScript/TypeScript/Node.js (aliases: js, node, ts)" >&2
    echo "  python      - Python projects (aliases: py)" >&2
    echo "  shell       - Shell scripts (aliases: bash, sh)" >&2
    echo "  dart-flutter - Dart/Flutter projects (aliases: flutter, dart)" >&2
    echo "" >&2
    echo "Available project types:" >&2
    echo "  cli-tools     - Command-line tools" >&2
    echo "  web-apps      - Web applications" >&2
    echo "  mobile-apps   - Mobile applications" >&2
    echo "  genesis-tools - Genesis framework tools" >&2
    echo "" >&2
    echo "Example: generate-agents.sh --language=go,js --type=web-apps --path=./my-project" >&2
    exit 1
fi
```

**Step 4: Run test to verify it passes**

Run: `cd test && bats args.bats`
Expected: PASS

**Step 5: Commit**

```bash
git add generate-agents.sh test/args.bats
git commit -m "feat: show available languages and types in error message"
```

---

## Task 3: Detect Existing Guidance Files

**Files:**
- Modify: `generate-agents.sh` (add detection function)
- Test: `test/migrate.bats` (new test file)

**Step 1: Create new test file with failing test**

Create `test/migrate.bats`:

```bash
#!/usr/bin/env bats
# Migration Tests

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# Test: Detects existing CLAUDE.md with content
@test "detects existing CLAUDE.md with substantial content" {
    mkdir -p "$TEST_DIR"
    # Create CLAUDE.md with >100 bytes of content
    cat > "$TEST_DIR/CLAUDE.md" << 'EOF'
# Project Guide

This is substantial project-specific content that should not be lost.

## Rules
- Do this
- Do that
EOF

    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -ne 0 ]
    [[ "$output" == *"existing"* ]] || [[ "$output" == *"CLAUDE.md"* ]] || [[ "$output" == *"--migrate"* ]]
}

# Test: Ignores small redirect CLAUDE.md
@test "ignores small redirect CLAUDE.md" {
    mkdir -p "$TEST_DIR"
    echo "See Agents.md" > "$TEST_DIR/CLAUDE.md"

    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR" --dry-run
    [ "$status" -eq 0 ]
}

# Test: Detects existing Agents.md without markers
@test "detects existing Agents.md without markers" {
    create_agents_without_markers "$TEST_DIR"

    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -ne 0 ]
    [[ "$output" == *"existing"* ]] || [[ "$output" == *"--migrate"* ]]
}
```

**Step 2: Run test to verify it fails**

Run: `cd test && bats migrate.bats`
Expected: FAIL - no detection yet

**Step 3: Write the detection function**

Add to `generate-agents.sh` after the alias resolution:

```bash
# Minimum bytes to consider a file as having substantial content (not just a redirect)
MIN_CONTENT_BYTES=100

# Check for existing guidance files that would be overwritten
check_existing_guidance() {
    local path="$1"
    local found_files=""

    # Check CLAUDE.md (if >100 bytes, it's not just a redirect)
    if [[ -f "$path/CLAUDE.md" ]]; then
        local size
        size=$(wc -c < "$path/CLAUDE.md" | tr -d ' ')
        if [[ "$size" -gt "$MIN_CONTENT_BYTES" ]]; then
            found_files="CLAUDE.md ($size bytes)"
        fi
    fi

    # Check Agents.md without markers
    if [[ -f "$path/Agents.md" ]]; then
        if ! grep -q "$MARKER_START" "$path/Agents.md"; then
            local size
            size=$(wc -c < "$path/Agents.md" | tr -d ' ')
            found_files="${found_files:+$found_files, }Agents.md ($size bytes, no markers)"
        fi
    fi

    # Check AGENTS.md (case variation)
    if [[ -f "$path/AGENTS.md" ]]; then
        if ! grep -q "$MARKER_START" "$path/AGENTS.md"; then
            local size
            size=$(wc -c < "$path/AGENTS.md" | tr -d ' ')
            found_files="${found_files:+$found_files, }AGENTS.md ($size bytes, no markers)"
        fi
    fi

    echo "$found_files"
}
```

**Step 4: Add check before generation**

Add before the generation output section (around line 587):

```bash
# Check for existing guidance files (unless --migrate is used)
if [[ "$MIGRATE" != "true" && "$UPGRADE" != "true" && "$DRY_RUN" != "true" ]]; then
    existing=$(check_existing_guidance "$OUTPUT_PATH")
    if [[ -n "$existing" ]]; then
        echo "[ERROR] Found existing guidance files: $existing" >&2
        echo "" >&2
        echo "  These files contain project-specific content that would be lost." >&2
        echo "  Use --migrate to safely incorporate this content into the new Agents.md." >&2
        echo "" >&2
        echo "  Example: generate-agents.sh --migrate --language=go --path=$OUTPUT_PATH" >&2
        exit 1
    fi
fi
```

**Step 5: Add --migrate flag parsing**

Add to argument parsing:

```bash
--migrate) MIGRATE=true ;;
```

And initialize at top:

```bash
MIGRATE=false
```

**Step 6: Run test to verify it passes**

Run: `cd test && bats migrate.bats`
Expected: PASS

**Step 7: Commit**

```bash
git add generate-agents.sh test/migrate.bats
git commit -m "feat: detect existing guidance files, require --migrate"
```

---

## Task 4: Generate MIGRATION-PROMPT.md

**Files:**
- Modify: `generate-agents.sh` (add migration prompt generation)
- Test: `test/migrate.bats` (add tests)

**Step 1: Write the failing test**

Add to `test/migrate.bats`:

```bash
# Test: --migrate creates MIGRATION-PROMPT.md
@test "--migrate creates MIGRATION-PROMPT.md" {
    mkdir -p "$TEST_DIR"
    cat > "$TEST_DIR/CLAUDE.md" << 'EOF'
# Project Guide
Substantial content here that needs migration.
## Custom Rules
- Rule 1
- Rule 2
EOF

    run "$GENERATE_SCRIPT" --migrate --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/MIGRATION-PROMPT.md" ]
    [ -f "$TEST_DIR/Agents.md" ]
}

# Test: MIGRATION-PROMPT.md contains existing content
@test "MIGRATION-PROMPT.md contains existing content" {
    mkdir -p "$TEST_DIR"
    cat > "$TEST_DIR/CLAUDE.md" << 'EOF'
# My Unique Project Guide
Very specific content ABC123
EOF

    run "$GENERATE_SCRIPT" --migrate --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    grep -q "ABC123" "$TEST_DIR/MIGRATION-PROMPT.md"
}

# Test: MIGRATION-PROMPT.md has deletion note
@test "MIGRATION-PROMPT.md has deletion note" {
    mkdir -p "$TEST_DIR"
    echo "Substantial content here for testing purposes" > "$TEST_DIR/CLAUDE.md"

    run "$GENERATE_SCRIPT" --migrate --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    grep -qi "delete" "$TEST_DIR/MIGRATION-PROMPT.md"
}

# Test: .gitignore updated with MIGRATION-PROMPT.md
@test ".gitignore includes MIGRATION-PROMPT.md" {
    mkdir -p "$TEST_DIR"
    echo "Substantial content here for testing purposes" > "$TEST_DIR/CLAUDE.md"

    run "$GENERATE_SCRIPT" --migrate --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    grep -q "MIGRATION-PROMPT.md" "$TEST_DIR/.gitignore"
}
```

**Step 2: Run test to verify it fails**

Run: `cd test && bats migrate.bats`
Expected: FAIL

**Step 3: Write the migration prompt generator**

Add function to `generate-agents.sh`:

```bash
# Generate the LLM migration prompt
generate_migration_prompt() {
    local path="$1"
    local existing_content=""
    local source_file=""

    # Collect existing content
    if [[ -f "$path/CLAUDE.md" ]]; then
        local size
        size=$(wc -c < "$path/CLAUDE.md" | tr -d ' ')
        if [[ "$size" -gt "$MIN_CONTENT_BYTES" ]]; then
            source_file="CLAUDE.md"
            existing_content=$(cat "$path/CLAUDE.md")
        fi
    fi

    if [[ -f "$path/Agents.md" ]] && ! grep -q "$MARKER_START" "$path/Agents.md"; then
        source_file="${source_file:+$source_file + }Agents.md"
        existing_content="${existing_content}

---

$(cat "$path/Agents.md")"
    fi

    if [[ -f "$path/AGENTS.md" ]] && ! grep -q "$MARKER_START" "$path/AGENTS.md"; then
        source_file="${source_file:+$source_file + }AGENTS.md"
        existing_content="${existing_content}

---

$(cat "$path/AGENTS.md")"
    fi

    cat << 'PROMPT_EOF'
# Golden Agents Migration Prompt

> **DELETE THIS FILE** after completing the migration.

You are helping migrate project-specific AI guidance into the golden-agents framework.

## Instructions

1. Read the **Existing Content** below (from the old guidance files)
2. Read the **New Framework** in `Agents.md` (already generated)
3. Identify all **project-specific** guidance in the existing content:
   - Project-specific rules, workflows, conventions
   - File paths, commands, scripts unique to this project
   - Team policies, deployment procedures
   - Technology-specific guidance not covered by the framework
4. Add the project-specific content to `Agents.md` in the section after `<!-- GOLDEN:framework:end -->`
5. **DO NOT** duplicate content already in the framework (superpowers, anti-slop, etc.)
6. **DO NOT** lose any project-specific information
7. Delete this file when done

## Source Files
PROMPT_EOF
    echo ""
    echo "Migrated from: $source_file"
    echo ""
    echo "## Existing Content"
    echo ""
    echo '```markdown'
    echo "$existing_content"
    echo '```'
    echo ""
    echo "## Next Steps"
    echo ""
    echo "1. Open \`Agents.md\` and find the \`<!-- GOLDEN:framework:end -->\` marker"
    echo "2. Add your project-specific content after that marker"
    echo "3. Delete this \`MIGRATION-PROMPT.md\` file"
    echo "4. Commit the changes"
}
```

**Step 4: Add migration mode handling**

Add after the upgrade handling section:

```bash
# Handle migrate mode
if [[ "$MIGRATE" == "true" ]]; then
    mkdir -p "$OUTPUT_PATH"

    # Check if there's content to migrate
    existing=$(check_existing_guidance "$OUTPUT_PATH")
    if [[ -z "$existing" ]]; then
        echo "[INFO] No existing guidance files found. Running normal generation."
    else
        echo "[INFO] Found existing guidance: $existing"
        echo "[INFO] Generating migration prompt..."

        # Generate the migration prompt
        generate_migration_prompt "$OUTPUT_PATH" > "$OUTPUT_PATH/MIGRATION-PROMPT.md"
        echo "[OK] Created: $OUTPUT_PATH/MIGRATION-PROMPT.md"

        # Add to .gitignore
        if [[ -f "$OUTPUT_PATH/.gitignore" ]]; then
            if ! grep -q "MIGRATION-PROMPT.md" "$OUTPUT_PATH/.gitignore"; then
                echo "MIGRATION-PROMPT.md" >> "$OUTPUT_PATH/.gitignore"
            fi
        else
            echo "MIGRATION-PROMPT.md" > "$OUTPUT_PATH/.gitignore"
        fi
        echo "[OK] Added MIGRATION-PROMPT.md to .gitignore"
    fi

    # Continue with normal generation (framework Agents.md)
    # Fall through to normal generation below
fi
```

**Step 5: Run test to verify it passes**

Run: `cd test && bats migrate.bats`
Expected: PASS

**Step 6: Commit**

```bash
git add generate-agents.sh test/migrate.bats
git commit -m "feat: generate MIGRATION-PROMPT.md with LLM instructions"
```

---

## Task 5: Update Help Text and Documentation

**Files:**
- Modify: `generate-agents.sh` (update usage)
- Modify: `README.md` (add migration docs)

**Step 1: Update usage() function**

Add to OPTIONS section:

```
    --migrate           Migrate existing guidance files (creates MIGRATION-PROMPT.md)
```

Add new MIGRATION section after UPGRADE SAFETY:

```
MIGRATION (First-time adoption)
    When existing guidance files are detected (CLAUDE.md, AGENTS.md with content),
    generation is blocked to prevent data loss. Use --migrate to:

    1. Generate the framework Agents.md
    2. Create MIGRATION-PROMPT.md with your existing content
    3. Add MIGRATION-PROMPT.md to .gitignore

    Then paste MIGRATION-PROMPT.md into your AI assistant to complete the migration.
```

Add LANGUAGE ALIASES section:

```
LANGUAGE ALIASES
    js, node, ts, typescript  →  javascript
    py, python3               →  python
    bash, sh, zsh             →  shell
    flutter, dart             →  dart-flutter
    golang                    →  go
```

**Step 2: Commit**

```bash
git add generate-agents.sh README.md
git commit -m "docs: add migration and alias documentation"
```

---

## Task 6: Run Full Test Suite

**Step 1: Run all BATS tests**

```bash
cd test && bats *.bats
```

Expected: All tests pass

**Step 2: Run PowerShell tests (if on Windows)**

```powershell
Invoke-Pester -Path test/generate-agents.Tests.ps1
```

**Step 3: Manual integration test**

```bash
# Test on RecipeArchive
cd /Users/matt/GitHub/Personal/golden-agents
./generate-agents.sh --migrate --language=js,go --type=web-apps --path=/Users/matt/GitHub/Personal/RecipeArchive
```

Expected:
- Creates `Agents.md` with framework content
- Creates `MIGRATION-PROMPT.md` with CLAUDE.md content
- Adds to `.gitignore`

**Step 4: Commit final state**

```bash
git add -A
git commit -m "feat: complete migration feature with aliases and detection"
```

