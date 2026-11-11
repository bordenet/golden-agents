#!/usr/bin/env bash
#
# generate-agents.sh - Golden Agents Framework Generator
#
# Generates project-specific AGENTS.md files from modular templates.
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
PATH_GIVEN=false
PROJECT_NAME=""
# Mode is progressive by default
FULL=false        # Legacy mode, deprecated
SUPERPOWERS=false # Bootstrap block is off unless --superpowers is passed
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
# Line limit for AGENTS.md and each .ai-guidance/*.md. templates/core/invariants.md and
# templates/modular-migration-prompt.md state it literally; test/thresholds.bats keeps them in sync.
MAX_GUIDANCE_LINES=250
# Line budget for a freshly generated progressive AGENTS.md (test/size-limits.bats)
MAX_PROGRESSIVE_LINES=100
SELF_MANAGE_START="<!-- GOLDEN:self-manage:start -->"
# shellcheck disable=SC2034 # SELF_MANAGE_END defined for symmetry; will be used in Phase 3 bloat detection
SELF_MANAGE_END="<!-- GOLDEN:self-manage:end -->"

# usage()
# Prints comprehensive help documentation to stdout.
# Follows man page conventions (NAME, SYNOPSIS, DESCRIPTION, OPTIONS, EXAMPLES).
# Arguments: none
# Returns: 0
usage() {
    cat << 'EOF'
NAME
    generate-agents.sh - Generate project-specific AGENTS.md from modular templates

SYNOPSIS
    generate-agents.sh [OPTIONS]
    generate-agents.sh --sync
    generate-agents.sh --language=LANG [--type=TYPE] [--path=PATH] [--progressive]
    generate-agents.sh --upgrade [--apply] --path=PATH
    generate-agents.sh --adopt --language=LANG --path=PATH
    generate-agents.sh --dedupe --path=PATH

DESCRIPTION
    Generates an AGENTS.md file from modular templates.

    Output mode:
    Progressive (~60 lines core with on-demand module loading from templates)

    When upgrading existing files, only framework sections (between markers) are
    replaced. Project-specific content is preserved.

SIZE
    MAX_GUIDANCE_LINES stays 250. That is the lock this script enforces.
    200 lines is the soft ceiling for the always-loaded file. It is guidance
    for authors, not a second limit in this script. Overflow belongs in
    scoped rules, not in a longer AGENTS.md.
    Generation prints a token estimate (file bytes divided by 4, rounded up).
    Token counts vary by tokenizer. The line count is the check tests use.

PLATFORM SUPPORT
    Linux ........... Native (works out of the box)
    macOS ........... Native (works out of the box)
    Windows WSL ..... Native (run from WSL bash shell)
    Windows Native .. Requires Git Bash, Cygwin, or MSYS2

    Requirements: Bash 3.2+, Git

    NOTE: Native PowerShell/cmd.exe is NOT supported. This is a bash script.
          On Windows, use WSL (recommended), Git Bash, Cygwin, or MSYS2.

OPTIONS
    --language=LANG     Languages to include (comma-separated, see LANGUAGE ALIASES below)
    --type=TYPE         Project type (genesis-tools, cli-tools, web-apps, mobile-apps)
    --path=PATH         Output directory (default: current directory)
    --name=NAME         Project name for header (default: directory name)
                        Value options also accept a space: --path ./my-project
    --progressive       Generate minimal core (~60 lines) with on-demand loading (default)
    --superpowers       Write the superpowers bootstrap after the framework end
                        marker. It is omitted by default. Upgrade does not put it
                        back inside the framework. An existing bootstrap below
                        the end marker is left as it is.
    --sync              Update local templates from GitHub (git fetch, fast-forward
                        only; refuses on uncommitted changes or local commits)
    --dry-run           Print what would be generated without writing
    --migrate           Migrate existing guidance files (creates MIGRATION-PROMPT.md)
    --adopt             Adopt existing AGENTS.md (backs up, appends, creates ADOPT-PROMPT.md)
    --dedupe            Deduplicate bloated project-specific section (for files WITH markers)
    --upgrade           Upgrade existing AGENTS.md (dry-run by default, shows diff)
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

    1. Back up existing CLAUDE.md, AGENTS.md and other non-generated redirects
       to <file>.<YYYYmmdd-HHMMSS>.bak (not gitignored)
    2. Generate the framework AGENTS.md
    3. Create MIGRATION-PROMPT.md with your existing content
    4. Add MIGRATION-PROMPT.md to .gitignore

    Then paste MIGRATION-PROMPT.md content into your AI assistant to complete migration.
    Delete MIGRATION-PROMPT.md after migration is complete.

MODULES
    Progressive mode copies the selected language module, the project-type
    module, and the workflow modules named by the triggers into
    .golden-agents/modules/. The triggers read those relative paths.
    A <!-- golden-agents:modules ... --> comment next to the stamp records
    the sha256 of each copied file. --sync updates this checkout only.
    A consumer project changes when you run --upgrade --apply. The preview
    shows hash differences and writes nothing.

WRITE SAFETY
    CLAUDE.md, GEMINI.md, and .github/copilot-instructions.md are one-line
    @AGENTS.md imports and end with <!-- golden-agents:generated -->.
    CODEX.md, AGENT.md, and COPILOT.md are not generated. A generated copy or
    an exact 1.4.x stub of those three is removed. A hand-written copy stays.
    Any other redirect without the sentinel (other than an exact 1.4.x stub)
    holds your content. Any existing AGENTS.md also counts.
    - Plain generation: refuses, lists each blocking file, writes nothing, exits 1
    - --adopt / --migrate: copies each blocking redirect to
      <file>.<YYYYmmdd-HHMMSS>.bak first, then proceeds

UPGRADE SAFETY
    - Without --apply: shows diff of what would change (safe)
    - With --apply: creates .backup, then applies changes
    - Files WITHOUT markers: REFUSES to upgrade (suggests migration)
    - Project-specific sections (outside markers) are ALWAYS preserved

ADOPTION (Existing AGENTS.md without markers)
    Use --adopt when you have an existing AGENTS.md that wasn't created by
    golden-agents. This mode:

    1. Backs up your original AGENTS.md to AGENTS.md.original
    2. Generates framework content with markers
    3. Appends your original content under "## Preserved Project Content"
    4. Creates ADOPT-PROMPT.md with aggressive deduplication instructions

    The goal is MINIMAL OUTPUT. After running the deduplication prompt:
    - Simple projects: 0-20 lines of project-specific content
    - Moderate projects: 20-50 lines
    - Complex projects: 50-100 lines

    If your result exceeds 100 lines, you kept too much generic advice.

DEDUPLICATION (Existing AGENTS.md with bloated project section)
    Use --dedupe when you have an AGENTS.md that WAS created by golden-agents
    but has a bloated project-specific section (>100 lines). This mode:

    1. Verifies the file has framework markers
    2. Counts project-specific lines (after the end marker)
    3. Creates ADOPT-PROMPT.md with deduplication instructions
    4. Does NOT modify the AGENTS.md (you apply changes after review)

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

    # Adopt existing AGENTS.md (backs up, appends, generates dedup prompt)
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
# Updates local templates from origin/main with a fast-forward only merge.
# Never rebases or merges local history, and refuses when tracked files are modified.
# Requires the script directory to be a git repository.
# Arguments: none
# Returns: 0 on success; exits 1 if not a git repo, dirty, or diverged
sync_templates() {
    echo "[INFO] Syncing templates from GitHub..."

    if [[ ! -d "$SCRIPT_DIR/.git" ]]; then
        echo "[WARN] Not a git repo. Re-clone from: $REPO_URL"
        exit 1
    fi
    if [[ -n "$(git -C "$SCRIPT_DIR" status --porcelain --untracked-files=no)" ]]; then
        echo "[ERROR] $SCRIPT_DIR has uncommitted changes; refusing to sync." >&2
        echo "  Commit or stash them, then rerun --sync." >&2
        exit 1
    fi
    git -C "$SCRIPT_DIR" fetch origin main
    if ! git -C "$SCRIPT_DIR" merge --ff-only FETCH_HEAD; then
        echo "[ERROR] Local history differs from origin/main and cannot fast-forward." >&2
        echo "  Nothing was changed. Reconcile $SCRIPT_DIR by hand." >&2
        exit 1
    fi
    echo "[OK] Templates updated"
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

# list_templates <subdir>
# Lists template names (file names without .md) in templates/<subdir>.
# Arguments:
#   $1 - Subdirectory of templates/ (languages, project-types)
# Returns: Comma-separated names via stdout
list_templates() {
    local f names=""
    for f in "$TEMPLATES_DIR/$1"/*.md; do
        [[ -e "$f" ]] || continue
        f=$(basename "$f" .md)
        names="${names:+$names, }$f"
    done
    echo "$names"
}

# is_template <subdir> <name>
# Arguments:
#   $1 - Subdirectory of templates/
#   $2 - Template name to check
# Returns: 0 if templates/<subdir>/<name>.md exists and name is a plain token
is_template() {
    case "$2" in
        "" | *[!a-z0-9-]*) return 1 ;;
    esac
    [[ -f "$TEMPLATES_DIR/$1/$2.md" ]]
}

# Redirect files carrying this line were written by the generator and may be overwritten.
GENERATED_SENTINEL="<!-- golden-agents:generated -->"

# Redirect files the generator still writes. Each one is an @AGENTS.md import.
KEPT_REDIRECTS="CLAUDE.md GEMINI.md .github/copilot-instructions.md"
# No longer written. A generated copy is removed. A hand-written copy stays.
RETIRED_REDIRECTS="CODEX.md AGENT.md COPILOT.md"
# Every path whose hand-written content blocks a plain run.
REDIRECT_FILES="$KEPT_REDIRECTS $RETIRED_REDIRECTS"

# redirect_title <relpath>
# Returns: Markdown title for a redirect file via stdout
redirect_title() {
    case "$1" in
        CLAUDE.md) echo "Claude Code Instructions" ;;
        CODEX.md) echo "OpenAI Codex CLI Instructions" ;;
        AGENT.md) echo "Amp by Sourcegraph Instructions" ;;
        GEMINI.md) echo "Google Gemini Code Assist Instructions" ;;
        COPILOT.md) echo "GitHub Copilot Instructions" ;;
        .github/copilot-instructions.md) echo "GitHub Copilot Custom Instructions" ;;
    esac
}

# legacy_redirect_body <relpath> <agents_name>
# Byte-identical to the prose stubs 1.4.x wrote, without the sentinel.
# Used only to recognize those stubs. New files are imports, not this text.
# Arguments:
#   $1 - Redirect file path relative to the output path
#   $2 - Name of the AGENTS file the stub links to
# Returns: Stub body via stdout
legacy_redirect_body() {
    local rel="$1"
    local agents="$2"
    if [[ "$rel" == ".github/copilot-instructions.md" ]]; then
        cat << EOF
# $(redirect_title "$rel")

See **[../$agents](../$agents)** for all AI guidance.

## Summary

This project uses the Golden Agents Framework for AI coding assistant guidance.
All instructions are consolidated in $agents at the project root.
EOF
    else
        cat << EOF
# $(redirect_title "$rel")

See **[$agents](./$agents)** for all AI guidance.
EOF
    fi
}

# import_redirect_body <relpath>
# One-line @AGENTS.md import. Copilot's file lives in .github/, so its import
# walks up one directory. No prose.
# Arguments:
#   $1 - Redirect file path relative to the output path
# Returns: Import line via stdout
import_redirect_body() {
    if [[ "$1" == ".github/copilot-instructions.md" ]]; then
        echo '@../AGENTS.md'
    else
        echo '@AGENTS.md'
    fi
}

# is_generated_redirect <file> <relpath>
# A redirect is generated if it carries the sentinel line or is byte-identical
# to a 1.4.x stub (either AGENTS.md spelling).
# Arguments:
#   $1 - Path to an existing file
#   $2 - Redirect file path relative to the output path
# Returns: 0 if generated, 1 otherwise
is_generated_redirect() {
    local file="$1"
    local rel="$2"
    if grep -qxF "$GENERATED_SENTINEL" "$file"; then
        return 0
    fi
    if cmp -s "$file" <(legacy_redirect_body "$rel" "AGENTS.md"); then
        return 0
    fi
    if cmp -s "$file" <(legacy_redirect_body "$rel" "Agents.md"); then
        return 0
    fi
    if cmp -s "$file" <(import_redirect_body "$rel"); then
        return 0
    fi
    return 1
}

# find_blocking_redirects <path>
# Lists redirect files that exist and hold non-generated content.
# Arguments:
#   $1 - Directory path to check
# Returns: Newline-separated relative paths via stdout, or empty string
find_blocking_redirects() {
    local path="$1"
    local rel
    for rel in $REDIRECT_FILES; do
        if [[ -f "$path/$rel" ]] && ! is_generated_redirect "$path/$rel" "$rel"; then
            echo "$rel"
        fi
    done
}

# backup_file <file>
# Copies a file to <file>.<YYYYmmdd-HHMMSS>.bak, adding -1, -2 on collision.
# Arguments:
#   $1 - Path to the file to back up
# Returns: 0 on success
backup_file() {
    local src="$1"
    local stamp dest
    local n=0
    stamp=$(date +%Y%m%d-%H%M%S)
    dest="$src.$stamp.bak"
    while [[ -e "$dest" ]]; do
        n=$((n + 1))
        dest="$src.$stamp-$n.bak"
    done
    cp -p "$src" "$dest"
    echo "[OK] Backed up: $dest"
}

# create_redirect <relpath>
# Writes a sentinel-marked @AGENTS.md import.
# Arguments:
#   $1 - Redirect file path relative to OUTPUT_PATH
# Returns: 0
create_redirect() {
    local rel="$1"
    mkdir -p "$(dirname "$OUTPUT_PATH/$rel")"
    {
        import_redirect_body "$rel"
        echo "$GENERATED_SENTINEL"
    } > "$OUTPUT_PATH/$rel"
}

# sync_redirects <mode>
# mode "preview" prints the plan and writes nothing.
# mode "apply" writes kept imports when the file is missing or generated.
# mode "apply-backup" is apply, and backs up a kept file before replacing it.
# mode "apply-force" writes every kept import. Adopt and migrate use it after
# they have already backed up hand-written copies.
# A hand-written retired file is never removed.
# Arguments:
#   $1 - preview, apply, apply-backup, or apply-force
# Returns: 0
sync_redirects() {
    local mode="$1"
    local rel
    for rel in $KEPT_REDIRECTS; do
        if [[ "$mode" != "apply-force" && -f "$OUTPUT_PATH/$rel" ]] && ! is_generated_redirect "$OUTPUT_PATH/$rel" "$rel"; then
            if [[ "$mode" == "preview" ]]; then
                echo "  would leave $rel (hand-written)"
            fi
            continue
        fi
        if [[ "$mode" == "preview" ]]; then
            echo "  would write $rel (@AGENTS.md import)"
            continue
        fi
        if [[ "$mode" == "apply-backup" && -f "$OUTPUT_PATH/$rel" ]]; then
            backup_file "$OUTPUT_PATH/$rel"
        fi
        create_redirect "$rel"
    done
    for rel in $RETIRED_REDIRECTS; do
        if [[ ! -f "$OUTPUT_PATH/$rel" ]]; then
            continue
        fi
        if ! is_generated_redirect "$OUTPUT_PATH/$rel" "$rel"; then
            if [[ "$mode" == "preview" ]]; then
                echo "  would leave $rel (hand-written)"
            else
                echo "  left $rel (hand-written)"
            fi
            continue
        fi
        if [[ "$mode" == "preview" ]]; then
            echo "  would remove generated $rel"
            continue
        fi
        backup_file "$OUTPUT_PATH/$rel"
        rm -f "$OUTPUT_PATH/$rel"
        echo "  removed generated $rel"
    done
}

# gitignore_add <dir> <entry>
# Appends entry to <dir>/.gitignore on its own line, creating the file if needed.
# Skips the append when the entry already appears in the file.
# Arguments:
#   $1 - Directory containing .gitignore
#   $2 - Entry to add
# Returns: 0 if added, 1 if already present
gitignore_add() {
    local file="$1/.gitignore"
    local entry="$2"
    if [[ -f "$file" ]] && grep -qF "$entry" "$file"; then
        return 1
    fi
    if [[ -s "$file" && -n "$(tail -c 1 "$file")" ]]; then
        printf '\n' >> "$file"
    fi
    printf '%s\n' "$entry" >> "$file"
}

# check_existing_guidance <path>
# Checks for existing guidance files that would be overwritten.
# Detects non-generated CLAUDE.md, and Agents.md and AGENTS.md without markers.
# Arguments:
#   $1 - Directory path to check
# Returns: Space-separated list of found files with sizes via stdout, or empty string
check_existing_guidance() {
    local path="$1"
    local found_files=""

    if [[ -f "$path/CLAUDE.md" ]] && ! is_generated_redirect "$path/CLAUDE.md" "CLAUDE.md"; then
        local size
        size=$(wc -c < "$path/CLAUDE.md" | tr -d ' ')
        found_files="CLAUDE.md ($size bytes)"
    fi

    # Check Agents.md without markers (skip when it is the same file as AGENTS.md,
    # as on case-insensitive filesystems)
    if [[ -f "$path/Agents.md" ]] && ! [[ "$path/Agents.md" -ef "$path/AGENTS.md" ]]; then
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
    if [[ -f "$path/CLAUDE.md" ]] && ! is_generated_redirect "$path/CLAUDE.md" "CLAUDE.md"; then
        source_file="CLAUDE.md"
        existing_content=$(cat "$path/CLAUDE.md")
    fi

    # Collect from Agents.md without markers (once, if it is the same file as AGENTS.md)
    if [[ -f "$path/Agents.md" ]] && ! [[ "$path/Agents.md" -ef "$path/AGENTS.md" ]] \
        && ! grep -q "$MARKER_START" "$path/Agents.md"; then
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
2. Read the **New Framework** in `AGENTS.md` (already generated)
3. Apply the **10-word test** to each piece of content:
   - Can you express this in under 10 words with specific names/paths/commands?
   - YES → Keep it (project-specific)
   - NO → Skip it (framework already covers it)
4. Add ONLY project-specific content to `AGENTS.md` after `<!-- GOLDEN:framework:end -->`
5. **DO NOT** duplicate content already in the framework (quality gates, anti-slop, etc.)
6. **DO NOT** lose any genuinely project-specific information

## Target Sizes

| Project Complexity | Target Size |
|-------------------|-------------|
| Simple (single language, standard tooling) | **0-20 lines** |
| Moderate (multi-language, some custom workflows) | **20-50 lines** |
| Complex (many integrations, strict domain rules) | **50-100 lines** |

**If your project exceeds 100 lines** of genuinely project-specific content:
1. Create a `.ai-guidance/` directory in your repo
2. Split content into topic-specific modules (e.g., `mobile-builds.md`, `security.md`)
3. Add a loading table to AGENTS.md referencing when to load each module
PROMPT_EOF
    echo "4. Keep AGENTS.md under $MAX_GUIDANCE_LINES lines with quick reference + loading instructions"
    echo ""
    echo "## Source Files"
    echo ""
    echo "Migrated from: $source_file"
    local source_lines
    source_lines=$(echo "$existing_content" | wc -l | tr -d ' ')
    echo "Original size: $source_lines lines"
    echo ""
    # The fence must be longer than any backtick run in the content, or an
    # embedded code block closes it early
    local longest_run fence=""
    longest_run=$(printf '%s\n' "$existing_content" | awk '
        { s = $0; while (match(s, /`+/)) { if (RLENGTH > m) m = RLENGTH; s = substr(s, RSTART + RLENGTH) } }
        END { print m + 0 }')
    while [[ ${#fence} -lt 3 || ${#fence} -le $longest_run ]]; do
        fence="${fence}\`"
    done
    echo "## Existing Content"
    echo ""
    echo "${fence}markdown"
    echo "$existing_content"
    echo "$fence"
    echo ""
    echo "## Report Metrics"
    echo ""
    echo "After adding project-specific content to AGENTS.md, report:"
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
    echo "1. Open \`AGENTS.md\` and find the \`<!-- GOLDEN:framework:end -->\` marker"
    echo "2. Add your project-specific content after that marker"
    echo "3. Report the metrics above"
    echo "4. Delete this \`MIGRATION-PROMPT.md\` file"
    echo "5. Commit the changes"
}

# Parse arguments (value options accept --opt=value and --opt value)
while [[ $# -gt 0 ]]; do
    arg="$1"
    case $arg in
        --language|--type|--path|--name)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "Error: $arg requires a value" >&2
                exit 1
            fi
            arg="$arg=$2"
            shift
            ;;
    esac
    case $arg in
        --language=*) LANGUAGES="${arg#*=}" ;;
        --type=*) PROJECT_TYPE="${arg#*=}" ;;
        --path=*) OUTPUT_PATH="${arg#*=}"; PATH_GIVEN=true ;;
        --name=*) PROJECT_NAME="${arg#*=}" ;;
        --progressive) ;; # Already the default, flag accepted for clarity
        --superpowers) SUPERPOWERS=true ;;
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
    shift
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

# Validate --language and --type against templates/
if [[ -n "$LANGUAGES" ]]; then
    IFS=',' read -ra requested_langs <<< "$LANGUAGES"
    for lang in "${requested_langs[@]}"; do
        if ! is_template languages "$lang"; then
            echo "[ERROR] Unknown language: $lang" >&2
            echo "  Valid languages: $(list_templates languages)" >&2
            echo "  Aliases are listed under LANGUAGE ALIASES in --help." >&2
            exit 1
        fi
    done
fi
if [[ -n "$PROJECT_TYPE" ]] && ! is_template project-types "$PROJECT_TYPE"; then
    echo "[ERROR] Unknown project type: $PROJECT_TYPE" >&2
    echo "  Valid types: $(list_templates project-types)" >&2
    exit 1
fi

# Validate --adopt requires --language
if [[ "$ADOPT" == "true" && -z "$LANGUAGES" ]]; then
    echo "Error: --adopt requires --language" >&2
    exit 1
fi

# Validate --dedupe requires --path
if [[ "$DEDUPE" == "true" && "$PATH_GIVEN" != "true" ]]; then
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

# Redirect files with non-generated content; backed up in --adopt/--migrate, block plain runs
BLOCKING_REDIRECTS=$(find_blocking_redirects "$OUTPUT_PATH")

# Check for existing guidance files (unless --migrate or --upgrade or --adopt or --dedupe or --dry-run is used)
# A blocked plain run writes nothing at all.
if [[ "$MIGRATE" != "true" && "$UPGRADE" != "true" && "$ADOPT" != "true" && "$DEDUPE" != "true" && "$DRY_RUN" != "true" ]]; then
    blocking=""
    for name in AGENTS.md Agents.md; do
        if [[ "$name" == "Agents.md" && "$OUTPUT_PATH/Agents.md" -ef "$OUTPUT_PATH/AGENTS.md" ]]; then
            continue
        fi
        if [[ -f "$OUTPUT_PATH/$name" ]]; then
            if grep -q "$MARKER_START" "$OUTPUT_PATH/$name"; then
                blocking="${blocking}  $name (existing file with markers; use --upgrade)
"
            else
                blocking="${blocking}  $name (existing file without markers; use --adopt or --migrate)
"
            fi
        fi
    done
    for rel in $BLOCKING_REDIRECTS; do
        blocking="${blocking}  $rel (non-generated content)
"
    done
    if [[ -n "$blocking" ]]; then
        echo "[ERROR] Found existing guidance files. No files were written." >&2
        echo "" >&2
        printf '%s' "$blocking" >&2
        echo "" >&2
        echo "  These files contain project-specific content that would be lost." >&2
        echo "  Use --migrate to safely incorporate this content into the new AGENTS.md." >&2
        echo "  Use --adopt to bring an existing AGENTS.md into the framework." >&2
        echo "" >&2
        echo "  Example: generate-agents.sh --migrate --language=go --path=$OUTPUT_PATH" >&2
        echo "  Example: generate-agents.sh --adopt --language=go --path=$OUTPUT_PATH" >&2
        exit 1
    fi
fi

# Handle migrate mode - generate migration prompt if needed
if [[ "$MIGRATE" == "true" ]]; then
    # Check if there's content to migrate
    existing=$(check_existing_guidance "$OUTPUT_PATH")
    if [[ -n "$existing" ]]; then
        # Extract filename and count lines
        source_file=$(echo "$existing" | cut -d' ' -f1)
        source_lines=$(wc -l < "$OUTPUT_PATH/$source_file" | tr -d ' ')

        echo "[INFO] Found existing guidance: $existing"
        echo "[INFO] Source file: $source_file ($source_lines lines)"

        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[DRY RUN] Would generate migration prompt: $OUTPUT_PATH/MIGRATION-PROMPT.md"
            echo "[DRY RUN] Would add MIGRATION-PROMPT.md to $OUTPUT_PATH/.gitignore"
        else
            mkdir -p "$OUTPUT_PATH"
            echo "[INFO] Generating migration prompt..."

            # Generate the migration prompt
            generate_migration_prompt "$OUTPUT_PATH" > "$OUTPUT_PATH/MIGRATION-PROMPT.md"
            echo "[OK] Created: $OUTPUT_PATH/MIGRATION-PROMPT.md"
            echo "[INFO] Target: reduce to 0-100 lines of project-specific content"

            # Add to .gitignore
            gitignore_add "$OUTPUT_PATH" "MIGRATION-PROMPT.md" || true
            echo "[OK] Added MIGRATION-PROMPT.md to .gitignore"
        fi
    else
        echo "[INFO] No existing guidance files found. Running normal generation."
    fi

    # Normal generation below replaces AGENTS.md, so back up any existing one
    # (with or without markers). Both names may be one file on case-insensitive volumes.
    for name in AGENTS.md Agents.md; do
        if [[ ! -f "$OUTPUT_PATH/$name" ]]; then
            continue
        fi
        if [[ "$name" == "Agents.md" && "$OUTPUT_PATH/Agents.md" -ef "$OUTPUT_PATH/AGENTS.md" ]]; then
            continue
        fi
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[DRY RUN] Would back up $name to $name.<timestamp>.bak"
        else
            backup_file "$OUTPUT_PATH/$name"
        fi
    done

    # Continue with normal generation (framework AGENTS.md)
    # Fall through to normal generation below
fi

# Handle adopt mode - bring existing AGENTS.md into framework
if [[ "$ADOPT" == "true" ]]; then
    # Check for existing AGENTS.md (preferred) or Agents.md (legacy) without markers
    existing_agents_file=""
    if [[ -f "$OUTPUT_PATH/AGENTS.md" ]]; then
        existing_agents_file="$OUTPUT_PATH/AGENTS.md"
    elif [[ -f "$OUTPUT_PATH/Agents.md" ]]; then
        existing_agents_file="$OUTPUT_PATH/Agents.md"
    fi

    if [[ -z "$existing_agents_file" ]]; then
        echo "[ERROR] No AGENTS.md found at $OUTPUT_PATH" >&2
        echo "  --adopt requires an existing AGENTS.md file to adopt." >&2
        exit 1
    fi

    if grep -q "$MARKER_START" "$existing_agents_file"; then
        echo "[ERROR] $(basename "$existing_agents_file") already has framework markers" >&2
        echo "  Use --upgrade instead to update framework sections." >&2
        exit 1
    fi

    echo "[INFO] Adopting existing $(basename "$existing_agents_file") into golden-agents framework..."

    # Store original content (read-only; safe to do even in dry-run)
    original_content=$(cat "$existing_agents_file")
    original_lines=$(wc -l < "$existing_agents_file" | tr -d ' ')

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would back up original: $OUTPUT_PATH/AGENTS.md.original"
        if [[ "$existing_agents_file" == "$OUTPUT_PATH/Agents.md" ]]; then
            echo "[DRY RUN] Would remove legacy file: $existing_agents_file"
        fi
        echo "[DRY RUN] Would create: $OUTPUT_PATH/ADOPT-PROMPT.md"
        echo "[DRY RUN] Would add ADOPT-PROMPT.md and AGENTS.md.original to .gitignore"
    else
        mkdir -p "$OUTPUT_PATH"

        # Backup original
        cp "$existing_agents_file" "$OUTPUT_PATH/AGENTS.md.original"
        echo "[OK] Backed up original: $OUTPUT_PATH/AGENTS.md.original"

        # Remove old file if it was lowercase (will be replaced with AGENTS.md)
        if [[ "$existing_agents_file" == "$OUTPUT_PATH/Agents.md" ]]; then
            rm "$existing_agents_file"
        fi

        # Copy ADOPT-PROMPT.md template
        if [[ -f "$TEMPLATES_DIR/adopt-prompt.md" ]]; then
            cp "$TEMPLATES_DIR/adopt-prompt.md" "$OUTPUT_PATH/ADOPT-PROMPT.md"
            echo "[OK] Created: $OUTPUT_PATH/ADOPT-PROMPT.md"
        else
            echo "[WARN] Template not found: $TEMPLATES_DIR/adopt-prompt.md" >&2
        fi

        # Add to .gitignore
        gitignore_add "$OUTPUT_PATH" "ADOPT-PROMPT.md" || true
        gitignore_add "$OUTPUT_PATH" "AGENTS.md.original" || true
        echo "[OK] Added ADOPT-PROMPT.md and AGENTS.md.original to .gitignore"
    fi

    # Generate framework content, then append original
    # We'll set a flag to append after generation
    ADOPT_ORIGINAL_CONTENT="$original_content"
    ADOPT_ORIGINAL_LINES="$original_lines"

    # Fall through to normal generation, which will append the original content
fi

# Handle dedupe mode - generate deduplication prompt for files WITH markers
if [[ "$DEDUPE" == "true" ]]; then
    # Check for existing AGENTS.md (preferred) or Agents.md (legacy) WITH markers
    existing_agents_file=""
    if [[ -f "$OUTPUT_PATH/AGENTS.md" ]]; then
        existing_agents_file="$OUTPUT_PATH/AGENTS.md"
    elif [[ -f "$OUTPUT_PATH/Agents.md" ]]; then
        existing_agents_file="$OUTPUT_PATH/Agents.md"
    fi

    if [[ -z "$existing_agents_file" ]]; then
        echo "[ERROR] No AGENTS.md found at $OUTPUT_PATH" >&2
        echo "  --dedupe requires an existing AGENTS.md file with framework markers." >&2
        exit 1
    fi

    if ! grep -q "$MARKER_START" "$existing_agents_file"; then
        echo "[ERROR] $(basename "$existing_agents_file") does not have framework markers" >&2
        echo "  Use --adopt instead for files created without golden-agents." >&2
        exit 1
    fi

    if ! grep -qF "$MARKER_END" "$existing_agents_file"; then
        echo "[ERROR] $(basename "$existing_agents_file") has $MARKER_START but no $MARKER_END" >&2
        echo "  Restore the end marker after the framework section, then rerun --dedupe." >&2
        echo "  No files were changed." >&2
        exit 1
    fi

    # Count lines in project-specific section (after MARKER_END)
    marker_end_line=$(grep -n "$MARKER_END" "$existing_agents_file" | head -1 | cut -d: -f1)
    total_lines=$(wc -l < "$existing_agents_file" | tr -d ' ')
    project_lines=$((total_lines - marker_end_line))

    echo "[INFO] Analyzing $(basename "$existing_agents_file") for deduplication..."
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

    # ADOPT-PROMPT.md template is required regardless of dry-run (read-only check)
    if [[ ! -f "$TEMPLATES_DIR/adopt-prompt.md" ]]; then
        echo "[ERROR] Template not found: $TEMPLATES_DIR/adopt-prompt.md" >&2
        exit 1
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would create: $OUTPUT_PATH/ADOPT-PROMPT.md"
        echo "[DRY RUN] Would add ADOPT-PROMPT.md to .gitignore"
    else
        # Copy ADOPT-PROMPT.md template (same prompt works for dedupe)
        cp "$TEMPLATES_DIR/adopt-prompt.md" "$OUTPUT_PATH/ADOPT-PROMPT.md"
        echo "[OK] Created: $OUTPUT_PATH/ADOPT-PROMPT.md"

        # Add to .gitignore if not already there
        if [[ -f "$OUTPUT_PATH/.gitignore" ]]; then
            if gitignore_add "$OUTPUT_PATH" "ADOPT-PROMPT.md"; then
                echo "[OK] Added ADOPT-PROMPT.md to .gitignore"
            fi
        else
            gitignore_add "$OUTPUT_PATH" "ADOPT-PROMPT.md"
            echo "[OK] Created .gitignore with ADOPT-PROMPT.md"
        fi
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "                    NEXT STEPS"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "  1. Open ADOPT-PROMPT.md in your AI assistant"
    echo "  2. Paste the contents of AGENTS.md after the prompt"
    echo "  3. The AI will propose aggressive deduplication"
    echo "  4. Review and approve the proposed changes"
    echo "  5. Apply the minimal result to AGENTS.md"
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

# ensure_detected_gates
# Reads the project once for exact lint, test, build, and coverage commands.
# Order: package.json scripts, Makefile, justfile, pyproject.toml
# [project.scripts], then GitHub Actions step names. The first match wins.
# A missing python3 leaves every gate on the template fallback.
# Reads from global: OUTPUT_PATH
# Arguments: none
# Returns: 0. Sets DET_LINT, DET_BUILD, DET_TEST, DET_COV and *_SRC.
ensure_detected_gates() {
    if [[ "${GATES_DETECTED:-}" == "1" ]]; then
        return 0
    fi
    GATES_DETECTED=1
    DET_LINT="" DET_BUILD="" DET_TEST="" DET_COV=""
    DET_LINT_SRC="" DET_BUILD_SRC="" DET_TEST_SRC="" DET_COV_SRC=""
    if ! command -v python3 >/dev/null 2>&1; then
        return 0
    fi
    local line name cmd src
    while IFS=$'\t' read -r name cmd src; do
        [[ -n "$name" && -n "$cmd" && -n "$src" ]] || continue
        case "$name" in
            lint) [[ -z "$DET_LINT" ]] && { DET_LINT="$cmd"; DET_LINT_SRC="$src"; } ;;
            build) [[ -z "$DET_BUILD" ]] && { DET_BUILD="$cmd"; DET_BUILD_SRC="$src"; } ;;
            test) [[ -z "$DET_TEST" ]] && { DET_TEST="$cmd"; DET_TEST_SRC="$src"; } ;;
            coverage) [[ -z "$DET_COV" ]] && { DET_COV="$cmd"; DET_COV_SRC="$src"; } ;;
        esac
    done < <(ROOT="$OUTPUT_PATH" python3 - << 'PY'
import json, os, pathlib, re, sys
root = pathlib.Path(os.environ.get("ROOT", "."))
names = ("lint", "test", "build", "coverage")
found = {}

def add(name, cmd, src):
    if name in names and name not in found and cmd.strip():
        found[name] = (cmd.strip(), src)

pkg = root / "package.json"
if pkg.is_file():
    try:
        data = json.loads(pkg.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        data = {}
    scripts = data.get("scripts") if isinstance(data, dict) else None
    if isinstance(scripts, dict):
        for name in names:
            if isinstance(scripts.get(name), str) and scripts[name].strip():
                add(name, "npm run " + name, "package.json")

def make_targets(path, runner):
    if not path.is_file():
        return
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        match = re.match(r"^(lint|test|build|coverage):([^:]|$)", raw)
        if match:
            add(match.group(1), runner + " " + match.group(1), path.name)

for makefile in ("Makefile", "makefile", "GNUmakefile"):
    make_targets(root / makefile, "make")
for just in ("justfile", "Justfile", ".justfile"):
    make_targets(root / just, "just")

pyproject = root / "pyproject.toml"
if pyproject.is_file():
    section = None
    entry = re.compile(r"^[\w.]+:[\w.]+$")
    for raw in pyproject.read_text(encoding="utf-8", errors="replace").splitlines():
        header = re.match(r"^\[([^]]+)\]\s*$", raw)
        if header:
            section = header.group(1)
            continue
        if section != "project.scripts":
            continue
        item = re.match(r'^(lint|test|build|coverage)\s*=\s*"(.*)"\s*$', raw)
        if item and not entry.match(item.group(2)):
            add(item.group(1), item.group(2), "pyproject.toml")

workflows = root / ".github" / "workflows"
if workflows.is_dir():
    for path in sorted(workflows.glob("*.yml")) + sorted(workflows.glob("*.yaml")):
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        rel = ".github/workflows/" + path.name
        for index, raw in enumerate(lines):
            step = re.match(r"\s*-\s*name:\s*['\"]?(lint|test|build|coverage)['\"]?\s*$", raw)
            if not step:
                continue
            for nxt in lines[index + 1:index + 8]:
                if re.match(r"\s*-\s*name:", nxt):
                    break
                run = re.match(r"\s*run:\s*['\"]?(.+?)['\"]?\s*$", nxt)
                if run and not run.group(1).startswith("|"):
                    add(step.group(1), run.group(1), rel)
                    break

for name in names:
    if name in found:
        cmd, src = found[name]
        sys.stdout.write(name + "\t" + cmd + "\t" + src + "\n")
PY
    )
}

# gate_line <label> <command> <source> <fallback>
# Prints one gate. A detected command cites its file. Otherwise the template
# command is marked unverified.
# Arguments:
#   $1 - Label, including any indent and number
#   $2 - Detected command, or empty
#   $3 - Source file for the detected command
#   $4 - Template command
# Returns: The line via stdout
gate_line() {
    local label="$1" cmd="$2" src="$3" fallback="$4"
    if [[ -n "$cmd" ]]; then
        echo "${label}: \`${cmd}\` (${src})"
    else
        echo "${label}: \`UNVERIFIED: confirm ${fallback}\`"
    fi
}

# emit_lang_gates <language> [indent]
# Prints the numbered lint/build/test/coverage gate list for one language.
# Detected project commands replace the template. Coverage stays a percentage
# unless the project has a coverage command.
# Arguments:
#   $1 - Canonical language name
#   $2 - (optional) Prefix for each line, for nesting under a label
# Returns: Gate list via stdout
emit_lang_gates() {
    local indent="${2:-}"
    local line lint_cmd="" build_cmd="" test_cmd="" coverage=""
    ensure_detected_gates
    while IFS= read -r line; do
        case "$line" in
            LINT:*) lint_cmd="${line#LINT:}" ;;
            BUILD:*) build_cmd="${line#BUILD:}" ;;
            TEST:*) test_cmd="${line#TEST:}" ;;
            COV:*) coverage="${line#COV:}" ;;
        esac
    done < <(get_lang_commands "$1")
    gate_line "${indent}1. **Lint**" "$DET_LINT" "$DET_LINT_SRC" "$lint_cmd"
    gate_line "${indent}2. **Build**" "$DET_BUILD" "$DET_BUILD_SRC" "$build_cmd"
    gate_line "${indent}3. **Test**" "$DET_TEST" "$DET_TEST_SRC" "$test_cmd"
    if [[ -n "$DET_COV" ]]; then
        gate_line "${indent}4. **Coverage**" "$DET_COV" "$DET_COV_SRC" ""
    elif [[ "$coverage" != "N/A" ]]; then
        echo "${indent}4. **Coverage**: Minimum ${coverage}%"
    fi
}

# file_sha256 <file>
# Prints the sha256 hex digest of a file.
# Arguments:
#   $1 - Path to a file
# Returns: Digest via stdout
file_sha256() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{ print $1 }'
    else
        shasum -a 256 "$1" | awk '{ print $1 }'
    fi
}

# each_selected_module
# Lists the modules progressive mode copies into the consumer repo.
# Languages come from --language. The project type comes from --type.
# The five workflow modules are the ones the trigger block names.
# Reads from global: LANGUAGES, PROJECT_TYPE, TEMPLATES_DIR
# Arguments: none
# Returns: Lines of "<name> <template-path-relative-to-templates>" via stdout
each_selected_module() {
    local lang wf
    local IFS=','
    for lang in $LANGUAGES; do
        if [[ -f "$TEMPLATES_DIR/languages/${lang}.md" ]]; then
            echo "${lang} languages/${lang}.md"
        fi
    done
    for wf in security testing build-hygiene deployment; do
        echo "${wf} workflows/${wf}.md"
    done
    if [[ -n "$PROJECT_TYPE" && -f "$TEMPLATES_DIR/project-types/${PROJECT_TYPE}.md" ]]; then
        echo "${PROJECT_TYPE} project-types/${PROJECT_TYPE}.md"
    fi
}

# modules_record
# One comment recording the sha256 of every selected module.
# Arguments: none
# Returns: The comment via stdout
modules_record() {
    local name rel hash line=""
    while read -r name rel; do
        hash=$(file_sha256 "$TEMPLATES_DIR/$rel")
        line="${line:+$line }${name}=${hash}"
    done < <(each_selected_module)
    echo "<!-- golden-agents:modules ${line} -->"
}

# preview_modules
# Prints what --upgrade or --dry-run would do to .golden-agents/modules.
# Writes nothing.
# Arguments: none
# Returns: 0
preview_modules() {
    local name rel dest have hash
    while read -r name rel; do
        dest="$OUTPUT_PATH/.golden-agents/modules/${name}.md"
        hash=$(file_sha256 "$TEMPLATES_DIR/$rel")
        if [[ ! -f "$dest" ]]; then
            echo "  would write .golden-agents/modules/${name}.md"
        else
            have=$(file_sha256 "$dest")
            if [[ "$have" == "$hash" ]]; then
                echo "  unchanged .golden-agents/modules/${name}.md"
            else
                echo "  would update .golden-agents/modules/${name}.md"
                echo "    have     $have"
                echo "    template $hash"
            fi
        fi
    done < <(each_selected_module)
}

# write_selected_modules
# Copies selected templates into OUTPUT_PATH/.golden-agents/modules/.
# Arguments: none
# Returns: 0
write_selected_modules() {
    local name rel dest
    mkdir -p "$OUTPUT_PATH/.golden-agents/modules"
    while read -r name rel; do
        dest="$OUTPUT_PATH/.golden-agents/modules/${name}.md"
        cp "$TEMPLATES_DIR/$rel" "$dest"
        echo "  wrote .golden-agents/modules/${name}.md"
    done < <(each_selected_module)
}

# apply_modules_comment <file>
# Inserts or replaces the modules comment. A stamp line keeps it on the next
# line. A file with no stamp gets it immediately before the framework marker.
# Arguments:
#   $1 - AGENTS.md path
# Returns: 0
apply_modules_comment() {
    local file="$1"
    local desired tmp
    desired=$(modules_record)
    tmp=$(mktemp)
    MARK="$MARKER_START" DESIRED="$desired" awk '
        index($0, "<!-- golden-agents:modules ") == 1 { next }
        !inserted && index($0, "<!-- golden-agents:stamp ") == 1 {
            print
            print ENVIRON["DESIRED"]
            inserted = 1
            next
        }
        !inserted && index($0, ENVIRON["MARK"]) {
            print ENVIRON["DESIRED"]
            inserted = 1
        }
        { print }
    ' "$file" > "$tmp"
    mv "$tmp" "$file"
}

# rule_glob <language>
# Path glob for a language module. Empty for an unknown language.
rule_glob() {
    case "$1" in
        go) echo '**/*.go' ;;
        python) echo '**/*.py' ;;
        javascript) echo '**/*.{js,ts,jsx,tsx}' ;;
        shell) echo '**/*.sh' ;;
        dart-flutter) echo '**/*.dart' ;;
        *) echo '' ;;
    esac
}

# rule_owned <file>
# A rule file is ours when it is missing or carries the generated sentinel.
# A hand-written file is left alone.
rule_owned() {
    local file="$1"
    [[ ! -e "$file" ]] && return 0
    grep -qxF "$GENERATED_SENTINEL" "$file"
}

# render_rule <dest> <frontmatter> <body>
# Frontmatter may be empty. The sentinel is the last line.
render_rule() {
    local dest="$1" front="$2" body="$3"
    mkdir -p "$(dirname "$dest")"
    {
        if [[ -n "$front" ]]; then
            printf '%s\n' "$front"
            echo
        fi
        cat "$body"
        echo
        echo "$GENERATED_SENTINEL"
    } > "$dest"
}

# each_scoped_rule
# Lines of "<name> <body-path> <mode> <glob>".
# mode is "always" or "scoped". Invariants and security always load.
# A language rule is scoped to that language's files.
# A project type applies to the whole project.
each_scoped_rule() {
    local lang glob rel
    echo "invariants $TEMPLATES_DIR/core/invariants.md always"
    echo "security $TEMPLATES_DIR/workflows/security.md always"
    local IFS=','
    for lang in $LANGUAGES; do
        rel="$TEMPLATES_DIR/languages/${lang}.md"
        glob=$(rule_glob "$lang")
        if [[ -f "$rel" && -n "$glob" ]]; then
            echo "${lang} ${rel} scoped ${glob}"
        fi
    done
    if [[ -n "$PROJECT_TYPE" && -f "$TEMPLATES_DIR/project-types/${PROJECT_TYPE}.md" ]]; then
        echo "${PROJECT_TYPE} $TEMPLATES_DIR/project-types/${PROJECT_TYPE}.md always"
    fi
}

# rule_frontmatter <tool> <mode> <glob> <name>
# tool is claude, cursor, or copilot.
rule_frontmatter() {
    local tool="$1" mode="$2" glob="$3" name="$4"
    case "$tool" in
        claude)
            if [[ "$mode" == "scoped" ]]; then
                printf '%s\n' "---" "paths:" "  - \"${glob}\"" "---"
            fi
            ;;
        cursor)
            if [[ "$mode" == "scoped" ]]; then
                printf '%s\n' "---" "description: ${name} rules" "globs: \"${glob}\"" "alwaysApply: false" "---"
            else
                printf '%s\n' "---" "description: ${name} rules" "alwaysApply: true" "---"
            fi
            ;;
        copilot)
            if [[ "$mode" == "scoped" ]]; then
                printf '%s\n' "---" "applyTo: \"${glob}\"" "---"
            else
                printf '%s\n' "---" "applyTo: \"**\"" "---"
            fi
            ;;
    esac
}

# rule_dest <tool> <name>
rule_dest() {
    case "$1" in
        claude) echo "$OUTPUT_PATH/.claude/rules/${2}.md" ;;
        cursor) echo "$OUTPUT_PATH/.cursor/rules/${2}.mdc" ;;
        copilot) echo "$OUTPUT_PATH/.github/instructions/${2}.instructions.md" ;;
    esac
}

# sync_scoped_rules <preview|apply>
# Writes Claude, Cursor, and Copilot rule files for the selected modules.
# A file without the generated sentinel is left in place.
sync_scoped_rules() {
    local mode="$1"
    local name body rule_mode glob tool dest front tmp
    while read -r name body rule_mode glob; do
        [[ -n "$name" ]] || continue
        for tool in claude cursor copilot; do
            dest=$(rule_dest "$tool" "$name")
            if [[ -e "$dest" ]] && ! rule_owned "$dest"; then
                if [[ "$mode" == "preview" ]]; then
                    echo "  would leave ${dest#"$OUTPUT_PATH"/} (hand-written)"
                else
                    echo "  left ${dest#"$OUTPUT_PATH"/} (hand-written)"
                fi
                continue
            fi
            front=$(rule_frontmatter "$tool" "$rule_mode" "$glob" "$name")
            if [[ "$mode" == "preview" ]]; then
                tmp=$(mktemp)
                render_rule "$tmp" "$front" "$body"
                if [[ -f "$dest" ]] && cmp -s "$tmp" "$dest"; then
                    echo "  unchanged ${dest#"$OUTPUT_PATH"/}"
                elif [[ -f "$dest" ]]; then
                    echo "  would update ${dest#"$OUTPUT_PATH"/}"
                else
                    echo "  would write ${dest#"$OUTPUT_PATH"/}"
                fi
                rm -f "$tmp"
            else
                render_rule "$dest" "$front" "$body"
                echo "  wrote ${dest#"$OUTPUT_PATH"/}"
            fi
        done
    done < <(each_scoped_rule)
}

# superpowers_block
# The opt-in bootstrap. It is written after the framework end marker so a
# later upgrade does not restore it.
# Arguments: none
# Returns: The block via stdout
superpowers_block() {
    cat << 'EOF'

### Optional: Superpowers integration

Two parallel, mutually exclusive skill ecosystems exist. At the **START of every conversation**, detect which THIS machine uses and bootstrap accordingly:

- **superpowers-acme**: No bootstrap required (skills are pre-deployed as symlinks).
- **superpowers-plus**: Run the js bootstrap:
  ```bash
  node ~/.codex/superpowers-augment/superpowers-augment.js bootstrap
  ```

This loads available skills into the environment. To load a specific skill manually (plus only):
```bash
node ~/.codex/superpowers-augment/superpowers-augment.js use-skill <name>
```
EOF
}

# place_superpowers_block <file>
# Inserts the bootstrap immediately after the framework end marker when the
# text below that marker does not already contain the bootstrap command.
# Arguments:
#   $1 - AGENTS.md path
# Returns: 0
place_superpowers_block() {
    local file="$1"
    if awk -v mark="$MARKER_END" '
        index($0, mark) { seen = 1; next }
        seen && index($0, "superpowers-augment.js bootstrap") { found = 1 }
        END { exit !found }
    ' "$file"; then
        return 0
    fi
    local tmp block
    tmp=$(mktemp)
    block=$(mktemp)
    superpowers_block > "$block"
    MARK="$MARKER_END" BLOCK="$block" awk '
        { print }
        !done && index($0, ENVIRON["MARK"]) {
            while ((getline line < ENVIRON["BLOCK"]) > 0) print line
            done = 1
        }
    ' "$file" > "$tmp"
    mv "$tmp" "$file"
    rm -f "$block"
}

# generate_progressive()
# Generates a progressive-loading AGENTS.md (~60-80 lines).
# Multi-language projects get gates per language unless that pushes the file past
# MAX_PROGRESSIVE_LINES; then only the first language's gates are shown and the
# rest are named.
# Arguments: none (uses globals)
# Returns: Complete AGENTS.md content via stdout
generate_progressive() {
    local tmp_dir lines
    tmp_dir=$(mktemp -d)
    generate_progressive_body "per-language" > "$tmp_dir/agents.md"
    lines=$(wc -l < "$tmp_dir/agents.md" | tr -d ' ')
    if [[ "$lines" -gt "$MAX_PROGRESSIVE_LINES" ]]; then
        generate_progressive_body "first"
    else
        cat "$tmp_dir/agents.md"
    fi
    rm -rf "$tmp_dir"
}

# generate_progressive_body <gate_style>
# Uses on-demand module loading from .golden-agents/modules/ in the consumer repo.
# Reads from global: LANGUAGES, PROJECT_TYPE, PROJECT_NAME, FRAMEWORK_VERSION
# Arguments:
#   $1 - "per-language" or "first" (multi-language gate layout)
# Returns: Complete AGENTS.md content via stdout
generate_progressive_body() {
    local gate_style="$1"
    local today modules_line
    today=$(date +%Y-%m-%d)
    modules_line=$(modules_record)

    IFS=',' read -ra lang_array <<< "$LANGUAGES"

    cat << HEADER
# AI Agent Guidelines - $PROJECT_NAME

> **Generated by**: [golden-agents](https://github.com/bordenet/golden-agents) v${FRAMEWORK_VERSION} (progressive)
<!-- golden-agents:stamp version=${FRAMEWORK_VERSION} updated=${today} -->
${modules_line}
> **Languages**: $LANGUAGES
> **Type**: ${PROJECT_TYPE:-general}

Minimal core with on-demand module loading. Modules: \`.golden-agents/modules/\`

HEADER

    # Output self-manage bootstrap block
    generate_self_manage_block

    cat << FRAMEWORK_START

$MARKER_START

---

## Quality Gates

FRAMEWORK_START

    if [[ ${#lang_array[@]} -eq 1 ]]; then
        echo "Before a commit:"
        emit_lang_gates "${lang_array[0]}"
    elif [[ "$gate_style" == "first" ]]; then
        local others="${LANGUAGES#*,}"
        echo "Before a commit (gates shown for ${lang_array[0]}; add equivalents for ${others//,/, }):"
        emit_lang_gates "${lang_array[0]}"
    else
        echo "Before a commit, run the gates for each language you changed:"
        for lang in "${lang_array[@]}"; do
            echo "- **$lang**"
            emit_lang_gates "$lang" "  "
        done
    fi

    cat << FRAMEWORK_REST

Lint, then build, then test. Run the same commands in CI or a hook.

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
FRAMEWORK_REST

    # Generate language loading instructions with specific triggers
    for lang in "${lang_array[@]}"; do
        case "$lang" in
            go) echo "- 🔴 **BEFORE writing ANY \`.go\` file**: Read \`.golden-agents/modules/go.md\`" ;;
            python) echo "- 🔴 **BEFORE writing ANY \`.py\` file**: Read \`.golden-agents/modules/python.md\`" ;;
            javascript) echo "- 🔴 **BEFORE writing ANY \`.js\`, \`.ts\`, \`.jsx\`, \`.tsx\` file**: Read \`.golden-agents/modules/javascript.md\`" ;;
            shell) echo "- 🔴 **BEFORE writing ANY \`.sh\` file or bash code block**: Read \`.golden-agents/modules/shell.md\`" ;;
            dart-flutter) echo "- 🔴 **BEFORE writing ANY \`.dart\` file**: Read \`.golden-agents/modules/dart-flutter.md\`" ;;
            *) echo "- 🔴 **BEFORE writing $lang code**: Read \`.golden-agents/modules/${lang}.md\`" ;;
        esac
    done

    cat << MIDDLE

### Workflow Modules (🔴 Required)
- 🔴 **BEFORE any commit, PR, push, or merge**: Read \`.golden-agents/modules/security.md\`
- 🔴 **WHEN tests fail OR after 2+ failed fix attempts**: Read \`.golden-agents/modules/testing.md\`
- 🔴 **WHEN build fails OR lint errors appear**: Read \`.golden-agents/modules/build-hygiene.md\`
- 🟡 **BEFORE deploying to any environment**: Read \`.golden-agents/modules/deployment.md\`

MIDDLE

    if [[ -n "$PROJECT_TYPE" ]]; then
        echo "### Project type guidance:"
        echo "- Read \`.golden-agents/modules/${PROJECT_TYPE}.md\`"
        echo ""
    fi

    cat << FOOTER
$MARKER_END
FOOTER
    if [[ "$SUPERPOWERS" == "true" ]]; then
        superpowers_block
    fi
    cat << 'PROJECT'

---

## Project-Specific Rules

<!-- Add project-specific guidance below this line -->

PROJECT
}

# generate_full()
# Generates a full self-contained AGENTS.md (~800 lines).
# DEPRECATED: This mode generates files too large for AI assistants to follow.
# Includes all templates inline rather than using on-demand loading.
# Reads from global: LANGUAGES, PROJECT_TYPE, PROJECT_NAME, FRAMEWORK_VERSION
# Arguments: none (uses globals)
# Returns: Complete AGENTS.md content via stdout
generate_full() {
    local today
    today=$(date +%Y-%m-%d)

    cat << HEADER
# AI Agent Guidelines - $PROJECT_NAME

> **Generated by**: [golden-agents](https://github.com/bordenet/golden-agents) v${FRAMEWORK_VERSION}
<!-- golden-agents:stamp version=${FRAMEWORK_VERSION} updated=${today} -->
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

# estimate_tokens <file>
# Prints a token estimate: file bytes divided by 4, rounded up.
# This is not a model tokenizer. The line count is the reproducible check.
# Arguments:
#   $1 - File path
# Returns: The estimate on stdout
estimate_tokens() {
    local bytes
    bytes=$(wc -c < "$1" | tr -d ' ')
    echo $(( (bytes + 3) / 4 ))
}

# report_size <file> [indent]
# Prints the line count and the token estimate.
# Arguments:
#   $1 - File path
#   $2 - Optional prefix for each line
# Returns: 0
report_size() {
    local file="$1"
    local indent="${2:-}"
    local lines tokens
    lines=$(wc -l < "$file" | tr -d ' ')
    tokens=$(estimate_tokens "$file")
    echo "${indent}Lines: $lines"
    echo "${indent}Tokens (estimate): $tokens"
}

# generate_self_manage_block()
# Generates the self-management bootstrap block.
# This block is injected BEFORE the framework start marker.
# Arguments: none
# Returns: Bootstrap block content via stdout
generate_self_manage_block() {
    cat << 'SELF_MANAGE'
<!-- GOLDEN:self-manage:start -->
## ⚠️ Before ANY Task
1. Load `.ai-guidance/invariants.md` — contains critical rules
2. After editing ANY guidance file, check: `wc -l AGENTS.md .ai-guidance/*.md 2>/dev/null`
SELF_MANAGE
    printf "   - \`AGENTS.md\` >%s lines → refactor into \`.ai-guidance/\`\n" "$MAX_GUIDANCE_LINES"
    printf "   - Any \`.ai-guidance/*.md\` >%s lines → split into sub-directory\n" "$MAX_GUIDANCE_LINES"
    cat << 'SELF_MANAGE'
3. Over the limit, draft a diff. Do not apply it. A human merges it.
<!-- GOLDEN:self-manage:end -->

SELF_MANAGE
}

# sed_regex_escape <string>
# Escapes BRE metacharacters and "/" so the string matches literally in a sed address.
# Arguments:
#   $1 - Literal string
# Returns: Escaped string via stdout
sed_regex_escape() {
    printf '%s' "$1" | sed 's/[][\\/.^$*]/\\&/g'
}

# upgrade_agents_md()
# Safely upgrades an existing AGENTS.md file with framework markers.
# Preserves all content outside the framework markers (project-specific sections).
# Creates a backup before applying changes when --apply is used.
# Reads from global: OUTPUT_PATH, LANGUAGES, PROJECT_TYPE, FULL, APPLY
# Arguments: none (uses globals)
# Returns: 0 on success, 1 on error
# Side effects: May modify AGENTS.md and create .backup file
upgrade_agents_md() {
    # Check for existing AGENTS.md (preferred) or Agents.md (legacy)
    local existing_file=""
    if [[ -f "$OUTPUT_PATH/AGENTS.md" ]]; then
        existing_file="$OUTPUT_PATH/AGENTS.md"
    elif [[ -f "$OUTPUT_PATH/Agents.md" ]]; then
        existing_file="$OUTPUT_PATH/Agents.md"
    fi

    # Check if file exists
    if [[ -z "$existing_file" ]]; then
        echo "[ERROR] No AGENTS.md found at: $OUTPUT_PATH" >&2
        echo "  Use --language=... to generate a new file instead." >&2
        exit 1
    fi

    # Check for markers
    if ! grep -q "$MARKER_START" "$existing_file" || ! grep -q "$MARKER_END" "$existing_file"; then
        echo "[ERROR] Cannot upgrade: $(basename "$existing_file") lacks framework markers" >&2
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

    # Extract config from the generated header lines ("> **Languages**: ..." / "> **Type**: ...")
    local existing_langs existing_type
    existing_langs=$(awk 'sub(/^> \*\*Languages\*\*: /, "") { print; exit }' "$existing_file")
    existing_type=$(awk 'sub(/^> \*\*Type\*\*: /, "") { print; exit }' "$existing_file")
    if [[ -z "$existing_type" ]]; then
        existing_type="general"
    fi

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

    # Assemble the upgraded file by streaming. Command substitution would strip
    # trailing newlines, so user bytes outside the markers never pass through a variable.
    local start_line end_line start_re end_re tmp_dir
    start_line=$(MARK="$MARKER_START" awk 'index($0, ENVIRON["MARK"]) { print NR; exit }' "$existing_file")
    end_line=$(MARK="$MARKER_END" awk 'index($0, ENVIRON["MARK"]) { print NR; exit }' "$existing_file")
    start_re=$(sed_regex_escape "$MARKER_START")
    end_re=$(sed_regex_escape "$MARKER_END")
    tmp_dir=$(mktemp -d)
    generate_self_manage_block > "$tmp_dir/self-manage.full"
    SM_END="$SELF_MANAGE_END" awk '{ print } index($0, ENVIRON["SM_END"]) { exit }' \
        "$tmp_dir/self-manage.full" > "$tmp_dir/self-manage"
    {
        # Before the start marker: replace the self-manage block in place, or
        # inject it right before the marker if missing
        SM_START="$SELF_MANAGE_START" SM_END="$SELF_MANAGE_END" BLOCK="$tmp_dir/self-manage" \
            awk -v last="$((start_line - 1))" '
            NR > last { exit }
            !done && index($0, ENVIRON["SM_START"]) {
                while ((getline line < ENVIRON["BLOCK"]) > 0) print line
                skipping = 1
                done = 1
            }
            skipping { if (index($0, ENVIRON["SM_END"])) skipping = 0; next }
            { print }
            END { if (!done) while ((getline line < ENVIRON["BLOCK"]) > 0) print line }
            ' "$existing_file"
        $generator | sed -n "/$start_re/,/$end_re/p"
        tail -n +"$((end_line + 1))" "$existing_file"
    } > "$tmp_dir/upgraded"

    # The stamp sits in the preserved header. Keep its date and version when
    # the framework block is unchanged; otherwise bump both.
    sed -n "/$start_re/,/$end_re/p" "$existing_file" > "$tmp_dir/old-fw"
    sed -n "/$start_re/,/$end_re/p" "$tmp_dir/upgraded" > "$tmp_dir/new-fw"
    if ! cmp -s "$tmp_dir/old-fw" "$tmp_dir/new-fw"; then
        local today
        today=$(date +%Y-%m-%d)
        VER="$FRAMEWORK_VERSION" TODAY="$today" MARK="$MARKER_START" awk '
            index($0, ENVIRON["MARK"]) { seen = 1 }
            !seen && index($0, "<!-- golden-agents:stamp ") == 1 {
                printf "<!-- golden-agents:stamp version=%s updated=%s -->\n", ENVIRON["VER"], ENVIRON["TODAY"]
                next
            }
            { print }
        ' "$tmp_dir/upgraded" > "$tmp_dir/upgraded.stamp"
        mv "$tmp_dir/upgraded.stamp" "$tmp_dir/upgraded"
    fi

    # The modules comment lives in the preserved header, next to the stamp.
    if [[ "$FULL" == "true" ]]; then
        awk 'index($0, "<!-- golden-agents:modules ") != 1' "$tmp_dir/upgraded" > "$tmp_dir/upgraded.modules"
        mv "$tmp_dir/upgraded.modules" "$tmp_dir/upgraded"
    else
        apply_modules_comment "$tmp_dir/upgraded"
    fi

    if [[ "$SUPERPOWERS" == "true" ]]; then
        place_superpowers_block "$tmp_dir/upgraded"
    fi

    # Show diff or apply
    if [[ "$APPLY" != "true" ]]; then
        echo "=== UPGRADE PREVIEW (dry-run) ==="
        echo "File: $existing_file"
        echo "Languages: $LANGUAGES"
        echo "Type: ${PROJECT_TYPE:-general}"
        echo ""
        echo "--- Changes ---"
        diff -u "$existing_file" "$tmp_dir/upgraded" || true
        echo ""
        echo "--- Redirects ---"
        sync_redirects preview
        if [[ "$FULL" != "true" ]]; then
            echo ""
            echo "--- Modules ---"
            preview_modules
            echo "--- Rules ---"
            sync_scoped_rules preview
        fi
        rm -rf "$tmp_dir"
        echo ""
        echo "[INFO] This is a preview. No changes made."
        echo "  To apply: generate-agents.sh --upgrade --apply --path=$OUTPUT_PATH"
    else
        # Create backup
        local backup_file="${existing_file}.backup"
        cp "$existing_file" "$backup_file"
        echo "[OK] Backup created: $backup_file"

        # Write upgraded content
        cat "$tmp_dir/upgraded" > "$existing_file"
        rm -rf "$tmp_dir"
        echo "[OK] Upgraded: $existing_file"
        echo "  Framework: v${FRAMEWORK_VERSION}"
        report_size "$existing_file" "  "
        echo ""
        echo "  Project-specific content preserved."
        echo "  Backup: $backup_file"

        # The self-manage block tells agents to load this file
        ensure_invariants "$OUTPUT_PATH"
        sync_redirects apply-backup
        if [[ "$FULL" != "true" ]]; then
            write_selected_modules
            sync_scoped_rules apply
        fi

        # Check for bloat and trigger modular migration if needed
        local line_count
        line_count=$(wc -l < "$existing_file" | tr -d ' ')
        if [[ "$line_count" -gt "$MAX_GUIDANCE_LINES" ]]; then
            echo ""
            echo "[WARN] AGENTS.md exceeds $MAX_GUIDANCE_LINES lines ($line_count lines)"
            echo "  Creating modular migration prompt..."
            create_modular_migration_prompt "$OUTPUT_PATH"
        fi
    fi
}

# create_modular_migration_prompt()
# Creates the modular migration prompt file for bloated AGENTS.md files.
# Also creates .ai-guidance/ directory with invariants.md template.
# Copies the template and optionally adds to .gitignore.
# Arguments:
#   $1 - Directory path where the prompt file should be created
# Returns: 0 on success
create_modular_migration_prompt() {
    local dir="$1"
    if [[ -f "$TEMPLATES_DIR/modular-migration-prompt.md" ]]; then
        cp "$TEMPLATES_DIR/modular-migration-prompt.md" "$dir/MODULAR-MIGRATION-PROMPT.md"
        echo "[OK] Created: $dir/MODULAR-MIGRATION-PROMPT.md"

        # Add to .gitignore if it exists
        if [[ -f "$dir/.gitignore" ]]; then
            gitignore_add "$dir" "MODULAR-MIGRATION-PROMPT.md" || true
        fi
    fi

    ensure_invariants "$dir"
}

# ensure_invariants <dir>
# Creates <dir>/.ai-guidance/invariants.md from the template when absent.
# Files in .ai-guidance/ belong to the project once they exist and are never overwritten.
# Arguments:
#   $1 - Project directory
# Returns: 0
ensure_invariants() {
    local dir="$1"
    if [[ -e "$dir/.ai-guidance/invariants.md" ]]; then
        echo "[OK] Kept existing: $dir/.ai-guidance/invariants.md"
    elif [[ -f "$TEMPLATES_DIR/core/invariants.md" ]]; then
        mkdir -p "$dir/.ai-guidance"
        cp "$TEMPLATES_DIR/core/invariants.md" "$dir/.ai-guidance/invariants.md"
        echo "[OK] Created: $dir/.ai-guidance/invariants.md"
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

# Output (new file generation)
if [[ "$DRY_RUN" == "true" ]]; then
    echo "=== DRY RUN ($mode_label mode): Would generate the following AGENTS.md ==="
    echo ""
    $generator
    echo ""
    echo "=== Would also create redirect files: ==="
    echo "  CLAUDE.md        → @AGENTS.md"
    echo "  GEMINI.md        → @AGENTS.md"
    echo "  .github/copilot-instructions.md → @../AGENTS.md"
    echo "  CODEX.md, AGENT.md, COPILOT.md are not created"
    if [[ "$ADOPT" == "true" || "$MIGRATE" == "true" ]]; then
        for rel in $BLOCKING_REDIRECTS; do
            echo "[DRY RUN] Would back up non-generated $rel to $rel.<timestamp>.bak"
        done
    fi
    if [[ ! -e "$OUTPUT_PATH/.ai-guidance/invariants.md" ]]; then
        echo "[DRY RUN] Would create: .ai-guidance/invariants.md"
    fi
    if [[ "$FULL" != "true" ]]; then
        echo "=== Would copy modules into .golden-agents/modules/ ==="
        preview_modules
        echo "=== Would write scoped rules ==="
        sync_scoped_rules preview
    fi
    echo ""
else
    mkdir -p "$OUTPUT_PATH"
    # Only --adopt/--migrate reach here with blockers; plain runs exited earlier
    for rel in $BLOCKING_REDIRECTS; do
        backup_file "$OUTPUT_PATH/$rel"
    done
    output_file="$OUTPUT_PATH/AGENTS.md"
    $generator > "$output_file"

    # If in adopt mode, append the original content
    if [[ "$ADOPT" == "true" && -n "${ADOPT_ORIGINAL_CONTENT:-}" ]]; then
        cat >> "$output_file" << 'ADOPT_SECTION'

---

## Preserved Project Content

> **Note:** The content below was preserved from your original AGENTS.md.
> Run the ADOPT-PROMPT.md instructions with your AI assistant to deduplicate.
> Delete redundant content, keep only project-specific guidance.
> Target: 0-50 lines for most projects, max 100 lines for complex projects.

ADOPT_SECTION
        echo "$ADOPT_ORIGINAL_CONTENT" >> "$output_file"
        echo ""
        echo "[OK] Adopted existing AGENTS.md into framework"
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
    report_size "$output_file"

    echo ""
    echo "Writing @AGENTS.md imports..."
    if [[ "$MIGRATE" == "true" || "$ADOPT" == "true" ]]; then
        sync_redirects apply-force
    else
        sync_redirects apply
    fi

    echo "  ✓ CLAUDE.md        (@AGENTS.md)"
    echo "  ✓ GEMINI.md        (@AGENTS.md)"
    echo "  ✓ .github/copilot-instructions.md (@../AGENTS.md)"

    # The self-manage block tells agents to load this file
    ensure_invariants "$OUTPUT_PATH"
    if [[ "$FULL" != "true" ]]; then
        echo ""
        echo "Copying selected modules..."
        write_selected_modules
        echo "Writing scoped rules..."
        sync_scoped_rules apply
    fi
fi

