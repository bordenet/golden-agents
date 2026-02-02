# Golden Agents Adoption - Deduplication Prompt

> **MISSION:** Produce a minimal, high-signal Agents.md that AI assistants can follow faithfully.
>
> 800 lines of guidance is too much — AI agents drift and ignore bloated instructions.
> Your job is to **aggressively deduplicate** while preserving only what's truly unique to this project.

## Success Criteria

After deduplication, the `## Project-Specific Guidelines` section should be:

| Project Complexity | Target Size |
|-------------------|-------------|
| Simple (single language, standard tooling) | **0-20 lines** |
| Moderate (multi-language, some custom workflows) | **20-50 lines** |
| Complex (many integrations, strict domain rules) | **50-100 lines** |

**If your result exceeds 100 lines, you kept too much. Re-evaluate.**

## The Principle

The framework already provides:
- Superpowers integration and skill invocation
- Language-specific conventions (Go, Python, JS, Shell, Dart)
- Testing standards and coverage requirements
- Git workflow and commit conventions
- Anti-slop rules and communication standards
- Build hygiene (lint → build → test order)

**You should ONLY keep content that:**
1. Contains project-specific paths, commands, or scripts
2. Names specific tools, services, or APIs unique to this project
3. Defines team policies not covered by the framework
4. Specifies domain rules that an outsider wouldn't know

**Everything else is redundant. Delete it.**

## Classification Rules

### DELETE Aggressively (Redundant)

| Category | Examples to DELETE |
|----------|-------------------|
| **Testing guidance** | "Write tests", "Maintain coverage", "Test before commit" |
| **Git conventions** | "Use feature branches", "Write clear commit messages", "Conventional commits" |
| **Code style** | "Use descriptive names", "Keep functions small", "Follow language conventions" |
| **AI instructions** | "Bootstrap superpowers", "Use skills", "Verify before completing" |
| **Quality gates** | "Run linter", "Fix warnings", "Build must pass" |
| **Generic best practices** | "Document your code", "Handle errors", "Log appropriately" |

**If it sounds like advice that applies to ANY project, DELETE IT.**

### KEEP Sparingly (Project-Specifics Only)

| Category | Examples to KEEP |
|----------|-----------------|
| **Paths & directories** | "`/src/api/` contains all REST handlers", "Config in `.env.local`" |
| **Commands** | "`npm run build:prod`", "`./scripts/deploy-staging.sh`" |
| **Named services** | "PostgreSQL 14 via PgBouncer", "Redis for session cache" |
| **Team policies** | "2 approvals required", "@backend-team reviews API changes" |
| **Domain rules** | "Prices in cents, never dollars", "User IDs are UUIDs, never ints" |
| **API contracts** | "All endpoints return `{data, error, meta}` envelope" |

**If you can't point to a specific name, path, command, or policy — it's probably redundant.**

### The 10-Word Test

For each piece of content, ask: *"Can I express this project-specific info in under 10 words?"*

- ✅ "Tests in `/tests/unit/` and `/tests/e2e/`" — KEEP (8 words, specific paths)
- ✅ "Deploy with `make deploy-prod`" — KEEP (4 words, specific command)
- ✅ "PRs need 2 approvals from @platform-team" — KEEP (6 words, specific policy)
- ❌ "Always write comprehensive tests for new features" — DELETE (generic advice)
- ❌ "Follow best practices for error handling" — DELETE (no specifics)
- ❌ "Use meaningful variable names" — DELETE (framework covers this)

## Process

### Step 1: Verify Structure

Confirm these exist in `Agents.md`:
- `<!-- GOLDEN:framework:start -->` marker
- `<!-- GOLDEN:framework:end -->` marker
- Project-specific section after the end marker (may be titled `## Preserved Project Content`, `## Project-Specific Rules`, `## Project-Specific Guidelines`, or similar)

If markers are missing, STOP and report.

### Step 2: Extract Project-Specifics

Scan the preserved content. For each item, apply the 10-word test:
- Can you express it in under 10 words with specific names/paths/commands?
- YES → Candidate to KEEP
- NO → Candidate to DELETE

### Step 3: Show Proposed Result

**Before making changes**, show what the final section will look like:

```
## Project-Specific Guidelines

[Show the minimal, deduplicated content here — aim for under 50 lines]
```

Include a summary:

```
DEDUPLICATION SUMMARY
━━━━━━━━━━━━━━━━━━━━━
Original preserved content: ~[X] lines
After deduplication: ~[Y] lines
Reduction: [Z]%

Deleted [N] redundant items (generic guidance covered by framework)
Kept [M] project-specific items (paths, commands, policies, domain rules)
```

### Step 4: Wait for Approval

Present the proposed result and wait for:
- "Approved" → Apply changes
- "Keep [item]" → Add it back
- "Delete [item]" → Remove it
- "Cancel" → Stop without changes

### Step 5: Apply Changes

After approval:
1. Rename the project section to `## Project-Specific Guidelines` (if not already named that)
2. Replace the content with the approved minimal version
3. Remove any migration notes or preserved content headers
4. Verify framework markers are untouched

### Step 6: Confirm Completion

```
ADOPTION COMPLETE
━━━━━━━━━━━━━━━━━
Final section size: [X] lines
Framework markers: INTACT
Status: READY FOR COMMIT

Next: Delete this ADOPT-PROMPT.md and commit Agents.md
```

## Safety Net

### Confidence Levels

When uncertain about an item:
- **HIGH confidence** → Delete or keep as classified
- **MEDIUM confidence** → Include in preview, note your uncertainty
- **LOW confidence** → Default to KEEP, flag for human decision

**Rule:** When genuinely uncertain, keep it. A slightly longer file is better than lost information.

### If Something Goes Wrong

The original content is preserved in `Agents.md.original`. To restore:

```bash
# View what was lost
diff Agents.md Agents.md.original

# Full restore
cp Agents.md.original Agents.md
```

### Red Flags — Stop and Ask

- Preserved section has complex domain logic you don't understand
- Multiple items reference the same system in different ways
- Content looks auto-generated or templated
- You're unsure if something is a project name or generic term

---

## Remember

> **The goal is a minimal, high-signal file that AI assistants will actually follow.**
>
> Generic advice gets ignored. Specific instructions get followed.
>
> When in doubt: Is this specific enough that an AI needs to know it for THIS project?
> If not, the framework already covers it. Delete it.

---

**DELETE THIS FILE** after deduplication is complete and committed.

