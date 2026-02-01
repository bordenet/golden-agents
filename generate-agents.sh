#!/usr/bin/env bash
set -euo pipefail

# Golden Agents - Generate project-specific Agents.md from modular templates
# Repository: https://github.com/bordenet/golden-agents

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
REPO_URL="https://github.com/bordenet/golden-agents.git"

# Defaults
LANGUAGES=""
PROJECT_TYPE=""
OUTPUT_PATH="."
PROJECT_NAME=""
COMPACT=false
DRY_RUN=false
SYNC=false

usage() {
    cat << 'EOF'
NAME
    seed.sh - Generate project-specific Agents.md from modular templates

SYNOPSIS
    seed.sh [OPTIONS]
    seed.sh --sync
    seed.sh --language=LANG [--type=TYPE] [--path=PATH] [--compact]

DESCRIPTION
    Generates a self-contained Agents.md file by combining modular templates.
    The output file has no external dependencies and works with any AI assistant.

OPTIONS
    --language=LANG     Languages to include (comma-separated: go,python,javascript,shell,dart-flutter)
    --type=TYPE         Project type (genesis-tools, cli-tools, web-apps, mobile-apps)
    --path=PATH         Output directory (default: current directory)
    --name=NAME         Project name for header (default: directory name)
    --compact           Generate compact version (~130 lines) instead of full (~800)
    --sync              Update local templates from GitHub
    --dry-run           Print what would be generated without writing
    -h, --help          Show this help message
    --version           Show version information

EXAMPLES
    # Generate for a Go CLI project
    seed.sh --language=go --type=cli-tools --path=./my-cli

    # Generate compact version for a Python web app
    seed.sh --language=python --type=web-apps --compact --path=./my-api

    # Update templates from GitHub
    seed.sh --sync
EOF
}

version() {
    echo "golden-agents seed.sh v1.0.0"
}

# Sync templates from GitHub
sync_templates() {
    echo "[INFO] Syncing templates from GitHub..."
    
    if [[ -d "$SCRIPT_DIR/.git" ]]; then
        echo "[DEBUG] Pulling latest changes..."
        cd "$SCRIPT_DIR"
        git pull --rebase origin main
        echo "[OK] Templates updated"
    else
        echo "[WARN] Not a git repo. Re-clone from: $REPO_URL"
        exit 1
    fi
}

# Parse arguments
for arg in "$@"; do
    case $arg in
        --language=*) LANGUAGES="${arg#*=}" ;;
        --type=*) PROJECT_TYPE="${arg#*=}" ;;
        --path=*) OUTPUT_PATH="${arg#*=}" ;;
        --name=*) PROJECT_NAME="${arg#*=}" ;;
        --compact) COMPACT=true ;;
        --sync) SYNC=true ;;
        --dry-run) DRY_RUN=true ;;
        -h|--help) usage; exit 0 ;;
        --version) version; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; usage; exit 1 ;;
    esac
done

# Handle sync mode
if [[ "$SYNC" == "true" ]]; then
    sync_templates
    exit 0
fi

# Validate
if [[ -z "$LANGUAGES" ]]; then
    echo "Error: --language is required (or use --sync to update templates)" >&2
    usage
    exit 1
fi

# Set project name from directory if not specified
if [[ -z "$PROJECT_NAME" ]]; then
    PROJECT_NAME=$(basename "$(cd "$OUTPUT_PATH" 2>/dev/null && pwd)" 2>/dev/null || echo "Project")
fi

# Get language-specific commands
get_lang_commands() {
    local lang="$1"
    case "$lang" in
        go) echo "LINT:golangci-lint run ./..."; echo "BUILD:go build ./..."; echo "TEST:go test -race ./..."; echo "COV:80" ;;
        python) echo "LINT:pylint --fail-under=9.5 ."; echo "BUILD:mypy ."; echo "TEST:pytest --cov=."; echo "COV:80" ;;
        javascript) echo "LINT:npm run lint"; echo "BUILD:npm run build"; echo "TEST:npm test"; echo "COV:70" ;;
        dart-flutter) echo "LINT:flutter analyze"; echo "BUILD:flutter build"; echo "TEST:flutter test"; echo "COV:70" ;;
        shell) echo "LINT:shellcheck *.sh"; echo "BUILD:bash -n *.sh"; echo "TEST:bats test/"; echo "COV:N/A" ;;
        *) echo "LINT:# lint"; echo "BUILD:# build"; echo "TEST:# test"; echo "COV:70" ;;
    esac
}

# Source the generator functions from the full script
# For now, delegate to superpowers-plus if available, otherwise use embedded compact generator
if [[ -f "$HOME/GitHub/Personal/superpowers-plus/guidance/seed.sh" ]]; then
    # Use the full generator
    exec "$HOME/GitHub/Personal/superpowers-plus/guidance/seed.sh" "$@"
else
    echo "[WARN] Full generator not found. Use --sync to set up, or clone superpowers-plus."
    exit 1
fi

