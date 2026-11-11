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
    existing=$(check_existing_guidance "$OUTPUT_PATH")
    if [[ -n "$existing" ]]; then
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

            generate_migration_prompt "$OUTPUT_PATH" > "$OUTPUT_PATH/MIGRATION-PROMPT.md"
            echo "[OK] Created: $OUTPUT_PATH/MIGRATION-PROMPT.md"
            echo "[INFO] Target: reduce to 0-100 lines of project-specific content"

            gitignore_add "$OUTPUT_PATH" "MIGRATION-PROMPT.md" || true
            echo "[OK] Added MIGRATION-PROMPT.md to .gitignore"
        fi
    else
        echo "[INFO] No existing guidance files found. Running normal generation."
    fi

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
fi
