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

# Set when generate-agents.sh sources lib/golden-agents/part*.sh.
if [[ -n "${GOLDEN_AGENTS_ROOT:-}" ]]; then
    SCRIPT_DIR="$GOLDEN_AGENTS_ROOT"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
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
NO_BACKUP=false
SELF_TEST=false

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
                        back inside the framework. A bootstrap already in the
                        file, including one inside the framework, is kept below
                        the end marker.
    --sync              Update local templates from GitHub (git fetch, fast-forward
                        only; refuses on uncommitted changes or local commits)
    --dry-run           Print what would be generated without writing
    --migrate           Migrate existing guidance files (creates MIGRATION-PROMPT.md)
    --adopt             Adopt existing AGENTS.md (backs up, appends, creates ADOPT-PROMPT.md)
    --dedupe            Deduplicate bloated project-specific section (for files WITH markers)
    --upgrade           Upgrade existing AGENTS.md (dry-run by default, shows diff)
    --apply             Apply upgrade changes (requires --upgrade, creates backup first)
    --no-backup         Skip .bak / AGENTS.md.backup writes (for batch runs that
                        already backed up; requires --apply, --adopt, or --migrate)
    --self-test         Verify this checkout is complete (part sizes, not stubs,
                        bash -n, --version) then exit; also runs before --upgrade
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
    - --no-backup: skips .backup and timestamped .bak (batch upgrades only)
    - --self-test: verifies this checkout before any consumer write
    - Files WITHOUT markers: REFUSES to upgrade (suggests migration)
    - Project-specific sections (outside markers) are ALWAYS preserved
    - Hand-written lines inside the managed block are moved below the end
      marker (not deleted); preview lists them; a second upgrade does not
      duplicate them

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
# Skips the copy when NO_BACKUP=true (batch runs that already backed up).
# Arguments:
#   $1 - Path to the file to back up
# Returns: 0 on success
backup_file() {
    local src="$1"
    if [[ "${NO_BACKUP:-false}" == "true" ]]; then
        echo "[OK] Skipped backup (--no-backup): $src"
        return 0
    fi
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
            if [[ -f "$OUTPUT_PATH/$rel" ]]; then
                echo "  would rewrite $rel to @AGENTS.md import (kept redirect; replaces old stub)"
            else
                echo "  would write $rel (@AGENTS.md import)"
            fi
            continue
        fi
        if [[ "$mode" == "apply-backup" && -f "$OUTPUT_PATH/$rel" ]]; then
            local desired
            desired=$(mktemp)
            {
                import_redirect_body "$rel"
                echo "$GENERATED_SENTINEL"
            } > "$desired"
            if cmp -s "$OUTPUT_PATH/$rel" "$desired"; then
                rm -f "$desired"
                continue
            fi
            rm -f "$desired"
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
            echo "  would remove $rel (matches old generated stub; AGENT.md/CODEX.md/COPILOT.md are retired)"
            continue
        fi
        backup_file "$OUTPUT_PATH/$rel"
        rm -f "$OUTPUT_PATH/$rel"
        echo "  removed $rel (matched old generated stub; retired redirect)"
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

# run_self_test
# Verifies this golden-agents checkout can run before --upgrade --apply.
# Catches truncated path stubs and incomplete part*.sh files that would
# otherwise fail mid-upgrade or with exit 127 when +x is missing / when
# a stub is `source`d. Intended to run after part00 is loaded and before
# other parts are sourced.
# Arguments: none
# Returns: 0 on success; exits 1 on failure
run_self_test() {
    local entry part size head1 fail=0
    entry="$SCRIPT_DIR/generate-agents.sh"
    echo "[INFO] Self-test: $SCRIPT_DIR"

    if [[ ! -f "$entry" ]]; then
        echo "[FAIL] Missing entry script: $entry" >&2
        exit 1
    fi

    shopt -s nullglob
    local parts=( "$SCRIPT_DIR"/lib/golden-agents/part*.sh )
    shopt -u nullglob
    if [[ ${#parts[@]} -eq 0 ]]; then
        echo "[FAIL] No lib/golden-agents/part*.sh files found" >&2
        exit 1
    fi

    for part in "${parts[@]}"; do
        size=$(wc -c < "$part" | tr -d ' ')
        if [[ "$size" -lt 1000 ]]; then
            echo "[FAIL] $part is only ${size} bytes (need >= 1000); likely truncated" >&2
            fail=1
            continue
        fi
        head1=$(head -n 1 "$part")
        case "$head1" in
            @*|PLACEHOLDER*|LOAD_FROM:*)
                echo "[FAIL] $part looks like a stub (head: $head1)" >&2
                fail=1
                continue
                ;;
        esac
        # Truncated uploads were path stubs or LOAD_* tokens, not shell.
        if [[ "$head1" != \#!* && "$head1" != \#* && "$head1" != [a-zA-Z_]*'()'* ]]; then
            echo "[FAIL] $part head is not a shell script: $head1" >&2
            fail=1
            continue
        fi
        if head -n 5 "$part" | grep -qE '^LOAD_|FROM_PRIOR_SUCCESSFUL_UPLOAD|^lib/golden-agents/'; then
            echo "[FAIL] $part looks like a truncated path stub" >&2
            fail=1
            continue
        fi
        if ! bash -n "$part"; then
            echo "[FAIL] bash -n failed for $part" >&2
            fail=1
        else
            echo "[OK] bash -n $part (${size} bytes)"
        fi
    done

    if ! bash -n "$entry"; then
        echo "[FAIL] bash -n failed for $entry" >&2
        fail=1
    else
        echo "[OK] bash -n $entry"
    fi

    if [[ ! -x "$entry" ]]; then
        echo "[WARN] $entry is not executable" >&2
    fi

    # --version sources every part; skip it when a part already failed.
    if [[ "$fail" -eq 0 ]]; then
        local ver
        if ! ver=$(bash "$entry" --version 2>&1); then
            echo "[FAIL] --version failed: $ver" >&2
            fail=1
        else
            echo "[OK] $ver"
        fi
    fi

    if [[ "$fail" -ne 0 ]]; then
        echo "[FAIL] Self-test failed. Fix the checkout before --upgrade --apply." >&2
        exit 1
    fi
    echo "[OK] Self-test PASS"
    return 0
}

# check_existing_guidance <path>
# Checks for existing guidance files that would be overwritten.
# Detects non-generated CLAUDE.md, and Agents.md and AGENTS.md without markers.
# Arguments:
#   $1 - Directory path to check
# Returns: Space-separated list of found files with sizes via stdout, or empty string
