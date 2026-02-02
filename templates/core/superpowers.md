# Workflow Checklists

Use these checklists to maintain quality and consistency across all development work.

## Optional: Enhanced Workflows

If you have [superpowers](https://github.com/obra/superpowers) installed, run at session start:

```bash
node ~/.codex/superpowers-augment/superpowers-augment.js bootstrap
```

Superpowers provides interactive skill-based workflows. If not installed, use the checklists below.

---

## Before Creative/Feature Work

- [ ] Clarify the problem being solved
- [ ] Identify acceptance criteria and success metrics
- [ ] Consider edge cases and error scenarios
- [ ] Explore 2-3 approaches with trade-offs
- [ ] Document decision rationale before implementing

## Before Implementation (TDD Cycle)

- [ ] Write failing test describing desired behavior
- [ ] Implement minimal code to pass test
- [ ] Refactor for clarity and consistency
- [ ] Verify all existing tests still pass
- [ ] Repeat until feature complete

## When Debugging

- [ ] Gather complete error information (logs, stack traces)
- [ ] Identify the exact failure point
- [ ] Form hypothesis before changing code
- [ ] Test hypothesis with minimal, isolated change
- [ ] Verify fix doesn't break other functionality
- [ ] Add test to prevent regression

## Before Claiming Done

- [ ] All tests pass locally
- [ ] No linting errors or warnings
- [ ] Code reviewed (or self-reviewed against standards)
- [ ] No secrets, credentials, or sensitive data in code
- [ ] Documentation updated if behavior changed
- [ ] Commit messages are descriptive

## Before Creating PR or Merging

- [ ] Branch is up to date with target branch
- [ ] CI pipeline passes
- [ ] Changes match the original requirements
- [ ] No unrelated changes included

## When Stuck (2+ Failed Attempts)

- [ ] Step back and re-read the error message carefully
- [ ] Search documentation or reliable sources
- [ ] Ask the user for clarification if requirements are unclear
- [ ] Consider if the approach itself is wrong, not just the implementation
