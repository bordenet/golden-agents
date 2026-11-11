# Critical Invariants — Always Follow

> **Load at START of every conversation.**

## GitHub from a container

Before any GitHub commit, branch change, or pull request, read `.ai-guidance/github-ops.md`. The container is not the user's machine. Do not drive its browser. `gh api --method DELETE` from a terminal requires `--input /dev/null`.

## Self-Management Protocol

After editing ANY guidance file, run: `wc -l AGENTS.md .ai-guidance/*.md 2>/dev/null`

| File | Limit | Action if exceeded |
|------|-------|-------------------|
| `AGENTS.md` | 250 lines | Extract to `.ai-guidance/*.md` |
| `.ai-guidance/*.md` | 250 lines | Split into sub-directory |

**If threshold exceeded:** STOP → Refactor (zero data loss) → Verify → Resume. The size cap exists so agents do not grow the file they are reading.

## Zero Data Loss Checklist

- [ ] Snapshot captured: `cat <file> > /tmp/original.md`
- [ ] Every section accounted for in new structure
- [ ] No rules deleted (only moved/split)
- [ ] Diff shows reorganization, not deletion

## Refactoring Steps

**AGENTS.md → .ai-guidance/:**
1. Snapshot → `mkdir -p .ai-guidance` → Classify by topic
2. Extract to sub-files (≤250 lines each) → Update loading table
3. Verify: `wc -l AGENTS.md` ≤250

**Sub-file → sub-directory** (e.g., `testing.md` exceeds 250 lines):
1. `mkdir -p .ai-guidance/testing`
2. Split into topic files (`unit.md`, `integration.md`, etc.)
3. Replace original with index referencing sub-files
4. Verify: each file ≤250 lines

**Recovery:** If verification fails, restore from `/tmp/original.md`

