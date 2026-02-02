# Sample Generated Output

## The Core Idea

Your AI assistant reads a ~60 line `Agents.md` at session start. When it encounters specific situations, it loads detailed guidance on-demand.

**Instead of this (800 lines the AI ignores):**

```
Agents.md: [800 lines of everything]
```

**You get this (60 lines + on-demand loading):**

```
Agents.md: [60 lines with triggers]
    ↓
"I need to write a shell script"
    ↓
AI loads: templates/languages/shell.md [100 lines, just-in-time]
```

---

## What Gets Generated

```bash
./generate-agents.sh --language=go,shell --type=cli-tools --path=./my-project
```

| File | Purpose |
|------|---------|
| `Agents.md` | Primary guidance (~60 lines) |
| `CLAUDE.md`, `CODEX.md`, etc. | Redirects for different AI assistants |

---

## The Progressive Loading Section

This is the key part. The AI sees specific triggers that tell it **when** to load **what**:

````markdown
## 🚨 Progressive Module Loading

**STOP and load the relevant module BEFORE these actions:**

### Language Modules (🔴 Required)
- 🔴 **BEFORE writing ANY `.go` file**: Read `$HOME/.golden-agents/templates/languages/go.md`
- 🔴 **BEFORE writing ANY `.sh` file or bash code block**: Read `$HOME/.golden-agents/templates/languages/shell.md`

### Workflow Modules (🔴 Required)
- 🔴 **BEFORE any commit, PR, push, or merge**: Read `$HOME/.golden-agents/templates/workflows/security.md`
- 🔴 **WHEN tests fail OR after 2+ failed fix attempts**: Read `$HOME/.golden-agents/templates/workflows/testing.md`
- 🔴 **WHEN build fails OR lint errors appear**: Read `$HOME/.golden-agents/templates/workflows/build-hygiene.md`
- 🟡 **BEFORE deploying to any environment**: Read `$HOME/.golden-agents/templates/workflows/deployment.md`
- 🟡 **WHEN conversation exceeds 50 exchanges**: Read `$HOME/.golden-agents/templates/workflows/context-management.md`

### Project type guidance:
- Read `$HOME/.golden-agents/templates/project-types/cli-tools.md`
````

### Why These Triggers Work

| Design Choice | Why It Works |
|---------------|--------------|
| 🔴 emoji | Unmistakable "must load" signal |
| "BEFORE writing ANY `.sh` file" | File extensions are unambiguous |
| "WHEN tests fail" | Discrete event the AI can't miss |
| "after 2+ failed attempts" | Clear threshold, not subjective |

---

## The Workflow Checklists Section

Always-available quick reference (no loading required):

````markdown
## Workflow Checklists

### Before Creative/Feature Work
- [ ] Clarify the problem being solved
- [ ] Identify acceptance criteria
- [ ] Explore 2-3 approaches with trade-offs

### Before Implementation (TDD Cycle)
- [ ] Write failing test
- [ ] Implement minimal code to pass
- [ ] Refactor for clarity

### Before Claiming Done
- [ ] All tests pass locally
- [ ] No linting errors
- [ ] Documentation updated if behavior changed
````

---

## What's In The Template Files?

When the AI loads a template, it gets ~100 lines of detailed, actionable guidance.

**`templates/languages/shell.md`** contains:
- `set -euo pipefail` requirements
- ShellCheck compliance rules
- BSD vs GNU compatibility notes
- Quoting and escaping patterns

**`templates/workflows/security.md`** contains:
- Secret scanning checklist
- Dependency audit commands
- Pre-commit security checks
- Common vulnerability patterns

**`templates/project-types/cli-tools.md`** contains:
- `--help` flag requirements
- Exit code conventions
- Stdin/stdout piping patterns
- Signal handling

**The AI only loads what it needs, when it needs it.**

---

## The Project-Specific Section

Your custom rules go at the bottom:

````markdown
## Project-Specific Rules

<!-- Add project-specific guidance below this line -->

### Build Commands
- `make build` - compile all binaries
- `make test` - run full test suite
- `make lint` - run all linters

### Architecture Notes
- All commands live in `cmd/`
- Shared logic lives in `internal/`
- No external dependencies without approval
````

This section is preserved during upgrades.

---

## Redirect Files

Each AI assistant has its own config file name. Golden Agents creates redirects:

````markdown
# Claude Code Instructions

See **[Agents.md](./Agents.md)** for all AI guidance.
````

Delete redirects for AI assistants you don't use.

