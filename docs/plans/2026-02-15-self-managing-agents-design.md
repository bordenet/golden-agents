# Self-Managing AGENTS.md Architecture Design

> **Date:** 2026-02-15
> **Status:** Implemented (v1.4.0)
> **Author:** Matt J Bordenet (with AI assistance)

---

## 1. Problem & Solution Overview

### Problem Statement

AI coding agents working in repositories with `AGENTS.md` files have no mechanism to:
1. Detect when instruction files exceed a manageable size
2. Automatically trigger refactoring before continuing their primary task
3. Split bloated files into modular, progressively-loaded sub-files

This leads to `AGENTS.md` files growing to 200-300+ lines (as seen across all genesis-tools repos), reducing agent effectiveness and increasing context window consumption.

### Solution Overview

A self-managing architecture where:
- Agents check `AGENTS.md` line count after any edit to that file
- If over 250 lines, agents pause their primary task and refactor
- Refactoring splits content into `.ai-guidance/*.md` topic files
- A defense-in-depth loading strategy ensures critical guidance is never missed
- Zero data loss is enforced through verification steps

### Key Design Principles

1. **Platform agnostic** — Works for any AI agent (Copilot, Gemini, Claude, Codex, etc.)
2. **Zero data loss** — All project-specific guidance preserved during refactoring
3. **Convention over configuration** — Hardcoded thresholds, standard file names
4. **Defense in depth** — Multiple loading mechanisms prevent guidance gaps

---

## 2. Trigger & Detection Mechanism

### Trigger: Post-Edit Check

The self-management check triggers specifically after an agent edits `AGENTS.md` (or any `.ai-guidance/*.md` file). This timing was chosen because:

- Agents are the primary cause of instruction file bloat
- "Just in time" checking avoids constant overhead
- Makes agents responsible for their own contributions

The check does NOT run:
- At conversation start (would delay every task)
- Periodically (arbitrary timing, may interrupt mid-task)
- In real-time (excessive monitoring overhead)

### Detection: Line Count Threshold

Detection uses a simple line count check:

```bash
wc -l < AGENTS.md
```

**Threshold:** 250 lines (hardcoded in framework)

This threshold was chosen because:
- 250 lines is small enough for AI agents to handle effectively
- Line count is trivial to check and verify
- Works identically across all platforms and operating systems

### Why Not Other Metrics?

| Metric | Rejected Because |
|--------|------------------|
| Byte size | Less intuitive; line length varies |
| Section count | Complex parsing; header styles vary |
| Composite score | Over-engineered; harder to explain |

### Threshold Configuration

The 250-line threshold is hardcoded in the golden-agents framework. No per-repo configuration files are needed. This follows the "convention over configuration" principle.

---

## 3. File Structure & Modular Organization

### Directory Structure

When `AGENTS.md` exceeds 250 lines, content is split into a `.ai-guidance/` directory:

```
repo/
├── AGENTS.md                    # ≤250 lines (core + loading table)
├── .ai-guidance/
│   ├── invariants.md           # Always loaded (critical rules)
│   ├── testing.md              # On-demand (test-related tasks)
│   ├── deployment.md           # On-demand (CI/CD tasks)
│   ├── architecture.md         # On-demand (code structure)
│   └── workflows.md            # On-demand (multi-step procedures)
```

### Organization: By Topic

Content is split by topic rather than by frequency, task type, or stability. This approach:
- Mirrors how humans naturally organize documentation
- Enables intuitive grep-based loading ("working on tests → load testing.md")
- Aligns with golden-agents existing examples (`mobile-builds.md`, `api-patterns.md`)

### Standard Topic Files

| File | Contains |
|------|----------|
| `invariants.md` | Git identity, critical checks, self-management protocol |
| `testing.md` | Test commands, coverage expectations, TDD guidance |
| `deployment.md` | CI/CD configuration, release process, environment setup |
| `architecture.md` | Code patterns, directory structure, naming conventions |
| `workflows.md` | Multi-step procedures, complex task sequences |

Custom topic files are allowed (e.g., `mobile-builds.md`) for project-specific needs.

### Size Constraints

| File | Limit | Rationale |
|------|-------|-----------|
| `AGENTS.md` | ≤250 lines | Triggers refactor if exceeded |
| Each `.ai-guidance/*.md` | ≤250 lines | Keeps individual reads cheap |

---

## 4. Migration & Backward Compatibility

### Migration Scenarios

The golden-agents framework must handle three states of existing repos:

| State | Example | Current Lines | Migration Needed |
|-------|---------|---------------|------------------|
| **A. Already modular** | (Future repos) | ≤250 | None — already compliant |
| **B. Bloated, has markers** | All genesis-tools repos | 295+ | Add self-manage block + split |
| **C. Bloated, no markers** | External adopters | Varies | Run `--adopt` first, then migrate |

### Upgrade Behavior Enhancement

The existing `--upgrade` command gains automatic migration detection:

```bash
./generate-agents.sh --upgrade --path=/path/to/repo
```

**New behavior:**
1. Detect if `AGENTS.md` > 250 lines
2. Detect if `.ai-guidance/` directory exists
3. If bloated AND no `.ai-guidance/`: trigger modular migration flow

### Migration Flow

1. Create `.ai-guidance/` directory
2. Generate `invariants.md` with default self-management protocol
3. Inject 5-line self-manage bootstrap into `AGENTS.md`
4. Generate `MODULAR-MIGRATION-PROMPT.md` with split instructions
5. AI executes prompt, splits content by topic
6. Verify total lines ≤250 in `AGENTS.md`

### No New Flag Required

The `--upgrade` command auto-detects the migration scenario. Rationale:
- Reduces cognitive load (fewer flags to remember)
- "Upgrade" semantically includes "migrate to latest architecture"
- Existing `--upgrade --apply` workflow remains unchanged

---

## 5. Defense-in-Depth Loading Strategy

### Problem Addressed

If agents rely solely on a keyword table to load guidance, incomplete or stale mappings could cause critical guidance to be missed — leading to wrong git identity, skipped verification, or broken deployments.

### Four-Layer Loading Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Layer 0: ALWAYS LOAD                                      │
│  Trigger: Conversation start                               │
│  Action: Load .ai-guidance/invariants.md                   │
├─────────────────────────────────────────────────────────────┤
│  Layer 1: HIGH-RISK OPERATIONS                             │
│  Trigger: Commit, PR, deploy, agent-file edit detected     │
│  Action: Load ALL .ai-guidance/*.md files                  │
├─────────────────────────────────────────────────────────────┤
│  Layer 2: KEYWORD TABLE MATCH                              │
│  Trigger: Task matches keywords in loading table           │
│  Action: Load matched files only                           │
├─────────────────────────────────────────────────────────────┤
│  Layer 3: FILENAME INFERENCE (Fallback)                    │
│  Trigger: No Layer 2 match found                           │
│  Action: Scan .ai-guidance/ filenames for relevance        │
└─────────────────────────────────────────────────────────────┘
```

### High-Risk Operation Categories

| Category | Examples | Why Load All |
|----------|----------|--------------|
| Version control mutations | `git commit`, `git push`, `git merge` | Wrong identity pollutes history |
| PR lifecycle | Create PR, merge PR, approve | Skipped review → bad code in main |
| Deployment | `npm publish`, `deploy`, CI config edits | Skipped checks → broken production |
| Agent instruction edits | Edit `AGENTS.md`, `.ai-guidance/*` | Meta-corruption affects all future tasks |

### Keyword Table Format

```markdown
## On-Demand Guidance

| When working on... | Load |
|--------------------|------|
| tests, jest, coverage, TDD | `.ai-guidance/testing.md` |
| CI, deployment, releases | `.ai-guidance/deployment.md` |
| architecture, patterns, structure | `.ai-guidance/architecture.md` |
| workflows, multi-step tasks | `.ai-guidance/workflows.md` |
```

### Efficiency Safeguards

- **Session caching:** Files loaded once per conversation
- **Size limits:** Each sub-file ≤250 lines
- **Lazy Layer 3:** Only triggers if Layer 2 yields zero matches

---

## 6. Refactoring Workflow

### When Refactoring Triggers

After any agent edit to `AGENTS.md`, the agent runs:

```bash
wc -l < AGENTS.md
```

If result > 250, the agent MUST pause its primary task and refactor before continuing.

### Refactoring Steps

1. **PAUSE PRIMARY TASK** — Save current task context for resumption after refactor
2. **SNAPSHOT ORIGINAL CONTENT** — Copy full AGENTS.md content for zero-loss verification
3. **CREATE .ai-guidance/ IF NEEDED** — `mkdir -p .ai-guidance`
4. **CLASSIFY CONTENT BY TOPIC**
   - Critical/always-needed → `invariants.md`
   - Test-related → `testing.md`
   - CI/CD-related → `deployment.md`
   - Architecture-related → `architecture.md`
   - Multi-step procedures → `workflows.md`
5. **EXTRACT TO SUB-FILES** — Move classified content to appropriate files
6. **UPDATE LOADING TABLE** — Add/update keyword mappings in AGENTS.md
7. **VERIFY ZERO DATA LOSS** — Compare original snapshot to new structure
8. **VERIFY LINE COUNT** — Confirm AGENTS.md ≤250 lines
9. **RESUME PRIMARY TASK** — Continue original work with refactored structure

### What Can Be Removed During Refactoring

| Removable | Example |
|-----------|---------|
| Exact duplicates | Same rule stated twice |
| Framework-provided content | Rules already in golden-agents templates |
| Redundant formatting | Excessive blank lines, repeated headers |

### What Must Be Preserved

| Must Keep | Example |
|-----------|---------|
| Project-specific rules | Custom git identity, repo-specific paths |
| Team conventions | Code review requirements, naming standards |
| Custom workflows | Project-specific deployment steps |

---

## 7. Zero Data Loss Verification

### Core Principle

Refactoring is NEVER lossy. Every line of project-specific guidance in the original file must appear somewhere in the refactored output.

### Verification Checklist

Before completing any refactor, the agent MUST verify:

```markdown
## Zero Data Loss Checklist

- [ ] Original content snapshot captured before changes
- [ ] Every project-specific section accounted for
- [ ] No custom rules deleted (only moved)
- [ ] Loading table references ALL new sub-files
- [ ] Content diff shows only reorganization, not deletion
```

### Verification Method

```bash
# Step 1: Capture original content
cat AGENTS.md > /tmp/original-agents.md

# Step 2: After refactoring, concatenate all files
cat AGENTS.md .ai-guidance/*.md > /tmp/new-total.md

# Step 3: Compare project-specific content
# (Agent performs semantic comparison, not exact diff)
```

### What Counts as "Preserved"

| Status | Description | Acceptable? |
|--------|-------------|-------------|
| **Identical** | Line appears exactly as original | ✅ Yes |
| **Moved** | Line moved to different file, unchanged | ✅ Yes |
| **Reformatted** | Whitespace/formatting changed, meaning intact | ✅ Yes |
| **Condensed** | Two duplicate lines merged to one | ✅ Yes |
| **Reworded** | Meaning preserved, words changed for clarity | ⚠️ Caution |
| **Deleted** | Line removed entirely | ❌ No |

### Recovery Protocol

If verification fails:
1. Restore from original snapshot
2. Retry refactoring with more conservative splits
3. If repeated failures, leave file as-is and flag for human review

---

## 8. Bootstrap Mechanism

### The Bootstrap Problem

How does the instruction "check for bloat after editing AGENTS.md" reach the agent without itself contributing to bloat?

### Solution: Two-Part Bootstrap

The self-management capability is split between a minimal in-file block and detailed external rules.

### Part 1: In `AGENTS.md` (5 lines, framework-injected)

```markdown
<!-- GOLDEN:self-manage:start -->
## ⚠️ Before ANY Task
1. Load `.ai-guidance/invariants.md` — contains critical rules
2. After editing THIS file, run: `wc -l AGENTS.md` — if >250, refactor before continuing
<!-- GOLDEN:self-manage:end -->
```

**Why this works:**
- ANY agent reading the file sees the instruction (platform agnostic)
- Markers allow golden-agents to upgrade this section in future
- Minimal footprint (5 lines of framework overhead)

### Part 2: In `.ai-guidance/invariants.md` (detailed rules)

```markdown
# Critical Invariants — Always Follow

## Self-Management Protocol
After editing `AGENTS.md` or any `.ai-guidance/*.md` file:
1. Check: `wc -l AGENTS.md`
2. If >250 lines: STOP current task, refactor before continuing
3. Refactoring must be ZERO DATA LOSS
4. Verify total content preserved before resuming

## Zero Data Loss Verification
- Snapshot original before changes
- Compare: original vs (AGENTS.md + all .ai-guidance/*.md)
- Every project-specific line must appear somewhere
```

### Platform Agnosticism

| Requirement | How Satisfied |
|-------------|---------------|
| Works for any AI agent | Instructions are plain text in file |
| No external dependencies | Only standard file operations (`wc -l`) |
| No platform-specific config | No `~/.augment/`, no superpowers required |

### Framework Integration

The `generate-agents.sh` script automatically:
1. Injects the 5-line self-manage block into new `AGENTS.md` files
2. Adds the block during `--upgrade` for existing files
3. Creates `invariants.md` with default content during modular migration

---

## Appendix: Summary of Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Trigger | Post-edit check | Agents cause bloat; just-in-time checking |
| Detection | Line count > 250 | Simple, universal, small enough for AI to handle |
| Threshold config | Hardcoded | Convention over configuration |
| File structure | By topic | Intuitive, grep-friendly |
| Sub-file limit | 250 lines each | Keeps reads cheap |
| Loading strategy | 4-layer defense-in-depth | Prevents missed guidance |
| Always-load file | `invariants.md` | Clear convention, single file |
| High-risk operations | 4 categories | Version control, PR, deploy, agent edits |
| Bootstrap | 5-line block + invariants.md | Platform agnostic, minimal footprint |
| Migration | Auto-detect in `--upgrade` | No new flags needed |
| Data loss | Never acceptable | Verification checklist required |

