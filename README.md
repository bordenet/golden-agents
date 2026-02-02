# Golden Agents

Generates AI guidance files that don't grow out of control.

[![Tests](https://github.com/bordenet/golden-agents/actions/workflows/test.yml/badge.svg)](https://github.com/bordenet/golden-agents/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Quick Start

**Step 1:** Clone this repo locally:

```bash
git clone https://github.com/bordenet/golden-agents.git ~/.golden-agents
```

**Step 2:** Tell your AI coding assistant:

> "Read the instructions in ~/.golden-agents and apply them to my project at ~/my-project. Start with --dry-run so I can preview what will be created."

**Step 3:** Review the preview. If it looks good:

> "Apply the changes for real. Verify no existing content was lost."

That's it. Your AI handles the rest.

**[→ Full Usage Guide](docs/USAGE.md)** | **[→ Sample Output](docs/SAMPLE.md)** | **[→ Windows Installation](docs/WINDOWS.md)**

---

## What Gets Created

```
my-project/
├── Agents.md      # ~60 lines - core rules + triggers to load modules
├── CLAUDE.md      # Redirect: "See Agents.md"
├── GEMINI.md      # Redirect: "See Agents.md"
└── COPILOT.md     # Redirect: "See Agents.md"
```

The detailed modules stay in `~/.golden-agents/templates/`. Your project only gets the small core file with triggers like:

```markdown
🔴 BEFORE writing ANY `.go` file → Read `~/.golden-agents/templates/languages/go.md`
🔴 WHEN tests fail → Read `~/.golden-agents/templates/workflows/testing.md`
```

The AI loads modules on-demand instead of reading 500+ lines at session start.

**[→ How Progressive Loading Works](docs/PROGRESSIVE-LOADING.md)**

---

## Why This Exists

A 50-line `CLAUDE.md` works fine. A 500-line one wastes context tokens. A 1000-line one means the AI misses half of what you wrote.

Golden Agents keeps the core small (~60 lines) and loads detailed guidance only when relevant.

---

## Templates Included

```
~/.golden-agents/templates/
├── languages/          # Go, Python, JavaScript, Shell, Dart/Flutter
├── project-types/      # cli-tools, web-apps, mobile-apps, genesis-tools
├── workflows/          # testing, security, deployment, context-management
└── core/               # anti-slop phrases, communication rules
```

Run `--sync` periodically to get template updates:

```bash
~/.golden-agents/generate-agents.sh --sync
```

---

## Supported AI Assistants

| Assistant | Redirect File Created |
|-----------|----------------------|
| Claude Code | `CLAUDE.md` |
| Augment Code | Reads `Agents.md` directly |
| OpenAI Codex CLI | `CODEX.md` |
| Amp by Sourcegraph | `AGENT.md` |
| Google Gemini | `GEMINI.md` |
| GitHub Copilot | `COPILOT.md` + `.github/copilot-instructions.md` |

All redirect files point to `Agents.md`. Created automatically.

---

## Platform Support

| Platform | Status |
|----------|--------|
| Linux | ✅ Native |
| macOS | ✅ Native |
| Windows WSL | ✅ Native |
| Windows (Git Bash) | ✅ Supported |

**Requirements:** Bash 4.0+, Git

**[→ Windows Installation](docs/WINDOWS.md)**

---

## Documentation

| Doc | Purpose |
|-----|---------|
| **[USAGE.md](docs/USAGE.md)** | CLI options, AI-driven examples, migration workflows |
| **[SAMPLE.md](docs/SAMPLE.md)** | What the generated output looks like |
| **[PROGRESSIVE-LOADING.md](docs/PROGRESSIVE-LOADING.md)** | Why small core + on-demand modules works |
| **[TRIGGER-DESIGN.md](docs/TRIGGER-DESIGN.md)** | How to write triggers the AI won't miss |
| **[HOW-IT-WORKS.md](docs/HOW-IT-WORKS.md)** | What the script does vs. what the AI does |
| **[REFERENCES.md](docs/REFERENCES.md)** | How we implement Anthropic, GitHub, OpenAI guidance |
| **[TEST-PLAN.md](docs/TEST-PLAN.md)** | 112 tests, what we verify |
| **[SUPERPOWERS.md](docs/SUPERPOWERS.md)** | Optional: obra/superpowers integration |

---

## Contributing

1. Fork this repository
2. Add or modify templates in `templates/`
3. Run tests: `bats test/*.bats`
4. Submit a pull request

## License

MIT License - See [LICENSE](LICENSE) for details.

## Author

Matt J Bordenet ([@bordenet](https://github.com/bordenet))
