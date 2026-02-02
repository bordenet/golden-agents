# AI Agent Guidelines - Golden Agents Framework

> **Last Updated**: 2026-02-01
> **Languages**: shell
> **Type**: genesis-tools (framework/tooling)

This framework generates Agents.md files for other projects. It should follow its own guidance.

---

## Workflow Checklists

### Optional: Enhanced Workflows

If [superpowers](https://github.com/obra/superpowers) is installed, run at session start:

```bash
node ~/.codex/superpowers-augment/superpowers-augment.js bootstrap
```

Otherwise, use the checklists below.

### Before Creative/Feature Work

- [ ] Clarify the problem being solved
- [ ] Identify acceptance criteria
- [ ] Explore 2-3 approaches with trade-offs
- [ ] Document decision rationale

### Before Implementation (TDD)

- [ ] Write failing test first
- [ ] Implement minimal code to pass
- [ ] Refactor for clarity
- [ ] Verify all tests pass

### When Debugging

- [ ] Gather error information
- [ ] Form hypothesis before changing code
- [ ] Test with minimal change
- [ ] Add regression test

### Before Claiming Done

- [ ] All tests pass (`bats test/`)
- [ ] ShellCheck passes (`shellcheck *.sh`)
- [ ] No secrets in code
- [ ] CHANGELOG.md updated

---

## Communication Standards

- **No flattery** - Skip "Great question!" or "Excellent point!"
- **No hype words** - Avoid "revolutionary", "game-changing", "cutting-edge"
- **Evidence-based** - Cite sources, provide data, or qualify as opinion
- **Direct** - State facts without embellishment

### Banned Phrases

| Category | Avoid |
|----------|-------|
| Self-Promotion | production-grade, world-class, enterprise-ready |
| Filler | incredibly, extremely, very, really, truly |
| AI Tells | leverage, utilize, facilitate, streamline, optimize |
| Sycophancy | Happy to help!, Absolutely!, I appreciate... |

---

## Shell Script Standards

### Required Header

```bash
#!/usr/bin/env bash
set -euo pipefail
```

### Quality Gates

1. **ShellCheck**: `shellcheck generate-agents.sh` must pass
2. **BSD compatibility**: Use flags that work on macOS (no GNU-only options)
3. **Quote variables**: Always `"$var"`, never `$var`
4. **Explicit returns**: Use `return 0` or `return 1`

### Before Committing

- [ ] `shellcheck *.sh` passes
- [ ] Tested on macOS (BSD tools)
- [ ] No hardcoded paths (use `$HOME`, `~/.golden-agents`)
- [ ] Help text updated if options changed

---

## Project Structure

```
golden-agents/
├── Agents.md              # This file (AI guidance)
├── Agents.core.md         # Pre-generated compact template
├── generate-agents.sh     # Main generator script
├── README.md              # User documentation
├── CHANGELOG.md           # Version history
└── templates/
    ├── core/              # Always-included guidance
    ├── languages/         # Language-specific (go, python, etc.)
    ├── project-types/     # Project type guidance
    └── workflows/         # Development workflow guidance
```

---

## Template Authoring

When editing templates in `templates/`:

1. **Keep modules self-contained** - No cross-references between modules
2. **Use placeholders** - `{{PROJECT_NAME}}`, `{{LANGUAGE}}` for substitution
3. **Test generation** - Run `./generate-agents.sh --dry-run` after changes
4. **Update CHANGELOG.md** - Document template changes

---

## Context Management

- **Context rot**: Model accuracy degrades as context fills. Keep tokens high-signal.
- **Progressive disclosure**: Load Agents.md always, modules on-demand.
- **Session resume**: Check `git log -5`, `git status` before proceeding.

---

## Quick Commands

```bash
# Lint shell scripts
shellcheck *.sh

# Test generation (dry run)
./generate-agents.sh --language=go --type=cli-tools --dry-run

# Generate for a project
./generate-agents.sh --language=python --path=../my-project

# Sync templates from GitHub
./generate-agents.sh --sync
```

---

*This framework eats its own dog food.*

