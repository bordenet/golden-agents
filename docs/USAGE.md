# Usage Guide

## Which Mode Do I Use?

| Your Situation | Command | What Happens |
|----------------|---------|--------------|
| **No Agents.md file** (or <10 lines) | `--language=X --path=Y` | Generates new file with framework |
| **Existing CLAUDE.md, GEMINI.md, CODEX.md** | `--migrate --path=Y` | Creates migration prompt, preserves originals |
| **Existing Agents.md WITHOUT markers** | `--adopt --language=X --path=Y` | Backs up original, generates framework, appends content |
| **Existing Agents.md WITH markers (outdated)** | `--upgrade --path=Y` | Preview changes (dry-run), then `--apply` to update |
| **Existing Agents.md WITH markers (bloated)** | `--dedupe --path=Y` | Creates deduplication prompt if >100 lines |

**How to tell if your file has markers:** Look for `<!-- GOLDEN:framework:start -->` near the top.

## Safety Mechanisms

| Mode | Backup Created | Dry-Run Default | Files Modified |
|------|----------------|-----------------|----------------|
| Generate (`--language`) | ❌ (new file) | Use `--dry-run` | Creates new files |
| Migrate (`--migrate`) | ✅ Preserves originals | ❌ | Creates MIGRATION-PROMPT.md only |
| Adopt (`--adopt`) | ✅ `Agents.md.original` | ❌ | Rewrites Agents.md |
| Upgrade (`--upgrade`) | ✅ `.backup` on apply | ✅ Preview first | Only with `--apply` |
| Dedupe (`--dedupe`) | ❌ (doesn't modify) | ✅ Always | Creates ADOPT-PROMPT.md only |

**⚠️ Data Loss Prevention:**

- **Always preview first:** Use `--dry-run` for new files, `--upgrade` (without `--apply`) for upgrades
- **Backups are automatic:** `--adopt` creates `.original`, `--upgrade --apply` creates `.backup`
- **Dedupe never modifies:** It only creates a prompt file; YOU apply the changes after review
- **Originals preserved:** `--migrate` keeps your CLAUDE.md/GEMINI.md files intact

## Usage Examples

```bash
# Generate for a Go CLI project
./generate-agents.sh --language=go --type=cli-tools --path=./my-cli

# Generate for a Python web app
./generate-agents.sh --language=python --type=web-apps --path=./my-api

# Upgrade existing file (dry-run first, then apply)
./generate-agents.sh --upgrade --path=./my-project
./generate-agents.sh --upgrade --apply --path=./my-project

# Adopt existing Agents.md into framework
./generate-agents.sh --adopt --language=python --path=./my-project
```

**Other options:**
- `--migrate` - Import existing CLAUDE.md/GEMINI.md content
- `--dedupe` - Trim bloated project-specific sections (>100 lines)
- `--sync` - Update local templates from GitHub
- `--dry-run` - Preview without writing

## Available Languages

| Language | File | Key Features |
|----------|------|--------------|
| `go` | languages/go.md | golangci-lint, table-driven tests, error wrapping |
| `python` | languages/python.md | pylint, mypy, type annotations |
| `javascript` | languages/javascript.md | ESLint, Prettier, async/await |
| `shell` | languages/shell.md | shellcheck, set -euo pipefail |
| `dart-flutter` | languages/dart-flutter.md | flutter analyze, AppLogger |

## Available Project Types

| Type | File | Key Features |
|------|------|--------------|
| `cli-tools` | project-types/cli-tools.md | --help, exit codes, piping |
| `web-apps` | project-types/web-apps.md | API versioning, CORS, health checks |
| `mobile-apps` | project-types/mobile-apps.md | iOS/Android builds, privacy logging |
| `genesis-tools` | project-types/genesis-tools.md | Template validation, --dry-run |

## Available Workflows

| Workflow | File | Purpose |
|----------|------|---------|
| `testing` | workflows/testing.md | Coverage requirements, test patterns |
| `security` | workflows/security.md | Secret scanning, dependency audits |
| `deployment` | workflows/deployment.md | CI/CD, environment management |
| `context-management` | workflows/context-management.md | Token efficiency, session resumption |
| `build-hygiene` | workflows/build-hygiene.md | Lint → Build → Test order |

## Directory Structure

```
golden-agents/
├── generate-agents.sh     # Generator script (Linux/macOS/WSL/Git Bash)
├── generate-agents.ps1    # PowerShell wrapper (Windows)
├── templates/
│   ├── core/              # Superpowers, anti-slop, communication
│   ├── languages/         # Go, Python, JS, Shell, Dart-Flutter
│   ├── project-types/     # CLI, web, mobile, genesis
│   └── workflows/         # Testing, security, context management
├── docs/
│   ├── HOW-IT-WORKS.md    # Security & transparency explanation
│   ├── SAMPLE.md          # Example generated output
│   └── TEST-PLAN.md       # Test plan
└── test/
    ├── *.bats             # BATS tests (bash script)
    └── *.Tests.ps1        # Pester tests (PowerShell wrapper)
```

