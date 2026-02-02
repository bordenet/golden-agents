# Golden Agents

Generate `Agents.md` files that enforce consistent AI coding assistant behavior across all your projects.

[![GitHub Stars](https://img.shields.io/github/stars/bordenet/golden-agents?style=social)](https://github.com/bordenet/golden-agents)
[![Tests](https://github.com/bordenet/golden-agents/actions/workflows/test.yml/badge.svg)](https://github.com/bordenet/golden-agents/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/bordenet/golden-agents/graph/badge.svg)](https://codecov.io/gh/bordenet/golden-agents)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Quick Start

```bash
# Clone once
git clone https://github.com/bordenet/golden-agents.git ~/.golden-agents

# Generate for your project
~/.golden-agents/generate-agents.sh --language=go --path=./my-project
```

Done. Your AI assistant now follows lint→build→test order, avoids slop phrases, and loads detailed guidance on-demand.

**[→ See sample output](docs/SAMPLE.md)**

## What It Does

| Feature | Description |
|---------|-------------|
| Quality gates | Enforces Lint → Build → Test before commits |
| Anti-slop rules | Bans "revolutionary", "seamless", "Happy to help!" |
| Language templates | Go, Python, JavaScript, Shell, Dart/Flutter |
| Project types | CLI tools, web apps, mobile apps |
| Skill integration | Works with [superpowers](https://github.com/obra/superpowers) |

## vs. Spec Kit

This project is **complementary to** [GitHub Spec Kit](https://github.com/github/spec-kit), not a replacement.

| Aspect | Golden Agents | Spec Kit |
|--------|---------------|----------|
| **Focus** | HOW the AI behaves (quality, style) | WHAT to build (specs, workflow) |
| **Problem** | AI drift, sloppy output, skipped tests | Vague requirements, "vibe coding" |
| **Output** | `Agents.md` with rules and checklists | Spec→Plan→Tasks→Implementation workflow |
| **Scope** | Behavior governance | Development methodology |

**Use together:** Run `specify init` (Spec Kit) for project structure, then merge golden-agents templates into your `CLAUDE.md`/`AGENTS.md` for quality enforcement during implementation.

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

> [!TIP]
> You can safely delete redirect files for AI assistants you don't use (e.g., delete `GEMINI.md` if you only use Claude Code).

## Which Mode Do I Use?

| Your Situation | Command | What Happens |
|----------------|---------|--------------|
| **No Agents.md file** (or <10 lines) | `--language=X --path=Y` | Generates new file with framework |
| **Existing CLAUDE.md, GEMINI.md, CODEX.md** | `--migrate --path=Y` | Creates migration prompt, preserves originals |
| **Existing Agents.md WITHOUT markers** | `--adopt --language=X --path=Y` | Backs up original, generates framework, appends content |
| **Existing Agents.md WITH markers (outdated)** | `--upgrade --path=Y` | Preview changes (dry-run), then `--apply` to update |
| **Existing Agents.md WITH markers (bloated)** | `--dedupe --path=Y` | Creates deduplication prompt if >100 lines |

**How to tell if your file has markers:** Look for `<!-- GOLDEN:framework:start -->` near the top.

### Safety Mechanisms

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
# Default: ~60 lines core + on-demand loading
./generate-agents.sh --language=go --type=cli-tools --path=./my-cli

# Compact mode - ~130 lines, inlined but condensed
./generate-agents.sh --compact --language=python --type=web-apps --path=./my-api

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

### Output Mode Comparison

| Mode | Lines | Use Case |
|------|-------|----------|
| (default) | ~60 | Minimal core, templates loaded on-demand from `~/.golden-agents/templates/` |
| `--compact` | ~130 | Self-contained but condensed. Good for repos without template access |

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
│   ├── SAMPLE.md          # Example generated output
│   └── TEST-PLAN.md       # Test plan
├── test/
│   ├── *.bats             # BATS tests (94 tests)
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

## Integration with Superpowers (Optional)

This framework optionally integrates with [obra/superpowers](https://github.com/obra/superpowers) for enhanced AI skill management. Superpowers is **not required** — all generated Agents.md files include self-contained workflow checklists that work with any AI assistant.

If superpowers is installed, users get interactive skill-based workflows:

- `superpowers:brainstorming` - Before creative work
- `superpowers:systematic-debugging` - Before fixing bugs
- `superpowers:test-driven-development` - Before implementation
- `superpowers:verification-before-completion` - Before claiming done

If not installed, the inline checklists provide equivalent guidance.

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

**108 automated tests** run on every push/PR via GitHub Actions:

| Test Suite | Framework | Tests | Platforms |
|------------|-----------|-------|-----------|
| Core script | BATS | 94 | Linux, macOS, Windows (Git Bash) |
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

## Why This Exists

AI coding assistants drift: they skip linters, ignore test failures, make random tooling choices, and forget project conventions. After 20+ repos, I got tired of repeating the same instructions every session.

**The solution:** Progressive loading. Core framework loads at startup (~60 lines), language/workflow modules load on-demand from `~/.golden-agents/templates/`, project-specific content stays under 50 lines.

If your Agents.md project section exceeds 100 lines, use `--adopt` with deduplication.

### Complex Projects: The `.ai-guidance/` Pattern

Some projects genuinely have extensive project-specific documentation (mobile builds, capture architectures, security protocols). For these:

1. **Create `.ai-guidance/` in your repo** with topic-specific modules
2. **Add a loading table to Agents.md** referencing when to load each module
3. **Keep Agents.md under 150 lines** with quick reference + loading instructions

Example structure:
```
your-repo/
├── Agents.md                           # ~100-150 lines (quick ref + loading table)
└── .ai-guidance/
    ├── mobile-builds.md                # iOS/Android build details
    ├── architecture.md                 # System architecture
    └── security-protocols.md           # Security requirements
```

Example loading table in Agents.md:
```markdown
| When... | Load |
|---------|------|
| Building iOS/Android | [.ai-guidance/mobile-builds.md](.ai-guidance/mobile-builds.md) |
| System design | [.ai-guidance/architecture.md](.ai-guidance/architecture.md) |
```

This mirrors how the framework uses `~/.golden-agents/templates/` for generic content, but with project-specific modules in the repo itself.
