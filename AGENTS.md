# AI Agent Guidelines - Golden Agents Framework

> **Last Updated**: 2026-02-02
> **Purpose**: Teach AI assistants how to USE this framework to apply AI guidance to other repos

---

## 🚨 CRITICAL: How to Use This Framework

**You are an AI assistant reading this file.** This repo contains tools that generate `AGENTS.md` files for OTHER projects. When a user asks you to "apply golden-agents" or "set up AI guidance" for a repo, follow these instructions.

### Step 1: Determine the Target Repo's State

Run the generator with `--path` pointing to the target repo:

```bash
# From this repo's directory (e.g., ~/.golden-agents or wherever cloned)
./generate-agents.sh --path=/path/to/target/repo --dry-run
```

The script will auto-detect the situation and tell you what to do.

### Step 2: Follow the Script's Guidance

| Situation | Script Output | Your Action |
|-----------|---------------|-------------|
| **No AGENTS.md** | Prompts for `--language` | Run with language flag, review output |
| **Existing CLAUDE.md/CODEX.md** | Suggests `--migrate` | Run migrate, then execute the generated prompt |
| **Existing AGENTS.md (no markers)** | Suggests `--adopt` | Run adopt, then execute the generated prompt |
| **Existing AGENTS.md (with markers)** | Suggests `--upgrade` | Run upgrade preview, then `--apply` if good |
| **Bloated AGENTS.md (>250 lines)** | Suggests `--dedupe` | Run dedupe, then execute the generated prompt |

### Step 3: Execute Generated Prompts

**THIS IS CRITICAL.** The scripts generate prompt files (e.g., `MIGRATION-PROMPT.md`, `ADOPT-PROMPT.md`) that YOU must read and execute.

```bash
# After running --migrate or --adopt or --dedupe:
cat /path/to/target/repo/MIGRATION-PROMPT.md  # or ADOPT-PROMPT.md
```

**Read the prompt file and follow its instructions.** These prompts guide you through:
- Deduplicating content
- Preserving project-specific guidance
- Removing redundant framework content
- Organizing into the right structure

### Step 4: Verify Zero Data Loss

After applying changes, verify:

1. **All original content preserved** - Nothing from the original file was lost
2. **Size within limits** - Progressive mode ≤250 lines, Compact ≤200 lines
<!-- GOLDEN:self-manage:start -->
## ⚠️ Before ANY Task
1. Load `.ai-guidance/invariants.md` — contains critical rules
2. After editing ANY guidance file, check: `wc -l AGENTS.md .ai-guidance/*.md 2>/dev/null`
   - `AGENTS.md` >250 lines → refactor into `.ai-guidance/`
   - Any `.ai-guidance/*.md` >250 lines → split into sub-directory
<!-- GOLDEN:self-manage:end -->
<!-- GOLDEN:framework:start -->

---

## Quality Gates (MANDATORY)

Before ANY commit:
1. **Lint**: `shellcheck *.sh`
2. **Build**: `bash -n *.sh`
3. **Test**: `bats test/`
4. **Coverage**: Minimum N/A%

**Order matters.** Lint → Build → Test. Never skip steps.

---

## Communication Rules

- **No flattery** - Skip "Great question!" or "Excellent point!"
- **No hype** - Avoid "revolutionary", "game-changing", "seamless"
- **Evidence-based** - Cite sources or qualify as opinion
- **Direct** - State facts without embellishment

**Banned phrases**: production-grade, world-class, leverage, utilize, incredibly, extremely, Happy to help!

---

## 🚨 Progressive Module Loading

**STOP and load the relevant module BEFORE these actions:**

### Language Modules (🔴 Required)
- 🔴 **BEFORE writing ANY `.sh` file or bash code block**: Read `$HOME/.golden-agents/templates/languages/shell.md`

### Workflow Modules (🔴 Required)
- 🔴 **BEFORE any commit, PR, push, or merge**: Read `$HOME/.golden-agents/templates/workflows/security.md`
- 🔴 **WHEN tests fail OR after 2+ failed fix attempts**: Read `$HOME/.golden-agents/templates/workflows/testing.md`
- 🔴 **WHEN build fails OR lint errors appear**: Read `$HOME/.golden-agents/templates/workflows/build-hygiene.md`
- 🟡 **BEFORE deploying to any environment**: Read `$HOME/.golden-agents/templates/workflows/deployment.md`
- 🟡 **WHEN conversation exceeds 50 exchanges**: Read `$HOME/.golden-agents/templates/workflows/context-management.md`

### Optional: Superpowers integration

If [superpowers](https://github.com/obra/superpowers) is installed, run at session start:

```bash
node ~/.codex/superpowers-augment/superpowers-augment.js bootstrap
```

<!-- GOLDEN:framework:end -->

---

## Command Reference

### For New Projects (No AGENTS.md)

```bash
./generate-agents.sh --language=go --path=/path/to/repo
./generate-agents.sh --language=python,shell --type=cli-tools --path=/path/to/repo
```

### For Existing CLAUDE.md/CODEX.md (Migration)

```bash
./generate-agents.sh --migrate --path=/path/to/repo
# Then read and execute: /path/to/repo/MIGRATION-PROMPT.md
```

### For Existing AGENTS.md Without Markers (Adoption)

```bash
./generate-agents.sh --adopt --language=go --path=/path/to/repo
# Then read and execute: /path/to/repo/ADOPT-PROMPT.md
```

### For Existing AGENTS.md With Markers (Upgrade)

```bash
./generate-agents.sh --upgrade --path=/path/to/repo          # Preview
./generate-agents.sh --upgrade --apply --path=/path/to/repo  # Apply
```

### For Bloated Files (Deduplication)

```bash
./generate-agents.sh --dedupe --path=/path/to/repo
# Then read and execute: /path/to/repo/ADOPT-PROMPT.md
```

---

## Example Workflow

User says: "Apply golden-agents to my recipe-app repo"

```bash
# 1. Check current state
./generate-agents.sh --path=../recipe-app --dry-run

# Output: "Found existing CLAUDE.md (584 lines). Use --migrate to preserve content."

# 2. Run migration
./generate-agents.sh --migrate --path=../recipe-app

# Output: "Created MIGRATION-PROMPT.md with instructions"

# 3. Read and execute the prompt
cat ../recipe-app/MIGRATION-PROMPT.md
# Follow the instructions in the prompt to:
# - Review the original content
# - Identify project-specific vs framework content
# - Create the new AGENTS.md with proper structure
# - Verify zero data loss

# 4. Verify result
wc -l ../recipe-app/AGENTS.md  # Should be ≤250 lines for progressive
grep "GOLDEN:framework" ../recipe-app/AGENTS.md  # Should find markers
```

---

## For Complex Projects (>250 Lines of Project-Specific Content)

If a project has extensive project-specific guidance that can't fit in 250 lines:

1. Create `.ai-guidance/` directory in target repo
2. Split content into focused modules (e.g., `mobile-builds.md`, `api-patterns.md`)
3. Reference modules from main AGENTS.md with on-demand loading table

See `templates/core/superpowers.md` for the module loading pattern.

---

## When Developing THIS Framework

### Quality Gates

```bash
# Run all tests (115 BATS tests)
bats test/*.bats

# Lint shell scripts
shellcheck generate-agents.sh

# Test generation
./generate-agents.sh --language=go --dry-run
```

### Template Authoring

When editing `templates/`:
- Keep modules self-contained
- Test with `--dry-run` after changes
- Verify size limits still met
- Update CHANGELOG.md

---

## Anti-Slop Rules

- **No flattery** - Skip "Great question!"
- **No hype** - Avoid "revolutionary", "game-changing"
- **Evidence-based** - Cite sources or qualify as opinion
- **Direct** - State facts without embellishment

---

*This framework teaches AI assistants to teach other AI assistants.*
