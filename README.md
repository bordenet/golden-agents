# Golden Agents Framework

> **Stop repeating yourself to AI coding assistants. Standardize once, enforce everywhere.**

[![Tests](https://github.com/bordenet/golden-agents/actions/workflows/test.yml/badge.svg)](https://github.com/bordenet/golden-agents/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## The Problem

AI coding assistants drift. They bypass quality gates, skip tests, ignore style guides, and make random choices about tooling. You find yourself repeating the same instructions across every project, every session.

## The Solution

Golden Agents generates a single `Agents.md` file that all major AI assistants read automatically. One file. Consistent behavior. No more drift.

**What you get:**

- **Quality gates** - Lint → Build → Test order enforced before every commit
- **Anti-slop rules** - Banned phrases, no flattery, evidence-based claims only
- **Skill integration** - Automatic invocation of brainstorming, TDD, debugging workflows
- **Language-specific guidance** - Go, Python, JavaScript, Shell, Dart/Flutter
- **Project-type templates** - CLI tools, web apps, mobile apps

**[→ See sample output](docs/SAMPLE.md)** to inspect what gets generated.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| **Linux** | ✅ Native | Works out of the box |
| **macOS** | ✅ Native | Works out of the box |
| **Windows WSL** | ✅ Native | Run from WSL bash shell |
| **Windows Native** | ✅ Supported | Requires Git Bash, Cygwin, or MSYS2 |

**Requirements:** Bash 4.0+ and Git

### Supported AI Coding Assistants

| Assistant | Config File | Notes |
|-----------|-------------|-------|
| **Claude Code** | `CLAUDE.md` → `Agents.md` | Anthropic's terminal-based agent |
| **Augment Code** | Reads `Agents.md` directly | Also reads `CLAUDE.md`, `AGENTS.md` |
| **OpenAI Codex CLI** | `CODEX.md` → `Agents.md` | Hierarchical instruction system |
| **Amp by Sourcegraph** | `AGENT.md` → `Agents.md` | Frontier coding agent |
| **Google Gemini** | `GEMINI.md` → `Agents.md` | Also accepts `AGENT.md` |
| **GitHub Copilot** | `COPILOT.md`, `.github/copilot-instructions.md` → `Agents.md` | Knowledge bases + custom instructions |

The generator creates all necessary redirect files automatically.

**Tip:** You can safely delete redirect files for AI assistants you don't use (e.g., delete `GEMINI.md` if you only use Claude Code).

## Quick Start

### Option 1: Generate a new Agents.md

```bash
# Clone this repo
git clone https://github.com/bordenet/golden-agents.git ~/.golden-agents

# Generate for your project
~/.golden-agents/generate-agents.sh --language=go --type=cli-tools --path=./my-project

# Or use compact mode (~130 lines instead of ~800)
~/.golden-agents/generate-agents.sh --language=python --compact --path=./my-project
```

### Option 2: Use the pre-generated core file

```bash
# Copy the standalone Agents.md to your project
cp ~/.golden-agents/Agents.core.md ./Agents.md
```

### Option 3: Upgrade existing Agents.md (safe)

```bash
# Preview what would change (dry-run, writes nothing)
~/.golden-agents/generate-agents.sh --upgrade --path=./my-project

# Apply upgrade (creates .backup first, preserves project-specific content)
~/.golden-agents/generate-agents.sh --upgrade --apply --path=./my-project
```

**Upgrade safety:**
- Dry-run by default (shows diff, writes nothing)
- Creates backup before any modification
- REFUSES to modify files without framework markers
- Preserves all project-specific content outside markers

### Option 4: Sync templates from GitHub

```bash
# Update your local templates
~/.golden-agents/generate-agents.sh --sync
```

## Features

- **Safe upgrades** - Update framework sections while preserving project-specific content
- **Modular templates** - Mix and match languages, project types, and workflows
- **Compact mode** - 6x smaller files with essential guidance only
- **Self-contained output** - Generated files have no external dependencies
- **Sync mechanism** - Keep templates up-to-date from GitHub
- **Multi-language** - Go, Python, JavaScript, Shell, Dart/Flutter

## Directory Structure

```
golden-agents/
├── .github/
│   ├── workflows/test.yml              # CI: BATS, Pester, ShellCheck
│   └── copilot-instructions.md         # GitHub Copilot custom instructions
├── Agents.md              # Primary AI guidance (canonical source)
├── AGENT.md               # Redirect → Amp by Sourcegraph
├── CLAUDE.md              # Redirect → Claude Code
├── CODEX.md               # Redirect → OpenAI Codex CLI
├── COPILOT.md             # Redirect → GitHub Copilot
├── GEMINI.md              # Redirect → Google Gemini
├── README.md              # This file
├── generate-agents.sh     # Generator script (Linux/macOS/WSL/Git Bash)
├── generate-agents.ps1    # PowerShell wrapper (Windows)
├── Agents.core.md         # Pre-generated compact version (standalone)
├── CHANGELOG.md           # Version history
├── docs/
│   └── TEST-PLAN.md       # Comprehensive test plan
├── test/
│   ├── *.bats             # BATS tests (53 tests)
│   ├── *.Tests.ps1        # Pester tests (14 tests)
│   └── test_helper.bash   # Shared test utilities
└── templates/
    ├── core/              # Superpowers, anti-slop, communication
    ├── languages/         # Go, Python, JS, Shell, Dart-Flutter
    ├── project-types/     # CLI, web, mobile, genesis
    └── workflows/         # Testing, security, context management
```

## Available Options

### Languages

| Language | File | Key Features |
|----------|------|--------------|
| `go` | languages/go.md | golangci-lint, table-driven tests, error wrapping |
| `python` | languages/python.md | pylint, mypy, type annotations |
| `javascript` | languages/javascript.md | ESLint, Prettier, async/await |
| `shell` | languages/shell.md | shellcheck, set -euo pipefail |
| `dart-flutter` | languages/dart-flutter.md | flutter analyze, AppLogger |

### Project Types

| Type | File | Key Features |
|------|------|--------------|
| `cli-tools` | project-types/cli-tools.md | --help, exit codes, piping |
| `web-apps` | project-types/web-apps.md | API versioning, CORS, health checks |
| `mobile-apps` | project-types/mobile-apps.md | iOS/Android builds, privacy logging |
| `genesis-tools` | project-types/genesis-tools.md | Template validation, --dry-run |

### Workflows

| Workflow | File | Purpose |
|----------|------|---------|
| `testing` | workflows/testing.md | Coverage requirements, test patterns |
| `security` | workflows/security.md | Secret scanning, dependency audits |
| `deployment` | workflows/deployment.md | CI/CD, environment management |
| `context-management` | workflows/context-management.md | Token efficiency, session resumption |
| `build-hygiene` | workflows/build-hygiene.md | Lint → Build → Test order |

## Usage Examples

```bash
# Go CLI tool
./generate-agents.sh --language=go --type=cli-tools --path=./my-cli

# Python web app
./generate-agents.sh --language=python --type=web-apps --path=./my-api

# Flutter mobile app
./generate-agents.sh --language=dart-flutter --type=mobile-apps --path=./my-app

# Multi-language project
./generate-agents.sh --language=go,shell --type=cli-tools --path=./my-project

# Compact mode (recommended for most projects)
./generate-agents.sh --language=javascript --compact --path=./my-project

# Dry run (preview without writing)
./generate-agents.sh --language=python --compact --dry-run
```

## Integration with Superpowers

This framework integrates with [obra/superpowers](https://github.com/obra/superpowers) for AI skill management. Generated files include bootstrap instructions for:

- `superpowers:brainstorming` - Before creative work
- `superpowers:systematic-debugging` - Before fixing bugs
- `superpowers:test-driven-development` - Before implementation
- `superpowers:verification-before-completion` - Before claiming done

## Windows Installation

### Option 1: WSL (Recommended)

```powershell
# Install WSL if not already installed
wsl --install

# Then from WSL bash:
git clone https://github.com/bordenet/golden-agents.git ~/.golden-agents
~/.golden-agents/generate-agents.sh --language=python --path=./my-project
```

### Option 2: Git Bash

1. Install [Git for Windows](https://git-scm.com/download/win) (includes Git Bash)
2. Open Git Bash
3. Run:

```bash
git clone https://github.com/bordenet/golden-agents.git ~/.golden-agents
~/.golden-agents/generate-agents.sh --language=python --path=./my-project
```

### Option 3: PowerShell Wrapper (Auto-detects WSL/Git Bash)

```powershell
# Clone the repo
git clone https://github.com/bordenet/golden-agents.git $HOME\.golden-agents

# Use the PowerShell wrapper (auto-detects WSL or Git Bash)
~\.golden-agents\generate-agents.ps1 --language=python --path=.\my-project
```

The `.ps1` wrapper automatically uses WSL if available, falls back to Git Bash, or shows installation instructions if neither is found.

### Option 4: MSYS2 / Cygwin

Install [MSYS2](https://www.msys2.org/) or [Cygwin](https://www.cygwin.com/), then run from their bash shell.

## Testing

**67 automated tests** run on every push/PR via GitHub Actions:

| Test Suite | Framework | Tests | Platforms |
|------------|-----------|-------|-----------|
| Core script | BATS | 53 | Linux, macOS, Windows (Git Bash) |
| PowerShell wrapper | Pester | 14 | Linux, macOS, Windows |
| Linting | ShellCheck | - | Linux |

```bash
# Run BATS tests locally
brew install bats-core  # macOS
bats test/*.bats

# Run Pester tests locally
Install-Module -Name Pester -Force -MinimumVersion 5.0
Invoke-Pester test/*.Tests.ps1 -Output Detailed
```

See [docs/TEST-PLAN.md](docs/TEST-PLAN.md) for the full test plan.

## Contributing

1. Fork this repository
2. Add or modify templates in `templates/`
3. Run tests: `bats test/*.bats`
4. Submit a pull request

## License

MIT License - See [LICENSE](LICENSE) for details.

## Author

Matt J Bordenet ([@bordenet](https://github.com/bordenet))

---

### Best Practices Sources

This framework incorporates official guidance from:

| Source | Key Concepts |
|--------|--------------|
| [Anthropic Context Engineering](https://www.anthropic.com/engineering/claude-code-best-practices) | CLAUDE.md hierarchy, subagents, explore-plan-code-commit workflow |
| [GitHub Copilot Best Practices](https://docs.github.com/en/copilot/get-started/best-practices) | Prompt engineering, context management, validation |
| [OpenAI Codex Prompting Guide](https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide/) | AGENTS.md specification, tool-use directives, autonomy settings |
| [Gemini Code Assist](https://developers.google.com/gemini-code-assist/docs/use-agentic-chat-pair-programmer) | GEMINI.md context files, MCP integration |
| [Spotify Golden Path](https://engineering.atspotify.com/2020/08/how-we-use-golden-paths-to-solve-fragmentation-in-our-software-ecosystem/) | Standardization philosophy |

---

## Why I Built This

Over six months of vibe coding, I created around 20 repositories. I noticed patterns in how even my favorite AI agents drifted off the golden path:

- **Bypassing quality gates** - Skipping linters, ignoring test failures, committing anyway
- **Scope creep excuses** - "That's a preexisting issue, not in scope" (always false)
- **Random tooling choices** - Different testing frameworks in every project, inconsistent coverage thresholds
- **Style guide violations** - Adopting coding standards only to watch agents ignore them

I found myself repeating the same instructions in every session. It got tiring.

So I consolidated all my guidance into a single document. But 800 lines is too much—no AI agent can faithfully follow that. Borrowing from [obra/superpowers](https://github.com/obra/superpowers), I factored the guidance into progressively loaded modules.

This repo exists for three reasons:

1. **Community contribution** - Share what works
2. **Learn from others** - See how you solve these problems
3. **Continuous improvement** - More eyes, better guidance

If you've experienced similar drift, give it a try. If you have better solutions, open a PR.

