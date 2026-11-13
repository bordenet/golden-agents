# Golden Agents

**Self-maintaining AI guidance files.** AI assistants automatically refactor their own instruction files when they exceed size thresholds.

[![Tests](https://github.com/bordenet/golden-agents/actions/workflows/test.yml/badge.svg)](https://github.com/bordenet/golden-agents/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## The Problem

AI guidance files (`CLAUDE.md`, `AGENTS.md`) accumulate rules over time. Past a certain size, AI assistants start ignoring instructions buried deep in the file.

Golden Agents embeds a self-management protocol into generated files. When a file exceeds 250 lines, the assistant drafts a diff that extracts content to topic-specific modules. A human merges that diff.

---

## Quick Start

```bash
git clone https://github.com/bordenet/golden-agents.git ~/.golden-agents
```

Then tell your AI assistant:

> "Read `~/.golden-agents/AGENTS.md` and run `generate-agents.sh --adopt ~/my-project`"

Your project gets a self-managing `AGENTS.md`.

**[→ Full Usage Guide](docs/USAGE.md)** | **[→ Sample Output](docs/SAMPLE.md)**

---

## How Self-Maintenance Works

Every generated `AGENTS.md` includes a **self-management protocol**:

```markdown
<!-- GOLDEN:self-manage:start -->
## 🔄 Self-Management Protocol

After ANY edit to this file or .ai-guidance/*.md, verify:
1. `wc -l AGENTS.md` — if >250 lines → extract content to .ai-guidance/
2. `wc -l .ai-guidance/*.md` — if any file >250 lines → split into sub-directory
3. Over the limit, draft a diff. Do not apply it. A human merges it.
<!-- GOLDEN:self-manage:end -->
```

When thresholds are exceeded, the assistant:

1. **Detects the problem** — Line count check after every edit
2. **Drafts a diff** — Moves bloated sections to `.ai-guidance/` topic files
3. **Stops** — A human reviews and merges the diff
4. **After the merge** — The result keeps every rule and meets the limit

---

## Thresholds

| File Type | Limit | Action When Exceeded |
|-----------|-------|----------------------|
| `AGENTS.md` | 250 lines | Extract to `.ai-guidance/*.md` |
| `.ai-guidance/*.md` | 250 lines | Split into sub-directory |

250 lines is the lock this script enforces. 200 lines is the soft ceiling for the always-loaded file. That figure is guidance for authors. Overflow belongs in scoped rules, not in a longer `AGENTS.md`.

---

## What Gets Created

```
my-project/
├── AGENTS.md                    # ≤250 lines, self-managing
├── CLAUDE.md                    # @AGENTS.md
├── GEMINI.md                    # @AGENTS.md
├── .golden-agents/modules/      # Copies of the modules this project selected
│   ├── go.md
│   └── testing.md
└── .ai-guidance/                # Auto-created when needed
    └── invariants.md            # Self-management rules (always loaded)
```

Triggers point at the copies in the project:

```markdown
🔴 BEFORE writing `.go` files → Read `.golden-agents/modules/go.md`
🔴 WHEN tests fail → Read `.golden-agents/modules/testing.md`
```

---

## Upgrading Existing Files

For projects with bloated guidance files:

```bash
~/.golden-agents/generate-agents.sh --upgrade ~/my-project
```

This injects the self-management protocol into existing files. For files exceeding 250 lines, it also creates `MODULAR-MIGRATION-PROMPT.md` with refactoring instructions.

**[→ Design Details](docs/plans/2026-02-15-self-managing-agents-design.md)**

---

## Why Self-Maintenance Matters

| Without Self-Maintenance | With Self-Maintenance |
|--------------------------|----------------------|
| 500+ line files accumulate | A drafted split at 250 lines, merged by a human |
| AI ignores rules buried deep | All rules stay accessible |
| An assistant rewrites the rules | The assistant drafts; a human merges |
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
| Claude Code | `CLAUDE.md` is `@AGENTS.md` |
| Augment Code | Reads `AGENTS.md` directly |
| OpenAI Codex CLI | Reads `AGENTS.md` directly |
| Amp | Reads `AGENTS.md` directly |
| Gemini | `GEMINI.md` is `@AGENTS.md` |
| GitHub Copilot | `.github/copilot-instructions.md` is `@../AGENTS.md` (not `COPILOT.md`) |

---

## Requirements

- Bash 3.2+
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
| [TEST-PLAN.md](docs/TEST-PLAN.md) | Test suite documentation |

---

## Contributing

```bash
git clone https://github.com/bordenet/golden-agents.git
cd golden-agents
bats test/*.bats  # Run tests
```

PRs welcome for new templates in `templates/`.

---

## Related Projects

| Project | Purpose |
|---------|---------|
| [superpowers-plus](https://github.com/bordenet/superpowers-plus) | Skills for Claude, Augment, and other AI coding assistants |
| [docforge-ai](https://github.com/bordenet/docforge-ai) | Adversarial document generation |

---

## License

MIT — [LICENSE](LICENSE)

## Author

[@bordenet](https://github.com/bordenet)
