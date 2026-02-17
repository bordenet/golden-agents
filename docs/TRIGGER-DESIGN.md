# Trigger Design for Progressive Loading

> **The Problem:** If the AI doesn't load the right module at the right time, the entire progressive loading system fails silently.

This document defines how to write triggers that reliably fire.

---

## Trigger Failure Modes

| Failure | Example | Result |
|---------|---------|--------|
| **Too vague** | "Security concerns" | AI doesn't recognize the situation |
| **Too specific** | "When writing pre-commit hooks in bash" | Misses shell scripts in CI |
| **Passive** | "When working with Go" | AI forgets to check the table |
| **No enforcement** | Just a suggestion | AI skips it under time pressure |

## Design Principles

### 1. Use Action Verbs, Not Topics

**Bad:** `| shell.md | Shell scripting guidance |`
**Good:** `| shell.md | 🔴 BEFORE writing ANY .sh file or bash code block |`

The word "BEFORE" creates a checkpoint. The AI must pause and load.

### 2. Use Unmistakable Signals

**Bad:** "Security concerns"
**Good:** "BEFORE any commit, PR, or push to remote"

Commits, PRs, and pushes are discrete events the AI can't miss.

### 3. Use Emoji for Critical Triggers

| Emoji | Meaning |
|-------|---------|
| 🔴 | MUST load - failure here causes real problems |
| 🟡 | SHOULD load - improves quality significantly |
| 🟢 | MAY load - helpful but optional |

### 4. Make Triggers Mutually Exclusive

**Bad:**
- "When debugging" → testing.md
- "When tests fail" → testing.md
- "When fixing bugs" → testing.md

**Good:**
- "When tests fail OR you've tried 2+ approaches" → testing.md

One trigger, one module. No ambiguity.

---

## Recommended Trigger Patterns

### Language Triggers (🔴 Critical)

```markdown
| Module | Trigger |
|--------|---------|
| shell.md | 🔴 BEFORE writing ANY `.sh` file, bash code block, or shell command |
| go.md | 🔴 BEFORE writing ANY `.go` file |
| python.md | 🔴 BEFORE writing ANY `.py` file |
| javascript.md | 🔴 BEFORE writing ANY `.js`, `.ts`, `.jsx`, `.tsx` file |
```

**Why this works:** File extensions are unambiguous. The AI knows exactly when to load.

### Workflow Triggers (🔴 Critical)

```markdown
| Module | Trigger |
|--------|---------|
| security.md | 🔴 BEFORE any commit, PR, push, or merge |
| testing.md | 🔴 WHEN tests fail OR after 2+ failed fix attempts |
| build-hygiene.md | 🔴 WHEN build fails OR lint errors appear |
| deployment.md | 🟡 BEFORE deploying to any environment |
```

**Why this works:** These are discrete events with clear boundaries.

### Context Triggers (🟡 Important)

```markdown
| Module | Trigger |
|--------|---------|
| context-management.md | 🟡 WHEN conversation exceeds 50 exchanges |
| session-resumption.md | 🟡 AT START of any resumed session |
```

---

## Enforcement Mechanisms

### Option 1: Inline Reminders

Add reminders directly in the workflow checklists:

```markdown
### Before Committing
- [ ] **LOAD** `security.md` if not already loaded
- [ ] Run linter
- [ ] Run tests
- [ ] Check for secrets
```

### Option 2: Pre-Action Gates

Add explicit gates before high-risk actions:

```markdown
## 🚨 STOP Before These Actions

| Action | Required Module |
|--------|-----------------|
| `git commit` | security.md |
| `git push` | security.md |
| Creating PR | security.md |
| Writing `.sh` | shell.md |
```

### Option 3: Session Start Checklist

At the top of AGENTS.md:

```markdown
## Session Start
1. Note the primary language(s) in this project
2. Load the corresponding language module(s)
3. If resuming work, load session-resumption.md
```

---

## Testing Trigger Sensitivity

### Manual Test

1. Start a fresh AI session
2. Ask: "Add a pre-commit hook that runs linting"
3. Verify the AI loads `shell.md` before writing bash

### Automated Test (Future)

Track module loading in conversation logs and measure:
- **Trigger hit rate:** % of situations where the right module was loaded
- **False negatives:** Situations where a module should have loaded but didn't
- **False positives:** Unnecessary module loads (wastes context)

---

## Current vs. Recommended Triggers

| Current (Vague) | Recommended (Specific) |
|-----------------|------------------------|
| "When working with Go" | "🔴 BEFORE writing ANY `.go` file" |
| "Before debugging" | "🔴 WHEN tests fail OR after 2+ failed attempts" |
| "Security concerns" | "🔴 BEFORE any commit, PR, push, or merge" |
| "Build issues" | "🔴 WHEN build fails OR lint errors appear" |
| "Context overflow" | "🟡 WHEN conversation exceeds 50 exchanges" |

