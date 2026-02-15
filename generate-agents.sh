#!/usr/bin/env bash
#
# generate-agents.sh - Golden Agents Framework Generator
#
# Generates project-specific Agents.md files from modular templates.
# Supports progressive loading (~60 lines) for efficient AI context usage.
#
# Repository: https://github.com/bordenet/golden-agents
# Author:     Matt J Bordenet (@bordenet)
# License:    MIT
#
# Usage:
#   ./generate-agents.sh --language=go --path=./my-project
#   ./generate-agents.sh --upgrade --apply --path=./my-project
#   ./generate-agents.sh --help
#
# See --help for full documentation.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
REPO_URL="https://github.com/bordenet/golden-agents.git"

# Defaults
LANGUAGES=""
PROJECT_TYPE=""
OUTPUT_PATH="."
PROJECT_NAME=""
# Mode is progressive by default
FULL=false        # Legacy mode, deprecated
DRY_RUN=false
SYNC=false
UPGRADE=false
APPLY=false
MIGRATE=false
ADOPT=false
DEDUPE=false

# Markers for upgrade-safe sections
MARKER_START="<!-- GOLDEN:framework:start -->"
MARKER_END="<!-- GOLDEN:framework:end -->"
FRAMEWORK_VERSION="1.4.0"
SELF_MANAGE_START="<!-- GOLDEN:self-manage:start -->"
SELF_MANAGE_END="<!-- GOLDEN:self-manage:end -->"

# usage()
# Prints comprehensive help documentation to stdout.
# Follows man page conventions (NAME, SYNOPSIS, DESCRIPTION, OPTIONS, EXAMPLES).
# Arguments: none
# Returns: 0
usage() {
    cat << 'EOF'
NAME
    generate-agents.sh - Generate project-specific Agents.md from modular templates

SYNOPSIS
    generate-agents.sh [OPTIONS]
    generate-agents.sh --sync
    generate-agents.sh --language=LANG [--type=TYPE] [--path=PATH] [--progressive]
    generate-agents.sh --upgrade [--apply] --path=PATH
    generate-agents.sh --adopt --language=LANG --path=PATH
    generate-agents.sh --dedupe --path=PATH

DESCRIPTION
    Generates an Agents.md file from modular templates.

    Output mode:
    Progressive (~60 lines core with on-demand module loading from templates)

    When upgrading existing files, only framework sections (between markers) are
    replaced. Project-specific content is preserved.

PLATFORM SUPPORT
    Linux ........... Native (works out of the box)
    macOS ........... Native (works out of the box)
    Windows WSL ..... Native (run from WSL bash shell)
    Windows Native .. Requires Git Bash, Cygwin, or MSYS2

    Requirements: Bash 4.0+, Git

    NOTE: Native PowerShell/cmd.exe is NOT supported. This is a bash script.
          On Windows, use WSL (recommended), Git Bash, Cygwin, or MSYS2.

OPTIONS
    --language=LANG     Languages to include (comma-separated, see LANGUAGE ALIASES below)
    --type=TYPE         Project type (genesis-tools, cli-tools, web-apps, mobile-apps)
    --path=PATH         Output directory (default: current directory)
    --name=NAME         Project name for header (default: directory name)
    --progressive       Generate minimal core (~60 lines) with on-demand loading (default)
    --sync              Update local templates from GitHub
    --dry-run           Print what would be generated without writing
    --migrate           Migrate existing guidance files (creates MIGRATION-PROMPT.md)
    --adopt             Adopt existing Agents.md (backs up, appends, creates ADOPT-PROMPT.md)
    --dedupe            Deduplicate bloated project-specific section (for files WITH markers)
    --upgrade           Upgrade existing Agents.md (dry-run by default, shows diff)
    --apply             Apply upgrade changes (requires --upgrade, creates backup first)
    -h, --help          Show this help message
    -v, --version       Show version information

LANGUAGE ALIASES
    Canonical names and their aliases:

    go ............. golang
    javascript ..... js, node, nodejs, ts, typescript
    python ......... py, python3
    shell .......... bash, sh, zsh
    dart-flutter ... flutter, dart

MIGRATION (First-time adoption)
    When existing guidance files are detected (CLAUDE.md, AGENTS.md with content),
    generation is blocked to prevent data loss. Use --migrate to:

    1. Generate the framework Agents.md
    2. Create MIGRATION-PROMPT.md with your existing content
    3. Add MIGRATION-PROMPT.md to .gitignore

    Then paste MIGRATION-PROMPT.md content into your AI assistant to complete migration.
    Delete MIGRATION-PROMPT.md after migration is complete.

UPGRADE SAFETY
    - Without --apply: shows diff of what would change (safe)
    - With --apply: creates .backup, then applies changes
    - Files WITHOUT markers: REFUSES to upgrade (suggests migration)
    - Project-specific sections (outside markers) are ALWAYS preserved

ADOPTION (Existing Agents.md without markers)
    Use --adopt when you have an existing Agents.md that wasn't created by
    golden-agents. This mode:

    1. Backs up your original Agents.md to Agents.md.original
    2. Generates framework content with markers
    3. Appends your original content under "## Preserved Project Content"
    4. Creates ADOPT-PROMPT.md with aggressive deduplication instructions

    The goal is MINIMAL OUTPUT. After running the deduplication prompt:
    - Simple projects: 0-20 lines of project-specific content
    - Moderate projects: 20-50 lines
    - Complex projects: 50-100 lines

    If your result exceeds 100 lines, you kept too much generic advice.

DEDUPLICATION (Existing Agents.md with bloated project section)
    Use --dedupe when you have an Agents.md that WAS created by golden-agents
    but has a bloated project-specific section (>100 lines). This mode:

    1. Verifies the file has framework markers
    2. Counts project-specific lines (after the end marker)
    3. Creates ADOPT-PROMPT.md with deduplication instructions
    4. Does NOT modify the Agents.md (you apply changes after review)

    This is for files that already have markers but need aggressive pruning.
    The --adopt command is for files WITHOUT markers.

EXAMPLES
    # Generate for a Go CLI project
    generate-agents.sh --language=go --type=cli-tools --path=./my-project

    # Generate for a Python web app
    generate-agents.sh --language=python --type=web-apps --path=./my-api

    # Update templates from GitHub
    generate-agents.sh --sync

    # Migrate existing CLAUDE.md/AGENTS.md into golden-agents framework
    generate-agents.sh --migrate --language=js,go --type=web-apps --path=./my-project

    # Adopt existing Agents.md (backs up, appends, generates dedup prompt)
    generate-agents.sh --adopt --language=typescript --path=./existing-project

    # Deduplicate bloated project section (for files already using golden-agents)
    generate-agents.sh --dedupe --path=./bloated-project

    # Preview upgrade (safe, writes nothing)
    generate-agents.sh --upgrade --path=./my-project

    # Apply upgrade after preview
    generate-agents.sh --upgrade --apply --path=./my-project

    # Windows (Git Bash)
    ~/.golden-agents/generate-agents.sh --language=python --path=./my-project

    # Windows (WSL)
    wsl ~/.golden-agents/generate-agents.sh --language=go --path=./my-project
EOF
}

# version()
# Prints the script version to stdout.
# Arguments: none
# Returns: 0
version() {
    echo "golden-agents generate-agents.sh v${FRAMEWORK_VERSION}"
}

# sync_templates()
# Updates local templates by pulling from the GitHub repository.
# Requires the script directory to be a git repository.
# Arguments: none
# Returns: 0 on success, 1 if not a git repo
sync_templates() {
    echo "[INFO] Syncing templates from GitHub..."

    if [[ -d "$SCRIPT_DIR/.git" ]]; then
        cd "$SCRIPT_DIR"
        git pull --rebase origin main
        echo "[OK] Templates updated"
    else
        echo "[WARN] Not a git repo. Re-clone from: $REPO_URL"
        exit 1
    fi
}

# resolve_language_alias <alias>
# Converts language aliases to their canonical names.
# Arguments:
#   $1 - Language name or alias (e.g., "js", "py", "golang")
# Returns: Canonical language name via stdout (e.g., "javascript", "python", "go")
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

# resolve_languages <comma-separated-list>
# Resolves a comma-separated list of language aliases to canonical names.
# Deduplicates the result (e.g., "js,typescript" becomes "javascript").
# Arguments:
#   $1 - Comma-separated list of language names/aliases
# Returns: Comma-separated list of canonical names via stdout
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

# Minimum bytes to consider a file as having substantial content (not just a redirect)
MIN_CONTENT_BYTES=100

# check_existing_guidance <path>
# Checks for existing guidance files that would be overwritten.
# Detects CLAUDE.md, Agents.md, and AGENTS.md with substantial content.
# Arguments:
#   $1 - Directory path to check
# Returns: Space-separated list of found files with sizes via stdout, or empty string
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

# generate_migration_prompt <path>
# Generates a markdown prompt file for LLM-assisted migration.
# Collects content from existing CLAUDE.md, Agents.md, and AGENTS.md files.
# Outputs a structured prompt with instructions for deduplication.
# Arguments:
#   $1 - Directory path containing existing guidance files
# Returns: Migration prompt markdown via stdout
generate_migration_prompt() {
    local path="$1"
    local existing_content=""
    local source_file=""

    # Collect existing content from CLAUDE.md
    if [[ -f "$path/CLAUDE.md" ]]; then
        local size
        size=$(wc -c < "$path/CLAUDE.md" | tr -d ' ')
        if [[ "$size" -gt "$MIN_CONTENT_BYTES" ]]; then
            source_file="CLAUDE.md"
            existing_content=$(cat "$path/CLAUDE.md")
        fi
    fi

    # Collect from Agents.md without markers
    if [[ -f "$path/Agents.md" ]] && ! grep -q "$MARKER_START" "$path/Agents.md"; then
        local size
        size=$(wc -c < "$path/Agents.md" | tr -d ' ')
        source_file="${source_file:+$source_file + }Agents.md"
        if [[ -n "$existing_content" ]]; then
            existing_content="$existing_content

---

$(cat "$path/Agents.md")"
        else
            existing_content=$(cat "$path/Agents.md")
        fi
    fi

    # Collect from AGENTS.md without markers
    if [[ -f "$path/AGENTS.md" ]] && ! grep -q "$MARKER_START" "$path/AGENTS.md"; then
        local size
        size=$(wc -c < "$path/AGENTS.md" | tr -d ' ')
        source_file="${source_file:+$source_file + }AGENTS.md"
        if [[ -n "$existing_content" ]]; then
            existing_content="$existing_content

---

$(cat "$path/AGENTS.md")"
        else
            existing_content=$(cat "$path/AGENTS.md")
        fi
    fi

    cat << 'PROMPT_EOF'
# Golden Agents Migration Prompt

> **DELETE THIS FILE** after completing the migration.

You are helping migrate project-specific AI guidance into the golden-agents framework.

## Instructions

1. Read the **Existing Content** below (from the old guidance files)
2. Read the **New Framework** in `Agents.md` (already generated)
3. Apply the **10-word test** to each piece of content:
   - Can you express this in under 10 words with specific names/paths/commands?
   - YES → Keep it (project-specific)
   - NO → Skip it (framework already covers it)
4. Add ONLY project-specific content to `Agents.md` after `<!-- GOLDEN:framework:end -->`
5. **DO NOT** duplicate content already in the framework (quality gates, anti-slop, etc.)
6. **DO NOT** lose any genuinely project-specific information

## Target Sizes

| Project Complexity | Target Size |
|-------------------|-------------|
| Simple (single language, standard tooling) | **0-20 lines** |
| Moderate (multi-language, some custom workflows) | **20-50 lines** |
| Complex (many integrations, strict domain rules) | **50-100 lines** |

**If your project exceeds 100 lines** of genuinely project-specific content:
1. Create a \`.ai-guidance/\` directory in your repo
2. Split content into topic-specific modules (e.g., \`mobile-builds.md\`, \`security.md\`)
3. Add a loading table to Agents.md referencing when to load each module
4. Keep Agents.md under 150 lines with quick reference + loading instructions

## Source Files
PROMPT_EOF
    echo ""
    echo "Migrated from: $source_file"
    local source_lines
    source_lines=$(echo "$existing_content" | wc -l | tr -d ' ')
    echo "Original size: $source_lines lines"
    echo ""
    echo "## Existing Content"
    echo ""
    echo '```markdown'
    echo "$existing_content"
    echo '```'
    echo ""
    echo "## Report Metrics"
    echo ""
    echo "After adding project-specific content to Agents.md, report:"
    echo ""
    echo '```'
    echo "MIGRATION SUMMARY"
    echo "━━━━━━━━━━━━━━━━━"
    echo "Original guidance file: $source_lines lines"
    echo "Project-specific content added: ~[Y] lines"
    echo "Reduction: [Z]%"
    echo ""
    echo "Kept [M] project-specific items (paths, commands, policies, domain rules)"
    echo "Skipped [N] generic items (covered by framework)"
    echo '```'
    echo ""
    echo "## Next Steps"
    echo ""
    echo "1. Open \`Agents.md\` and find the \`<!-- GOLDEN:framework:end -->\` marker"
    echo "2. Add your project-specific content after that marker"
    echo "3. Report the metrics above"
    echo "4. Delete this \`MIGRATION-PROMPT.md\` file"
    echo "5. Commit the changes"
}

# Parse arguments
for arg in "$@"; do
    case $arg in
        --language=*) LANGUAGES="${arg#*=}" ;;
        --type=*) PROJECT_TYPE="${arg#*=}" ;;
        --path=*) OUTPUT_PATH="${arg#*=}" ;;
        --name=*) PROJECT_NAME="${arg#*=}" ;;
        --progressive) ;; # Already the default, flag accepted for clarity
        --full)
            FULL=true
            echo "[DEPRECATED] --full mode generates 800+ line files that AI assistants cannot follow." >&2
            echo "[DEPRECATED] Use progressive mode (default) instead." >&2
            ;;
        --sync) SYNC=true ;;
        --dry-run) DRY_RUN=true ;;
        --upgrade) UPGRADE=true ;;
        --apply) APPLY=true ;;
        --migrate) MIGRATE=true ;;
        --adopt) ADOPT=true ;;
        --dedupe) DEDUPE=true ;;
        -h|--help) usage; exit 0 ;;
        -v|--version) version; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; usage; exit 1 ;;
    esac
done

# Validate --apply requires --upgrade
if [[ "$APPLY" == "true" && "$UPGRADE" != "true" ]]; then
    echo "Error: --apply requires --upgrade" >&2
    exit 1
fi

# Resolve language aliases
if [[ -n "$LANGUAGES" ]]; then
    LANGUAGES=$(resolve_languages "$LANGUAGES")
fi

# Handle sync mode
if [[ "$SYNC" == "true" ]]; then
    sync_templates
    exit 0
fi

# Validate --adopt requires --language
if [[ "$ADOPT" == "true" && -z "$LANGUAGES" ]]; then
    echo "Error: --adopt requires --language" >&2
    exit 1
fi

# Validate --dedupe requires --path
if [[ "$DEDUPE" == "true" && "$OUTPUT_PATH" == "." ]]; then
    echo "Error: --dedupe requires --path" >&2
    exit 1
fi

# Validate (skip language check for upgrade mode and dedupe mode)
if [[ -z "$LANGUAGES" && "$UPGRADE" != "true" && "$DEDUPE" != "true" ]]; then
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

# Check for existing guidance files (unless --migrate or --upgrade or --adopt or --dedupe or --dry-run is used)
if [[ "$MIGRATE" != "true" && "$UPGRADE" != "true" && "$ADOPT" != "true" && "$DEDUPE" != "true" && "$DRY_RUN" != "true" ]]; then
    existing=$(check_existing_guidance "$OUTPUT_PATH")
    if [[ -n "$existing" ]]; then
        echo "[ERROR] Found existing guidance files: $existing" >&2
        echo "" >&2
        echo "  These files contain project-specific content that would be lost." >&2
        echo "  Use --migrate to safely incorporate this content into the new Agents.md." >&2
        echo "  Use --adopt to bring an existing Agents.md into the framework." >&2
        echo "" >&2
        echo "  Example: generate-agents.sh --migrate --language=go --path=$OUTPUT_PATH" >&2
        echo "  Example: generate-agents.sh --adopt --language=go --path=$OUTPUT_PATH" >&2
        exit 1
    fi
fi

# Handle migrate mode - generate migration prompt if needed
if [[ "$MIGRATE" == "true" ]]; then
    mkdir -p "$OUTPUT_PATH"

    # Check if there's content to migrate
    existing=$(check_existing_guidance "$OUTPUT_PATH")
    if [[ -n "$existing" ]]; then
        # Extract filename and count lines
        source_file=$(echo "$existing" | cut -d' ' -f1)
        source_lines=$(wc -l < "$OUTPUT_PATH/$source_file" | tr -d ' ')

        echo "[INFO] Found existing guidance: $existing"
        echo "[INFO] Source file: $source_file ($source_lines lines)"
        echo "[INFO] Generating migration prompt..."

        # Generate the migration prompt
        generate_migration_prompt "$OUTPUT_PATH" > "$OUTPUT_PATH/MIGRATION-PROMPT.md"
        echo "[OK] Created: $OUTPUT_PATH/MIGRATION-PROMPT.md"
        echo "[INFO] Target: reduce to 0-100 lines of project-specific content"

        # Add to .gitignore
        if [[ -f "$OUTPUT_PATH/.gitignore" ]]; then
            if ! grep -q "MIGRATION-PROMPT.md" "$OUTPUT_PATH/.gitignore"; then
                echo "MIGRATION-PROMPT.md" >> "$OUTPUT_PATH/.gitignore"
            fi
        else
            echo "MIGRATION-PROMPT.md" > "$OUTPUT_PATH/.gitignore"
        fi
        echo "[OK] Added MIGRATION-PROMPT.md to .gitignore"
    else
        echo "[INFO] No existing guidance files found. Running normal generation."
    fi

    # Continue with normal generation (framework Agents.md)
    # Fall through to normal generation below
fi

# Handle adopt mode - bring existing Agents.md into framework
if [[ "$ADOPT" == "true" ]]; then
    mkdir -p "$OUTPUT_PATH"

    # Check for existing Agents.md without markers
    if [[ ! -f "$OUTPUT_PATH/Agents.md" ]]; then
        echo "[ERROR] No Agents.md found at $OUTPUT_PATH" >&2
        echo "  --adopt requires an existing Agents.md file to adopt." >&2
        exit 1
    fi

    if grep -q "$MARKER_START" "$OUTPUT_PATH/Agents.md"; then
        echo "[ERROR] Agents.md already has framework markers" >&2
        echo "  Use --upgrade instead to update framework sections." >&2
        exit 1
    fi

    echo "[INFO] Adopting existing Agents.md into golden-agents framework..."

    # Backup original
    cp "$OUTPUT_PATH/Agents.md" "$OUTPUT_PATH/Agents.md.original"
    echo "[OK] Backed up original: $OUTPUT_PATH/Agents.md.original"

    # Store original content
    original_content=$(cat "$OUTPUT_PATH/Agents.md.original")
    original_lines=$(wc -l < "$OUTPUT_PATH/Agents.md.original" | tr -d ' ')

    # Copy ADOPT-PROMPT.md template
    if [[ -f "$TEMPLATES_DIR/adopt-prompt.md" ]]; then
        cp "$TEMPLATES_DIR/adopt-prompt.md" "$OUTPUT_PATH/ADOPT-PROMPT.md"
        echo "[OK] Created: $OUTPUT_PATH/ADOPT-PROMPT.md"
    else
        echo "[WARN] Template not found: $TEMPLATES_DIR/adopt-prompt.md" >&2
    fi

    # Add to .gitignore
    if [[ -f "$OUTPUT_PATH/.gitignore" ]]; then
        if ! grep -q "ADOPT-PROMPT.md" "$OUTPUT_PATH/.gitignore"; then
            echo "ADOPT-PROMPT.md" >> "$OUTPUT_PATH/.gitignore"
        fi
        if ! grep -q "Agents.md.original" "$OUTPUT_PATH/.gitignore"; then
            echo "Agents.md.original" >> "$OUTPUT_PATH/.gitignore"
        fi
    else
        printf "ADOPT-PROMPT.md\nAgents.md.original\n" > "$OUTPUT_PATH/.gitignore"
    fi
    echo "[OK] Added ADOPT-PROMPT.md and Agents.md.original to .gitignore"

    # Generate framework content, then append original
    # We'll set a flag to append after generation
    ADOPT_ORIGINAL_CONTENT="$original_content"
    ADOPT_ORIGINAL_LINES="$original_lines"

    # Fall through to normal generation, which will append the original content
fi

# Handle dedupe mode - generate deduplication prompt for files WITH markers
if [[ "$DEDUPE" == "true" ]]; then
    # Check for existing Agents.md WITH markers
    if [[ ! -f "$OUTPUT_PATH/Agents.md" ]]; then
        echo "[ERROR] No Agents.md found at $OUTPUT_PATH" >&2
        echo "  --dedupe requires an existing Agents.md file with framework markers." >&2
        exit 1
    fi

    if ! grep -q "$MARKER_START" "$OUTPUT_PATH/Agents.md"; then
        echo "[ERROR] Agents.md does not have framework markers" >&2
        echo "  Use --adopt instead for files created without golden-agents." >&2
        exit 1
    fi

    # Count lines in project-specific section (after MARKER_END)
    marker_end_line=$(grep -n "$MARKER_END" "$OUTPUT_PATH/Agents.md" | head -1 | cut -d: -f1)
    total_lines=$(wc -l < "$OUTPUT_PATH/Agents.md" | tr -d ' ')
    project_lines=$((total_lines - marker_end_line))

    echo "[INFO] Analyzing Agents.md for deduplication..."
    echo "  Total lines: $total_lines"
    echo "  Framework section ends at line: $marker_end_line"
    echo "  Project-specific section: $project_lines lines"
    echo ""

    if [[ $project_lines -le 100 ]]; then
        echo "[OK] Project-specific section is already within target (<100 lines)"
        echo "  No deduplication needed."
        exit 0
    fi

    echo "[WARN] Project-specific section exceeds target (>100 lines)"
    echo "  Target for complex projects: 50-100 lines"
    echo "  Current: $project_lines lines"
    echo ""

    # Copy ADOPT-PROMPT.md template (same prompt works for dedupe)
    if [[ -f "$TEMPLATES_DIR/adopt-prompt.md" ]]; then
        cp "$TEMPLATES_DIR/adopt-prompt.md" "$OUTPUT_PATH/ADOPT-PROMPT.md"
        echo "[OK] Created: $OUTPUT_PATH/ADOPT-PROMPT.md"
    else
        echo "[ERROR] Template not found: $TEMPLATES_DIR/adopt-prompt.md" >&2
        exit 1
    fi

    # Add to .gitignore if not already there
    if [[ -f "$OUTPUT_PATH/.gitignore" ]]; then
        if ! grep -q "ADOPT-PROMPT.md" "$OUTPUT_PATH/.gitignore"; then
            echo "ADOPT-PROMPT.md" >> "$OUTPUT_PATH/.gitignore"
            echo "[OK] Added ADOPT-PROMPT.md to .gitignore"
        fi
    else
        echo "ADOPT-PROMPT.md" > "$OUTPUT_PATH/.gitignore"
        echo "[OK] Created .gitignore with ADOPT-PROMPT.md"
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "                    NEXT STEPS"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "  1. Open ADOPT-PROMPT.md in your AI assistant"
    echo "  2. Paste the contents of Agents.md after the prompt"
    echo "  3. The AI will propose aggressive deduplication"
    echo "  4. Review and approve the proposed changes"
    echo "  5. Apply the minimal result to Agents.md"
    echo "  6. Delete ADOPT-PROMPT.md and commit"
    echo ""
    echo "  Target: Reduce project-specific section from $project_lines to <100 lines"
    echo ""
    echo "═══════════════════════════════════════════════════════════════"

    exit 0
fi

# Set project name from directory if not specified
if [[ -z "$PROJECT_NAME" ]]; then
    PROJECT_NAME=$(basename "$(cd "$OUTPUT_PATH" 2>/dev/null && pwd)" 2>/dev/null || echo "Project")
fi

# get_lang_commands <language>
# Returns language-specific lint, build, test commands and coverage target.
# Output format: newline-separated KEY:VALUE pairs
#   LINT:<command>   - Linting command
#   BUILD:<command>  - Build/compile command
#   TEST:<command>   - Test command
#   COV:<percent>    - Coverage target percentage (or "N/A")
# Arguments:
#   $1 - Canonical language name (go, python, javascript, dart-flutter, shell)
# Returns: Key:value pairs via stdout, one per line
get_lang_commands() {
    local lang="$1"
    case "$lang" in
        go) echo "LINT:golangci-lint run ./..."; echo "BUILD:go build ./..."; echo "TEST:go test -race -coverprofile=coverage.out ./..."; echo "COV:80" ;;
        python) echo "LINT:pylint --fail-under=9.5 ."; echo "BUILD:mypy ."; echo "TEST:pytest --cov=. --cov-report=term-missing"; echo "COV:80" ;;
        javascript) echo "LINT:npm run lint"; echo "BUILD:npm run build"; echo "TEST:npm test"; echo "COV:70" ;;
        dart-flutter) echo "LINT:flutter analyze"; echo "BUILD:flutter build"; echo "TEST:flutter test --coverage"; echo "COV:70" ;;
        shell) echo "LINT:shellcheck *.sh"; echo "BUILD:bash -n *.sh"; echo "TEST:bats test/"; echo "COV:N/A" ;;
        *) echo "LINT:# lint"; echo "BUILD:# build"; echo "TEST:# test"; echo "COV:70" ;;
    esac
}

# generate_progressive()
# Generates a progressive-loading Agents.md (~60-80 lines).
# Uses on-demand module loading from $HOME/.golden-agents/templates/.
# Reads from global: LANGUAGES, PROJECT_TYPE, PROJECT_NAME, FRAMEWORK_VERSION
# Arguments: none (uses globals)
# Returns: Complete Agents.md content via stdout
generate_progressive() {
    local today
    today=$(date +%Y-%m-%d)
    local golden_agents_path="\$HOME/.golden-agents"

    IFS=',' read -ra lang_array <<< "$LANGUAGES"
    local first_lang="${lang_array[0]}"
    local lint_cmd build_cmd test_cmd coverage

    while IFS= read -r line; do
        case "$line" in
            LINT:*) lint_cmd="${line#LINT:}" ;;
            BUILD:*) build_cmd="${line#BUILD:}" ;;
            TEST:*) test_cmd="${line#TEST:}" ;;
            COV:*) coverage="${line#COV:}" ;;
        esac
    done < <(get_lang_commands "$first_lang")

    cat << HEADER
# AI Agent Guidelines - $PROJECT_NAME

> **Generated by**: [golden-agents](https://github.com/bordenet/golden-agents) v${FRAMEWORK_VERSION} (progressive)
> **Last Updated**: $today
> **Languages**: $LANGUAGES
> **Type**: ${PROJECT_TYPE:-general}

Minimal core with on-demand module loading. Templates at: \`$golden_agents_path/templates/\`

$MARKER_START

---

## Quality Gates (MANDATORY)

Before ANY commit:
1. **Lint**: \`$lint_cmd\`
2. **Build**: \`$build_cmd\`
3. **Test**: \`$test_cmd\`
4. **Coverage**: Minimum ${coverage}%

**Order matters.** Lint → Build → Test. Never skip steps.

---

## Communication Rules

- **No flattery** - Skip "Great question!" or "Excellent point!"
- **No hype** - Avoid "revolutionary", "game-changing", "seamless"
- **Evidence-based** - Cite sources or qualify as opinion
- **Direct** - State facts without embellishment

**Banned phrases**: production-grade, world-class, leverage, utilize, incredibly, extremely, Happy to help!

---

## 🚨 Progressive Module Loading

**STOP and load the relevant module BEFORE these actions:**

### Language Modules (🔴 Required)
HEADER

    # Generate language loading instructions with specific triggers
    for lang in "${lang_array[@]}"; do
        case "$lang" in
            go) echo "- 🔴 **BEFORE writing ANY \`.go\` file**: Read \`$golden_agents_path/templates/languages/go.md\`" ;;
            python) echo "- 🔴 **BEFORE writing ANY \`.py\` file**: Read \`$golden_agents_path/templates/languages/python.md\`" ;;
            javascript) echo "- 🔴 **BEFORE writing ANY \`.js\`, \`.ts\`, \`.jsx\`, \`.tsx\` file**: Read \`$golden_agents_path/templates/languages/javascript.md\`" ;;
            shell) echo "- 🔴 **BEFORE writing ANY \`.sh\` file or bash code block**: Read \`$golden_agents_path/templates/languages/shell.md\`" ;;
            dart-flutter) echo "- 🔴 **BEFORE writing ANY \`.dart\` file**: Read \`$golden_agents_path/templates/languages/dart-flutter.md\`" ;;
            *) echo "- 🔴 **BEFORE writing $lang code**: Read \`$golden_agents_path/templates/languages/${lang}.md\`" ;;
        esac
    done

    cat << MIDDLE

### Workflow Modules (🔴 Required)
- 🔴 **BEFORE any commit, PR, push, or merge**: Read \`$golden_agents_path/templates/workflows/security.md\`
- 🔴 **WHEN tests fail OR after 2+ failed fix attempts**: Read \`$golden_agents_path/templates/workflows/testing.md\`
- 🔴 **WHEN build fails OR lint errors appear**: Read \`$golden_agents_path/templates/workflows/build-hygiene.md\`
- 🟡 **BEFORE deploying to any environment**: Read \`$golden_agents_path/templates/workflows/deployment.md\`
- 🟡 **WHEN conversation exceeds 50 exchanges**: Read \`$golden_agents_path/templates/workflows/context-management.md\`

MIDDLE

    if [[ -n "$PROJECT_TYPE" ]]; then
        echo "### Project type guidance:"
        echo "- Read \`$golden_agents_path/templates/project-types/${PROJECT_TYPE}.md\`"
        echo ""
    fi

    cat << FOOTER
### Optional: Superpowers integration

If [superpowers](https://github.com/obra/superpowers) is installed, run at session start:

\`\`\`bash
node ~/.codex/superpowers-augment/superpowers-augment.js bootstrap
\`\`\`

$MARKER_END

---

## Project-Specific Rules

<!-- Add project-specific guidance below this line -->

FOOTER
}

# generate_full()
# Generates a full self-contained Agents.md (~800 lines).
# DEPRECATED: This mode generates files too large for AI assistants to follow.
# Includes all templates inline rather than using on-demand loading.
# Reads from global: LANGUAGES, PROJECT_TYPE, PROJECT_NAME, FRAMEWORK_VERSION
# Arguments: none (uses globals)
# Returns: Complete Agents.md content via stdout
generate_full() {
    local today
    today=$(date +%Y-%m-%d)

    cat << HEADER
# AI Agent Guidelines - $PROJECT_NAME

> **Generated by**: [golden-agents](https://github.com/bordenet/golden-agents) v${FRAMEWORK_VERSION}
> **Last Updated**: $today
> **Languages**: $LANGUAGES
> **Type**: ${PROJECT_TYPE:-general}

This file is self-contained and portable. No external references required.

$MARKER_START

---

HEADER

    # Core guidance
    echo "## Core Guidelines"
    echo ""
    cat "$TEMPLATES_DIR/core/superpowers.md"
    echo ""
    echo "---"
    echo ""
    cat "$TEMPLATES_DIR/core/communication.md"
    echo ""
    echo "---"
    echo ""
    cat "$TEMPLATES_DIR/core/anti-slop.md"
    echo ""
    echo "---"
    echo ""

    # Workflows
    echo "## Workflows"
    echo ""
    cat "$TEMPLATES_DIR/workflows/deployment.md"
    echo ""
    echo "---"
    echo ""
    cat "$TEMPLATES_DIR/workflows/testing.md"
    echo ""
    echo "---"
    echo ""
    cat "$TEMPLATES_DIR/workflows/security.md"
    echo ""
    echo "---"
    echo ""
    cat "$TEMPLATES_DIR/workflows/build-hygiene.md"
    echo ""
    echo "---"
    echo ""
    cat "$TEMPLATES_DIR/workflows/context-management.md"
    echo ""

    # Language-specific
    echo "---"
    echo ""
    echo "## Language-Specific Guidelines"
    echo ""

    IFS=',' read -ra lang_array <<< "$LANGUAGES"
    for lang in "${lang_array[@]}"; do
        lang_file="$TEMPLATES_DIR/languages/${lang}.md"
        if [[ -f "$lang_file" ]]; then
            cat "$lang_file"
            echo ""
            echo "---"
            echo ""
        else
            echo "Warning: No template for language: $lang" >&2
        fi
    done

    # Project type
    if [[ -n "$PROJECT_TYPE" ]]; then
        type_file="$TEMPLATES_DIR/project-types/${PROJECT_TYPE}.md"
        if [[ -f "$type_file" ]]; then
            echo "## Project Type Guidelines"
            echo ""
            cat "$type_file"
            echo ""
        else
            echo "Warning: No template for project type: $PROJECT_TYPE" >&2
        fi
    fi

    cat << FOOTER

$MARKER_END

---

## Project-Specific Rules

<!-- Add project-specific guidance below this line -->

FOOTER
}

# generate_self_manage_block()
# Generates the 5-line self-management bootstrap block.
# This block is injected BEFORE the framework start marker.
# Arguments: none
# Returns: Bootstrap block content via stdout
generate_self_manage_block() {
    cat << 'SELF_MANAGE'
<!-- GOLDEN:self-manage:start -->
## ⚠️ Before ANY Task
1. Load `.ai-guidance/invariants.md` — contains critical rules
2. After editing THIS file, run: `wc -l Agents.md` — if >150, refactor before continuing
<!-- GOLDEN:self-manage:end -->

SELF_MANAGE
}

# upgrade_agents_md()
# Safely upgrades an existing Agents.md file with framework markers.
# Preserves all content outside the framework markers (project-specific sections).
# Creates a backup before applying changes when --apply is used.
# Reads from global: OUTPUT_PATH, LANGUAGES, PROJECT_TYPE, FULL, APPLY
# Arguments: none (uses globals)
# Returns: 0 on success, 1 on error
# Side effects: May modify Agents.md and create .backup file
upgrade_agents_md() {
    local existing_file="$OUTPUT_PATH/Agents.md"

    # Check if file exists
    if [[ ! -f "$existing_file" ]]; then
        echo "[ERROR] No Agents.md found at: $existing_file" >&2
        echo "  Use --language=... to generate a new file instead." >&2
        exit 1
    fi

    # Check for markers
    if ! grep -q "$MARKER_START" "$existing_file" || ! grep -q "$MARKER_END" "$existing_file"; then
        echo "[ERROR] Cannot upgrade: Agents.md lacks framework markers" >&2
        echo "" >&2
        echo "  This file was not generated by golden-agents v1.2.0+ or was manually" >&2
        echo "  created. Upgrade requires these markers to identify framework sections:" >&2
        echo "" >&2
        echo "    $MARKER_START" >&2
        echo "    $MARKER_END" >&2
        echo "" >&2
        echo "  Options:" >&2
        echo "    1. Regenerate with: generate-agents.sh --language=... --path=$OUTPUT_PATH" >&2
        echo "    2. Manually add markers around framework sections" >&2
        echo "" >&2
        echo "  REFUSING TO MODIFY to prevent data loss." >&2
        exit 1
    fi

    # Extract config from existing file header
    local existing_langs existing_type
    existing_langs=$(grep "Languages" "$existing_file" | head -1 | sed 's/.*: //' || echo "")
    existing_type=$(grep "Type" "$existing_file" | head -1 | sed 's/.*: //' || echo "general")

    # Use existing config if not overridden by flags
    if [[ -z "$LANGUAGES" ]]; then
        LANGUAGES="$existing_langs"
    fi
    if [[ -z "$PROJECT_TYPE" && "$existing_type" != "general" ]]; then
        PROJECT_TYPE="$existing_type"
    fi
    # Auto-detect mode if not explicitly set via flags
    # Progressive is the default; upgrade legacy full files to progressive
    if [[ "$FULL" != "true" ]]; then
        generator="generate_progressive"
        mode_label="progressive"
    fi

    if [[ -z "$LANGUAGES" ]]; then
        echo "[ERROR] Cannot determine languages from existing file or flags" >&2
        echo "  Specify --language=... to upgrade" >&2
        exit 1
    fi

    # Extract preserved content (before start marker and after end marker)
    local before_marker after_marker
    before_marker=$(sed -n "1,/$MARKER_START/p" "$existing_file" | sed '$ d')
    after_marker=$(sed -n "/$MARKER_END/,\$p" "$existing_file" | sed '1 d')

    # Generate new framework content
    local new_framework
    new_framework=$($generator | sed -n "/$MARKER_START/,/$MARKER_END/p")

    # Assemble upgraded file
    local upgraded_content
    upgraded_content="${before_marker}
${new_framework}
${after_marker}"

    # Show diff or apply
    if [[ "$APPLY" != "true" ]]; then
        echo "=== UPGRADE PREVIEW (dry-run) ==="
        echo "File: $existing_file"
        echo "Languages: $LANGUAGES"
        echo "Type: ${PROJECT_TYPE:-general}"
        echo ""
        echo "--- Changes ---"
        diff -u "$existing_file" <(echo "$upgraded_content") || true
        echo ""
        echo "[INFO] This is a preview. No changes made."
        echo "  To apply: generate-agents.sh --upgrade --apply --path=$OUTPUT_PATH"
    else
        # Create backup
        local backup_file="${existing_file}.backup"
        cp "$existing_file" "$backup_file"
        echo "[OK] Backup created: $backup_file"

        # Write upgraded content
        echo "$upgraded_content" > "$existing_file"
        echo "[OK] Upgraded: $existing_file"
        echo "  Framework: v${FRAMEWORK_VERSION}"
        echo "  Lines: $(wc -l < "$existing_file")"
        echo ""
        echo "  Project-specific content preserved."
        echo "  Backup: $backup_file"
    fi
}

# Select generator (progressive is default)
if [[ "$FULL" == "true" ]]; then
    generator="generate_full"
    mode_label="full"
else
    # Default: progressive
    generator="generate_progressive"
    mode_label="progressive"
fi

# Handle upgrade mode
if [[ "$UPGRADE" == "true" ]]; then
    upgrade_agents_md
    exit 0
fi

# create_redirect <filepath> <title>
# Creates a redirect file that points to Agents.md.
# Used for AI assistant-specific files (CLAUDE.md, CODEX.md, etc.).
# Arguments:
#   $1 - Full path to the redirect file to create
#   $2 - Title for the markdown header
# Returns: 0 on success
# Side effects: Creates/overwrites the specified file
create_redirect() {
    local path="$1"
    local title="$2"
    cat > "$path" << EOF
# $title

See **[Agents.md](./Agents.md)** for all AI guidance.
EOF
}

# Output (new file generation)
if [[ "$DRY_RUN" == "true" ]]; then
    echo "=== DRY RUN ($mode_label mode): Would generate the following Agents.md ==="
    echo ""
    $generator
    echo ""
    echo "=== Would also create redirect files: ==="
    echo "  CLAUDE.md        → Claude Code"
    echo "  CODEX.md         → OpenAI Codex CLI"
    echo "  AGENT.md         → Amp by Sourcegraph"
    echo "  GEMINI.md        → Google Gemini Code Assist"
    echo "  COPILOT.md       → GitHub Copilot"
    echo "  .github/copilot-instructions.md → GitHub Copilot (custom instructions)"
    echo ""
    echo "Note: AGENTS.md not created (conflicts with Agents.md on case-insensitive filesystems)"
else
    mkdir -p "$OUTPUT_PATH"
    output_file="$OUTPUT_PATH/Agents.md"
    $generator > "$output_file"

    # If in adopt mode, append the original content
    if [[ "$ADOPT" == "true" && -n "${ADOPT_ORIGINAL_CONTENT:-}" ]]; then
        cat >> "$output_file" << 'ADOPT_SECTION'

---

## Preserved Project Content

> **Note:** The content below was preserved from your original Agents.md.
> Run the ADOPT-PROMPT.md instructions with your AI assistant to deduplicate.
> Delete redundant content, keep only project-specific guidance.
> Target: 0-50 lines for most projects, max 100 lines for complex projects.

ADOPT_SECTION
        echo "$ADOPT_ORIGINAL_CONTENT" >> "$output_file"
        echo ""
        echo "[OK] Adopted existing Agents.md into framework"
        echo "  Original: ${ADOPT_ORIGINAL_LINES:-?} lines preserved"
        echo "  Framework: generated with markers"
        echo ""
        echo "Next steps:"
        echo "  1. Open ADOPT-PROMPT.md and paste it into your AI assistant"
        echo "  2. The AI will deduplicate the preserved content"
        echo "  3. Target: 0-50 lines of project-specific content"
        echo "  4. Delete ADOPT-PROMPT.md when done"
    fi

    echo "Generated ($mode_label): $output_file"
    echo "Lines: $(wc -l < "$output_file")"

    # Create redirect files for all AI coding assistants
    echo ""
    echo "Creating redirect files for AI assistants..."

    create_redirect "$OUTPUT_PATH/CLAUDE.md" "Claude Code Instructions"
    create_redirect "$OUTPUT_PATH/CODEX.md" "OpenAI Codex CLI Instructions"
    create_redirect "$OUTPUT_PATH/AGENT.md" "Amp by Sourcegraph Instructions"
    create_redirect "$OUTPUT_PATH/GEMINI.md" "Google Gemini Code Assist Instructions"
    create_redirect "$OUTPUT_PATH/COPILOT.md" "GitHub Copilot Instructions"

    # Note: We do NOT create AGENTS.md because it conflicts with Agents.md
    # on case-insensitive filesystems (macOS default, Windows).
    # OpenAI Codex CLI will use CODEX.md or read Agents.md directly.

    # Create GitHub Copilot custom instructions file
    mkdir -p "$OUTPUT_PATH/.github"
    cat > "$OUTPUT_PATH/.github/copilot-instructions.md" << EOF
# GitHub Copilot Custom Instructions

See **[../Agents.md](../Agents.md)** for all AI guidance.

## Summary

This project uses the Golden Agents Framework for AI coding assistant guidance.
All instructions are consolidated in Agents.md at the project root.
EOF

    echo "  ✓ CLAUDE.md        (Claude Code)"
    echo "  ✓ CODEX.md         (OpenAI Codex CLI)"
    echo "  ✓ AGENT.md         (Amp by Sourcegraph)"
    echo "  ✓ GEMINI.md        (Google Gemini)"
    echo "  ✓ COPILOT.md       (GitHub Copilot)"
    echo "  ✓ .github/copilot-instructions.md (GitHub Copilot custom)"
    echo ""
    echo "Note: AGENTS.md not created (conflicts with Agents.md on case-insensitive filesystems)"
fi

