# How Golden Agents Works

> **TL;DR:** Golden Agents generates instruction files that AI coding assistants read. The generator script only creates text files. But the AI assistant that reads those files **will modify your code** — that's the whole point.

---

## Two Separate Things

There are two distinct components:

1. **The generator script** (`generate-agents.sh`) — Creates text files. Safe, auditable, no side effects.
2. **Your AI coding assistant** — Reads those files and acts on them. **Will modify your project files.**

```
generate-agents.sh          AGENTS.md              Your AI assistant
Creates text files    ->    Instructions for AI -> Modifies project files
Safe, auditable             Plain text             Real changes
No side effects             No executable code     Writes code
Runs once, exits            Just guidelines        Runs commands
```

**Be clear about this:** When you tell your AI assistant to "set up golden-agents and apply it," the AI will:
- Clone repositories
- Create and modify files
- Run shell commands
- Make commits (if you allow it)

This is normal and expected. That's what AI coding assistants do.

---

## What The Shell Script Does (And Doesn't Do)

### ✅ What `generate-agents.sh` DOES

1. **Reads command-line arguments** (`--language=go`, `--path=./my-project`)
2. **Reads template files** from `templates/` directory (plain text)
3. **Concatenates text** based on your selections
4. **Writes a Markdown file** (`AGENTS.md`) to your project
5. **Writes import files** (`CLAUDE.md` and `GEMINI.md` are `@AGENTS.md`; Copilot's file is `@../AGENTS.md`)

### ❌ What `generate-agents.sh` DOES NOT DO

- ❌ Execute any code in your project
- ❌ Install packages or dependencies
- ❌ Modify system files or settings
- ❌ Connect to the internet or external services
- ❌ Run in the background or as a daemon
- ❌ Access credentials, tokens, or secrets
- ❌ Spawn processes or subshells that persist
- ❌ Modify any files except the ones it explicitly creates

---

## The Output: Just Text Files

The generated `AGENTS.md` is a **plain text file** containing:

- Coding style guidelines
- Quality gate checklists (lint, build, test)
- Language-specific conventions
- Anti-slop rules (phrases to avoid)

**Example output (abbreviated):**

```markdown
# AI Agent Guidelines

## Quality Gates
Before ANY commit:
1. Run linter: `golangci-lint run`
2. Run build: `go build ./...`
3. Run tests: `go test ./...`

## Anti-Slop Rules
Never use: "revolutionary", "seamless", "Happy to help!"
```

This file has **no executable content**. It's instructions that an AI assistant reads—the same way a human developer would read a `CONTRIBUTING.md` file.

---

## How AI Assistants Use These Files

When you open a project in an AI-enabled editor:

1. **You** open your project folder
2. **The AI assistant** (Claude Code, Copilot, etc.) automatically reads `AGENTS.md`
3. **The AI** follows these instructions when you ask it to do things
4. **The AI modifies your files** based on your requests + the guidance

```
AI assistant (Claude, Copilot)  reads  AGENTS.md (text file)
        |
        writes code, runs commands
        v
Your project files get modified
```

**Important:** The AI assistant will modify your project files. That's the point. The `AGENTS.md` file just influences *how* it does so (coding style, quality gates, etc.).

---

## Security Model

### The Generator Script (`generate-agents.sh`)

The script itself is safe and auditable:

| Property | Status |
|----------|--------|
| Elevated privileges | ❌ Not required — runs as normal user |
| Network access | Only `--sync`: `git fetch origin main`, then fast-forward only; all other modes are offline |
| Persistence | ❌ None — runs once, exits |
| Side effects | ✅ Creates text files only |
| Auditable | ✅ ~1000 lines of readable Bash |

### Your AI Assistant (Separate Concern)

Your AI coding assistant is a different story. When it reads `AGENTS.md` and you ask it to do work:

| Action | Will It Happen? |
|--------|-----------------|
| Read your project files | ✅ Yes |
| Write/modify code files | ✅ Yes |
| Run shell commands | ✅ Yes (lint, build, test) |
| Create commits | ⚠️ If you allow it |
| Push to remote | ⚠️ If you allow it |
| Install dependencies | ⚠️ If you ask it to |

**This is normal.** That's what AI coding assistants do. The `AGENTS.md` file just provides guidelines for *how* the AI should work — it doesn't limit *what* the AI can do.

### Controlling Your AI Assistant

Most AI coding assistants have permission controls:

- **Claude Code**: Asks before running commands, can be set to auto-approve
- **GitHub Copilot**: Suggests code, you accept or reject
- **Augment**: Configurable approval settings

Golden Agents doesn't change these controls. Your AI assistant's existing permission model still applies.

---

## Verify For Yourself

Before running, you can audit everything:

```bash
# Read the main script
cat generate-agents.sh

# Read all templates
cat templates/**/*.md

# Check what files would be created (dry run)
./generate-agents.sh --dry-run --language=go --path=./test-project
```

The `--dry-run` flag shows exactly what would be created without writing anything.

---

## Questions?

If you have security concerns or questions about how this works, please [open an issue](https://github.com/bordenet/golden-agents/issues). We take transparency seriously.

