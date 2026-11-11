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
