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
