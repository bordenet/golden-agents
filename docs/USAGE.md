# Usage Guide

## TL;DR: Just Tell Your AI Agent

**You have an AI coding assistant. Use it.**

### One-Time Setup

Clone golden-agents somewhere permanent:

```bash
git clone https://github.com/bordenet/golden-agents.git ~/.golden-agents
```

### Option 1: "What If?" (Preview Mode)

Open your target project in your AI-enabled editor, then ask:

> "Read the instructions in `~/.golden-agents` and show me what you would do to set up AI guidance for this project. Use --dry-run so I can preview first."

Your AI will:
1. Read the golden-agents instructions
2. Analyze your project's current state
3. Show you exactly what files would be created/modified
4. Wait for your approval before proceeding

### Option 2: "Just Do It!" (Full Auto)

Open your target project, then ask:

> "Read `~/.golden-agents` and set up AI guidance for this project. It's a Python web app. Auto-detect everything, run the appropriate commands, and verify the result."

Your AI will:
1. Read the golden-agents instructions
2. Detect existing guidance files (CLAUDE.md, Agents.md, etc.)
3. Choose the right mode (generate, migrate, adopt, upgrade)
4. Run with `--dry-run` first, then apply
5. Verify zero data loss
6. Report what was created

### Option 3: Manual (Reference)

If you prefer CLI control, see the command reference below.

---

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
│   ├── HOW-IT-WORKS.md        # Security & transparency explanation
│   ├── PROGRESSIVE-LOADING.md # How on-demand module loading works
│   ├── REFERENCES.md          # Template reference with examples
│   ├── SAMPLE.md              # Example generated output
│   ├── SUPERPOWERS.md         # Optional superpowers integration
│   ├── TEST-PLAN.md           # Test plan (124 tests)
│   ├── TRIGGER-DESIGN.md      # How triggers are designed
│   ├── USAGE.md               # This file
│   └── WINDOWS.md             # Windows-specific instructions
└── test/
    ├── *.bats             # BATS tests (bash script)
    └── *.Tests.ps1        # Pester tests (PowerShell wrapper)
```

