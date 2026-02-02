# Golden Agents

**AI coding assistants need guidance, but guidance files don't scale.**

A 50-line `CLAUDE.md` works fine. A 500-line one wastes context tokens and buries critical rules. A 1000-line one means the AI misses half of what you wrote.

Golden Agents solves this with **progressive loading**: a minimal core file (~60 lines) that loads detailed guidance on-demand based on what the AI is actually doing.

[![Tests](https://github.com/bordenet/golden-agents/actions/workflows/test.yml/badge.svg)](https://github.com/bordenet/golden-agents/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Who Should Use This

- **Developers with 3+ AI-assisted repos** who are tired of repeating the same instructions
- **Teams standardizing AI behavior** across projects (linting, testing, commit hygiene)
- **Anyone whose CLAUDE.md/AGENTS.md has grown past 200 lines** and noticed the AI ignoring rules

**Not for you if:** You're happy with a simple 50-line guidance file, or you prefer manual per-session instructions.

---

## The Problem

| Project Stage | Guidance Size | What Happens |
|---------------|---------------|--------------|
| New project | 50 lines | Works fine |
| 6 months in | 200 lines | Still manageable |
| 1 year in | 500+ lines | AI skims, misses rules |
| Complex project | 1000+ lines | Critical guidance buried |

## The Solution

Instead of one massive file:

```
your-project/
├── Agents.md                    # ~60 lines - core rules, always loaded
└── .ai-guidance/                # Detailed modules, loaded on-demand
    ├── quality-gates.md         # Loaded before commits
    ├── debugging.md             # Loaded when fixing bugs
    └── architecture.md          # Loaded for design work
```

The AI reads the minimal core at session start, then loads specific modules when relevant.

**[→ How Progressive Loading Works](docs/PROGRESSIVE-LOADING.md)**

---

## Quick Start

```bash
# Clone once
git clone https://github.com/bordenet/golden-agents.git ~/.golden-agents

# Generate for your project
~/.golden-agents/generate-agents.sh --language=go --path=./my-project
```

**[→ Full Usage Guide](docs/USAGE.md)** | **[→ Sample Output](docs/SAMPLE.md)** | **[→ Windows Installation](docs/WINDOWS.md)**

---

## What's Included

| Category | Content |
|----------|---------|
| **Languages** | Go, Python, JavaScript, Shell, Dart/Flutter |
| **Project types** | CLI tools, web apps, mobile apps |
| **Workflows** | Testing, security, deployment, context management |
| **Core rules** | Quality gates, anti-slop phrases, build hygiene |

---

## vs. Other Tools

### vs. Spec Kit

| Aspect | Golden Agents | [Spec Kit](https://github.com/github/spec-kit) |
|--------|---------------|----------|
| **Focus** | HOW the AI behaves | WHAT to build |
| **Problem** | AI drift, skipped tests | Vague requirements |
| **Output** | `Agents.md` with rules | Spec→Plan→Tasks workflow |

**Use together:** Spec Kit for project structure, Golden Agents for quality enforcement.

### vs. Raw CLAUDE.md

| Aspect | Golden Agents | Manual CLAUDE.md |
|--------|---------------|------------------|
| **Scaling** | Progressive loading | Everything in one file |
| **Maintenance** | Templates updated centrally | Copy-paste across repos |
| **Size** | ~60 lines core | Grows unbounded |

---

## Supported AI Assistants

| Assistant | Config File |
|-----------|-------------|
| Claude Code | `CLAUDE.md` → `Agents.md` |
| Augment Code | Reads `Agents.md` directly |
| OpenAI Codex CLI | `CODEX.md` → `Agents.md` |
| Amp by Sourcegraph | `AGENT.md` → `Agents.md` |
| Google Gemini | `GEMINI.md` → `Agents.md` |
| GitHub Copilot | `COPILOT.md` → `Agents.md` |

The generator creates redirect files automatically.

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
| **[USAGE.md](docs/USAGE.md)** | Modes, options, examples |
| **[PROGRESSIVE-LOADING.md](docs/PROGRESSIVE-LOADING.md)** | How on-demand loading works |
| **[SUPERPOWERS.md](docs/SUPERPOWERS.md)** | Optional skill framework integration |
| **[SAMPLE.md](docs/SAMPLE.md)** | Example generated output |
| **[HOW-IT-WORKS.md](docs/HOW-IT-WORKS.md)** | Security & transparency |
| **[TEST-PLAN.md](docs/TEST-PLAN.md)** | Test strategy |
| **[REFERENCES.md](docs/REFERENCES.md)** | Best practices sources |

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
