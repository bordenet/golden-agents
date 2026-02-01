# Golden Agents Framework

> **Standardized AI agent guidance for consistent, high-quality code generation**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## What is this?

Golden Agents is a modular framework for generating project-specific `Agents.md` files that guide AI coding assistants (Claude Code, Augment, Gemini, etc.) to produce consistent, high-quality output.

## Quick Start

### Option 1: Generate a new Agents.md

```bash
# Clone this repo
git clone https://github.com/bordenet/golden-agents.git ~/.golden-agents

# Generate for your project
~/.golden-agents/seed.sh --language=go --type=cli-tools --path=./my-project

# Or use compact mode (~130 lines instead of ~800)
~/.golden-agents/seed.sh --language=python --compact --path=./my-project
```

### Option 2: Use the pre-generated core file

```bash
# Copy the standalone Agents.md to your project
cp ~/.golden-agents/Agents.core.md ./Agents.md
```

### Option 3: Sync existing projects

```bash
# Update your local templates from GitHub
~/.golden-agents/seed.sh --sync

# Regenerate Agents.md with latest templates
~/.golden-agents/seed.sh --language=javascript --path=./my-project
```

## Features

- **Modular templates** - Mix and match languages, project types, and workflows
- **Compact mode** - 6x smaller files with essential guidance only
- **Self-contained output** - Generated files have no external dependencies
- **Sync mechanism** - Keep templates up-to-date from GitHub
- **Multi-language** - Go, Python, JavaScript, Shell, Dart/Flutter

## Directory Structure

```
golden-agents/
├── README.md              # This file
├── seed.sh                # Generator script
├── Agents.core.md         # Pre-generated compact version (standalone)
├── CHANGELOG.md           # Version history
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
./seed.sh --language=go --type=cli-tools --path=./my-cli

# Python web app
./seed.sh --language=python --type=web-apps --path=./my-api

# Flutter mobile app
./seed.sh --language=dart-flutter --type=mobile-apps --path=./my-app

# Multi-language project
./seed.sh --language=go,shell --type=cli-tools --path=./my-project

# Compact mode (recommended for most projects)
./seed.sh --language=javascript --compact --path=./my-project

# Dry run (preview without writing)
./seed.sh --language=python --compact --dry-run
```

## Integration with Superpowers

This framework integrates with [obra/superpowers](https://github.com/obra/superpowers) for AI skill management. Generated files include bootstrap instructions for:

- `superpowers:brainstorming` - Before creative work
- `superpowers:systematic-debugging` - Before fixing bugs
- `superpowers:test-driven-development` - Before implementation
- `superpowers:verification-before-completion` - Before claiming done

## Contributing

1. Fork this repository
2. Add or modify templates in `templates/`
3. Test with `./seed.sh --dry-run`
4. Submit a pull request

## License

MIT License - See [LICENSE](LICENSE) for details.

## Author

Matt J Bordenet ([@bordenet](https://github.com/bordenet))

---

*Based on [Anthropic's context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) and [Spotify's golden path](https://engineering.atspotify.com/2020/08/how-we-use-golden-paths-to-solve-fragmentation-in-our-software-ecosystem/) concepts.*

