# Modular Migration Prompt

> **MISSION:** Refactor a bloated AGENTS.md (>250 lines) into a modular structure using `.ai-guidance/` sub-files.
>
> This file was created because your AGENTS.md exceeds the 250-line limit.
> AI agents struggle with long instruction files — they drift and miss important rules.

## Success Criteria

| Component | Limit |
|-----------|-------|
| `AGENTS.md` (root file) | ≤250 lines |
| Each `.ai-guidance/*.md` sub-file | ≤250 lines |
| Total content | ZERO data loss |

**If AGENTS.md still exceeds 250 lines after migration, continue extracting content.**

## Directory Structure

After migration, you should have:

```
project/
├── AGENTS.md              # ≤250 lines, references sub-files
├── .ai-guidance/
│   ├── invariants.md      # Critical rules (provided)
│   ├── domain-rules.md    # Project-specific domain logic
│   ├── team-policies.md   # Team conventions, review policies
│   └── [topic].md         # Additional topic-specific files
```

## Classification Rules

### What Goes in AGENTS.md (Root File)

- Header metadata (generator, languages, type)
- Self-management bootstrap block
- Framework section (between GOLDEN markers)
- Loading table referencing `.ai-guidance/` files
- Brief project overview (≤10 lines)

### What Goes in .ai-guidance/ Sub-Files

| File | Content |
|------|---------|
| `invariants.md` | Self-management protocol, zero data loss rules |
| `domain-rules.md` | Business logic, data formats, API contracts |
| `team-policies.md` | PR review requirements, deployment policies |
| `architecture.md` | System structure, key abstractions |
| `testing.md` | Test patterns, fixtures, coverage rules |

**Create only files you need.** Don't create empty placeholders.

## Zero Data Loss Checklist

Before completing migration:

- [ ] Snapshot original: `cat AGENTS.md > /tmp/original-agents.md`
- [ ] Every section from original exists somewhere in new structure
- [ ] No rules deleted — only reorganized
- [ ] `diff /tmp/original-agents.md <(cat AGENTS.md .ai-guidance/*.md)` shows no lost content
- [ ] All custom commands, paths, and policies preserved

## Migration Process

### Step 1: Analyze Current Content

Count lines and identify sections:

```bash
wc -l AGENTS.md
grep "^##" AGENTS.md
```

### Step 2: Classify Each Section

For each section after `<!-- GOLDEN:framework:end -->`:

1. Is it domain-specific? → `domain-rules.md`
2. Is it team policy? → `team-policies.md`
3. Is it architecture? → `architecture.md`
4. Is it testing-specific? → `testing.md`
5. Is it generic guidance? → Likely redundant, verify before deleting

### Step 3: Create Sub-Files

For each category with content:

```bash
mkdir -p .ai-guidance
# Create file with header and content
```

### Step 4: Update AGENTS.md Loading Table

Add after the framework end marker:

```markdown
## On-Demand Module Loading

| Trigger | Load |
|---------|------|
| BEFORE any task | `.ai-guidance/invariants.md` |
| WHEN editing domain logic | `.ai-guidance/domain-rules.md` |
| BEFORE creating PR | `.ai-guidance/team-policies.md` |
```

### Step 5: Verify

```bash
wc -l AGENTS.md                    # Must be ≤250
wc -l .ai-guidance/*.md            # Each must be ≤250
```

### Step 6: Clean Up

Remove migration artifacts:

```bash
rm MODULAR-MIGRATION-PROMPT.md
git add AGENTS.md .ai-guidance/
git commit -m "refactor: modularize AGENTS.md into .ai-guidance/"
```

## Recovery

If something goes wrong:

```bash
cp /tmp/original-agents.md AGENTS.md
rm -rf .ai-guidance/
```

---

**DELETE THIS FILE** after migration is complete and committed.

