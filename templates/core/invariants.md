# Critical Invariants — Always Follow

> **Load this file at the START of every conversation.**

## Self-Management Protocol

After editing `Agents.md` or any `.ai-guidance/*.md` file:

1. **Check line count:** `wc -l Agents.md`
2. **If >150 lines:** STOP current task, refactor before continuing
3. **Refactoring must be ZERO DATA LOSS**
4. **Verify total content preserved** before resuming original task

## Zero Data Loss Verification

Before completing any refactor:

- [ ] Original content snapshot captured
- [ ] Every project-specific section accounted for
- [ ] No custom rules deleted (only moved)
- [ ] Content diff shows reorganization, not deletion

## Refactoring Steps

1. Snapshot original: `cat Agents.md > /tmp/original.md`
2. Create directory: `mkdir -p .ai-guidance`
3. Classify content by topic
4. Extract to sub-files (≤50 lines each)
5. Update loading table in Agents.md
6. Verify: all original content exists in new structure
7. Confirm: `wc -l Agents.md` ≤150

## Recovery

If verification fails: `cp /tmp/original.md Agents.md`

