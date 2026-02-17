# Superpowers Integration

> **Priority**: CRITICAL - Configure at session start
> **Source**: obra/superpowers, bordenet/superpowers-plus, RecipeArchive AGENTS.md

## Superpowers Bootstrap

At the **START of every conversation**, run:

```bash
node ~/.codex/superpowers-augment/superpowers-augment.js bootstrap
```

This loads available skills from:
- **obra/superpowers** - Core skills: brainstorming, TDD, debugging, verification
- **bordenet/superpowers-plus** - Extended skills: slop detection, security upgrades, code review

To load a specific skill:
```bash
node ~/.codex/superpowers-augment/superpowers-augment.js use-skill superpowers:<skill-name>
```

## The Rule

**IF A SKILL APPLIES TO YOUR TASK (even 1% chance), YOU MUST INVOKE IT.**

This is not optional. Skills exist to ensure quality and consistency.

## Critical Checkpoints

**STOP and verify skill applicability before these actions:**

| Action | Required Check | Skill to Consider |
|--------|----------------|-------------------|
| Creating a branch | Did I invoke code review? | `superpowers:requesting-code-review` |
| Creating a PR | Did I invoke code review? | `superpowers:requesting-code-review` |
| Pushing to main | Did I verify completion? | `superpowers:verification-before-completion` |
| Starting feature work | Did I brainstorm first? | `superpowers:brainstorming` |
| Fixing a bug | Did I debug systematically? | `superpowers:systematic-debugging` |
| Writing implementation | Did I write tests first? | `superpowers:test-driven-development` |
| Claiming "done" | Did I run verification? | `superpowers:verification-before-completion` |

## Key Skills Reference

| Skill | When to Use |
|-------|-------------|
| `superpowers:brainstorming` | Before ANY creative/feature work |
| `superpowers:systematic-debugging` | Before fixing bugs |
| `superpowers:test-driven-development` | Before writing implementation |
| `superpowers:verification-before-completion` | Before claiming done |
| `superpowers:writing-plans` | Before multi-step tasks |
| `superpowers:requesting-code-review` | Before PRs or merging |

## Perplexity Escalation

**After 5 minutes OR 3 failed attempts**, escalate:

1. Stop trying to fix manually
2. Generate a Perplexity prompt with:
   - Exact error message
   - Version info (language, framework)
   - What you've already tried
3. Research before more attempts

## Fallback Checklists (Without Superpowers)

If superpowers not installed, use these minimal checklists:

### Before Implementation
- [ ] Write failing test first
- [ ] Implement minimal code to pass
- [ ] Refactor while keeping tests green

### Before Claiming Done
- [ ] All tests pass locally
- [ ] No linting errors
- [ ] No secrets in code
- [ ] Documentation updated

### When Stuck
- [ ] Re-read error message carefully
- [ ] Search documentation
- [ ] Ask user for clarification if needed
