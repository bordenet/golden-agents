# Progressive Loading

**The Problem:** Large AGENTS.md files (500+ lines) waste context tokens and cause AI assistants to miss critical rules buried in walls of text.

**The Solution:** Load guidance on-demand based on what the AI is actually doing.

## How It Works

```
┌────────────────────────────────────────────────────────────────────┐
│                        SESSION START                                 │
└────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌────────────────────────────────────────────────────────────────────┐
│  1. AI READS AGENTS.md (~60-100 lines)                              │
│     • Workflow checklists (always active)                            │
│     • Anti-slop rules (always active)                                │
│     • Quality gates (quick reference)                                │
│     • Progressive loading table with triggers                        │
└────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌────────────────────────────────────────────────────────────────────┐
│  2. AI IDENTIFIES TASK TYPE                                          │
│     User: "Add a pre-commit hook to run linting"                     │
│     AI thinks: "This is shell scripting → need shell.md"             │
└────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌────────────────────────────────────────────────────────────────────┐
│  3. AI LOADS RELEVANT MODULE                                         │
│     `view .golden-agents/modules/shell.md`                           │
│     → Now has ShellCheck rules, set -euo pipefail, portability...    │
└────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌────────────────────────────────────────────────────────────────────┐
│  4. AI EXECUTES TASK with full context                               │
│     Follows shell conventions, handles BSD/GNU differences...        │
└────────────────────────────────────────────────────────────────────┘
```

## Module Loading Table Pattern

The key to successful progressive loading is a **clear loading table** with explicit triggers:

```markdown
## 🚨 CRITICAL: Progressive Guidance Modules

| Module | When to Load | Command |
|--------|--------------|---------|
| **shell.md** | 🔴 Writing bash/shell scripts | `view .golden-agents/modules/shell.md` |
| **testing.md** | Writing or fixing tests | `view .golden-agents/modules/testing.md` |
| **security.md** | Before commits or PRs | `view .golden-agents/modules/security.md` |
```

**Critical success factors:**
- 🔴 Mark critical modules with emoji/color
- Use action words: "Before", "When", "During"
- One module per task type (don't make AI load 5 files)
- Keep module names descriptive

## The `.ai-guidance/` Pattern

For projects with extensive project-specific documentation:

```
your-repo/
├── AGENTS.md                           # ~60-100 lines (quick ref + loading table)
└── .ai-guidance/
    ├── mobile-builds.md                # iOS/Android build details
    ├── architecture.md                 # System architecture
    └── security-protocols.md           # Security requirements
```

The generator copies the modules a project selected into `.golden-agents/modules/`. Project-specific notes stay in `.ai-guidance/`.

## Why This Works

This pattern is inspired by on-demand skill loading (e.g., [obra/superpowers](https://github.com/obra/superpowers)):

| Aspect | Skill Frameworks | golden-agents |
|--------|------------------|---------------|
| **Bootstrap** | Load available skills | Reads AGENTS.md |
| **Detail** | `use-skill debugging` | `view .ai-guidance/debugging.md` |
| **Trigger** | Skill description says when | Loading table says when |
| **Loading** | On-demand per task | On-demand per task |

The key insight: **describe WHEN to load in the description/table**, not just WHAT the content is.

**Bad:** `| debugging.md | Debugging guidance |`
**Good:** `| debugging.md | When you've tried 2+ approaches without success |`

> **Note:** Golden Agents works standalone. Superpowers integration is optional—see [SUPERPOWERS.md](SUPERPOWERS.md).

