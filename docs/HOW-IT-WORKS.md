# How Golden Agents Works

> **TL;DR:** Golden Agents generates **text files** (Markdown) that AI coding assistants read as instructions. It does NOT execute code, install software, modify your system, or run autonomously. The shell script is a simple text generator.

---

## What This Project Actually Does

Golden Agents is a **documentation generator**. It creates `Agents.md` files—plain Markdown text—that AI coding assistants (Claude Code, GitHub Copilot, Augment, etc.) read when you open a project.

```
┌─────────────────────────────────────────────────────────────────────┐
│                    WHAT GOLDEN AGENTS DOES                          │
└─────────────────────────────────────────────────────────────────────┘

    You run:                        It creates:
    ┌──────────────────┐            ┌──────────────────┐
    │ generate-agents  │ ────────▶  │ Agents.md        │
    │ .sh              │            │ (text file)      │
    └──────────────────┘            └──────────────────┘
           │                               │
           │                               │
           ▼                               ▼
    Reads template                  AI assistant reads
    files (text)                    this when you chat
```

**That's it.** The script reads template files, concatenates them based on your options, and writes a Markdown file to your project directory.

---

## What The Shell Script Does (And Doesn't Do)

### ✅ What `generate-agents.sh` DOES:

1. **Reads command-line arguments** (`--language=go`, `--path=./my-project`)
2. **Reads template files** from `templates/` directory (plain text)
3. **Concatenates text** based on your selections
4. **Writes a Markdown file** (`Agents.md`) to your project
5. **Optionally creates redirect files** (`CLAUDE.md`, `GEMINI.md`) that point to `Agents.md`

### ❌ What `generate-agents.sh` DOES NOT DO:

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

The generated `Agents.md` is a **plain text file** containing:

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
2. **The AI assistant** (Claude Code, Copilot, etc.) automatically reads `Agents.md`
3. **The AI** uses these instructions to guide its responses
4. **You** interact with the AI as normal

```
┌─────────────────────────────────────────────────────────────────────┐
│                    HOW AI ASSISTANTS USE AGENTS.MD                  │
└─────────────────────────────────────────────────────────────────────┘

    ┌──────────────┐     reads      ┌──────────────┐
    │ AI Assistant │ ◀───────────── │ Agents.md    │
    │ (Claude,     │                │ (text file)  │
    │  Copilot)    │                └──────────────┘
    └──────────────┘
           │
           │ responds to
           ▼
    ┌──────────────┐
    │ You (human)  │
    │ asking       │
    │ questions    │
    └──────────────┘
```

The AI assistant is **already running** in your editor. Golden Agents doesn't start it, control it, or interact with it. We just create a text file it reads.

---

## Security Model

### No Elevated Privileges Required

- The script runs as your normal user
- No `sudo`, no admin rights, no special permissions
- Only writes to the directory you specify with `--path`

### No Network Access

- The script is entirely offline
- No telemetry, no analytics, no phone-home
- No external dependencies to download

### No Persistence

- Runs once, creates files, exits
- No background processes
- No scheduled tasks or cron jobs
- No startup scripts

### Fully Auditable

- The entire script is ~600 lines of Bash
- All templates are plain Markdown files
- No minified code, no binaries, no obfuscation
- MIT licensed, fully open source

---

## Why Shell Scripts?

We use shell scripts because:

1. **Transparency** - You can read every line of code
2. **No dependencies** - Works with just Bash and Git (already on your system)
3. **No installation** - Clone and run, nothing to install
4. **Cross-platform** - Works on Linux, macOS, Windows (WSL/Git Bash)

---

## Comparison: What We Are vs. What We're Not

| Aspect | Golden Agents | Malware/Suspicious Software |
|--------|---------------|----------------------------|
| **Purpose** | Generate documentation | Harm, steal, or control |
| **Execution** | Runs once when you invoke it | Runs persistently/hidden |
| **Output** | Text files only | Modifies system, installs software |
| **Network** | None | Phones home, exfiltrates data |
| **Privileges** | Normal user | Requests admin/root |
| **Transparency** | Fully readable source | Obfuscated/encrypted |
| **Persistence** | None | Startup scripts, services |

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

