# Golden Agents

**Self-maintaining AI guidance files.** Your AI assistants automatically keep their own instruction files under control.

[![Tests](https://github.com/bordenet/golden-agents/actions/workflows/test.yml/badge.svg)](https://github.com/bordenet/golden-agents/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## The Problem

AI guidance files (`CLAUDE.md`, `Agents.md`) start small. Then you add rules. More rules. Soon you have 500+ lines and the AI ignores half of them.

**Golden Agents solves this.** Files that exceed thresholds trigger the AI to refactor them automatically—no human intervention required.

---

## Quick Start

```bash
git clone https://github.com/bordenet/golden-agents.git ~/.golden-agents
```

Then tell your AI assistant:

> "Read `~/.golden-agents/Agents.md` and run `generate-agents.sh --adopt ~/my-project`"

Your project gets a self-managing `Agents.md` in ~30 seconds.

**[→ Full Usage Guide](docs/USAGE.md)** | **[→ Sample Output](docs/SAMPLE.md)**

---

## How Self-Maintenance Works

Every generated `Agents.md` includes a **self-management protocol**:

```markdown
<!-- GOLDEN:self-manage:start -->
## 🔄 Self-Management Protocol

After ANY edit to this file or .ai-guidance/*.md, verify:
1. `wc -l Agents.md` — if >250 lines → extract content to .ai-guidance/
2. `wc -l .ai-guidance/*.md` — if any file >250 lines → split into sub-directory
<!-- GOLDEN:self-manage:end -->
```

When thresholds are exceeded, the AI:

1. **Detects the problem** — Line count check after every edit
2. **Extracts content** — Moves bloated sections to `.ai-guidance/` topic files
3. **Updates references** — Adds loading triggers so nothing is lost
4. **Verifies the result** — Confirms all content preserved, thresholds met

**No manual cleanup. No context overflow. The AI maintains its own instructions.**

---

## Thresholds

| File Type | Limit | Action When Exceeded |
|-----------|-------|----------------------|
| `Agents.md` | 250 lines | Extract to `.ai-guidance/*.md` |
| `.ai-guidance/*.md` | 250 lines | Split into sub-directory |

These limits keep files within effective context windows for all major AI assistants.

---

## What Gets Created

```
my-project/
├── Agents.md                    # ≤250 lines, self-managing
├── CLAUDE.md                    # Redirect → Agents.md
├── GEMINI.md                    # Redirect → Agents.md
├── COPILOT.md                   # Redirect → Agents.md
└── .ai-guidance/                # Auto-created when needed
    ├── invariants.md            # Self-management rules (always loaded)
    ├── testing.md               # On-demand topic file
    └── deployment.md            # On-demand topic file
```

Detailed templates stay in `~/.golden-agents/templates/`. Your project gets small trigger files:

```markdown
🔴 BEFORE writing `.go` files → Load `~/.golden-agents/templates/languages/go.md`
🔴 WHEN tests fail → Load `~/.golden-agents/templates/workflows/testing.md`
```

---

## Upgrading Existing Files

For projects with bloated guidance files:

```bash
~/.golden-agents/generate-agents.sh --upgrade ~/my-project
```

This injects the self-management protocol. If `Agents.md` exceeds 250 lines, it also creates `MODULAR-MIGRATION-PROMPT.md` with step-by-step refactoring instructions for the AI.

**[→ Design Details](docs/plans/2026-02-15-self-managing-agents-design.md)**

---

## Why Self-Maintenance Matters

| Without Self-Maintenance | With Self-Maintenance |
|--------------------------|----------------------|
| 500+ line files accumulate | Auto-splits at 250 lines |
| AI ignores rules buried deep | All rules stay accessible |
| Manual cleanup required | Zero human intervention |
| Context window overflow | Stays within limits |

---

## Templates Included

```
~/.golden-agents/templates/
├── languages/       # Go, Python, JavaScript, Shell, Dart/Flutter
├── project-types/   # cli-tools, web-apps, mobile-apps
├── workflows/       # testing, security, deployment
└── core/            # anti-slop, communication rules, invariants
```

Update templates: `~/.golden-agents/generate-agents.sh --sync`

---

## Supported AI Assistants

| Assistant | File Created |
|-----------|--------------|
| Claude Code | `CLAUDE.md` → `Agents.md` |
| Augment Code | Reads `Agents.md` directly |
| OpenAI Codex CLI | `CODEX.md` → `Agents.md` |
| Amp | `AGENT.md` → `Agents.md` |
| Gemini | `GEMINI.md` → `Agents.md` |
| GitHub Copilot | `COPILOT.md` + `.github/copilot-instructions.md` |

---

## Requirements

- Bash 4.0+
- Git
- Linux, macOS, or Windows (WSL/Git Bash)

**[→ Windows Installation](docs/WINDOWS.md)**

---

## Documentation

| Doc | Purpose |
|-----|---------|
| [USAGE.md](docs/USAGE.md) | CLI options, workflows |
| [SAMPLE.md](docs/SAMPLE.md) | Generated output examples |
| [PROGRESSIVE-LOADING.md](docs/PROGRESSIVE-LOADING.md) | On-demand module loading |
| [HOW-IT-WORKS.md](docs/HOW-IT-WORKS.md) | Script vs AI responsibilities |
| [TEST-PLAN.md](docs/TEST-PLAN.md) | 124 tests |

---

## Contributing

```bash
git clone https://github.com/bordenet/golden-agents.git
cd golden-agents
bats test/*.bats  # Run tests
```

PRs welcome for new templates in `templates/`.

---

## License

MIT — [LICENSE](LICENSE)

## Author

[@bordenet](https://github.com/bordenet)
