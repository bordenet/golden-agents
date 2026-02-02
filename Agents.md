# AI Agent Guidelines - Golden Agents Framework

> **Last Updated**: 2026-02-02
> **Purpose**: Teach AI assistants how to USE this framework to apply AI guidance to other repos

---

## 🚨 CRITICAL: How to Use This Framework

**You are an AI assistant reading this file.** This repo contains tools that generate `Agents.md` files for OTHER projects. When a user asks you to "apply golden-agents" or "set up AI guidance" for a repo, follow these instructions.

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
| **No Agents.md** | Prompts for `--language` | Run with language flag, review output |
| **Existing CLAUDE.md/CODEX.md** | Suggests `--migrate` | Run migrate, then execute the generated prompt |
| **Existing Agents.md (no markers)** | Suggests `--adopt` | Run adopt, then execute the generated prompt |
| **Existing Agents.md (with markers)** | Suggests `--upgrade` | Run upgrade preview, then `--apply` if good |
| **Bloated Agents.md (>100 lines)** | Suggests `--dedupe` | Run dedupe, then execute the generated prompt |

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
2. **Size within limits** - Progressive mode ≤100 lines, Compact ≤200 lines
3. **Markers present** - `<!-- GOLDEN:framework:start -->` and `<!-- GOLDEN:framework:end -->`

---

## Command Reference

### For New Projects (No Agents.md)

```bash
./generate-agents.sh --language=go --path=/path/to/repo
./generate-agents.sh --language=python,shell --type=cli-tools --path=/path/to/repo
```

### For Existing CLAUDE.md/CODEX.md (Migration)

```bash
./generate-agents.sh --migrate --path=/path/to/repo
# Then read and execute: /path/to/repo/MIGRATION-PROMPT.md
```

### For Existing Agents.md Without Markers (Adoption)

```bash
./generate-agents.sh --adopt --language=go --path=/path/to/repo
# Then read and execute: /path/to/repo/ADOPT-PROMPT.md
```

### For Existing Agents.md With Markers (Upgrade)

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
# - Create the new Agents.md with proper structure
# - Verify zero data loss

# 4. Verify result
wc -l ../recipe-app/Agents.md  # Should be ≤100 lines for progressive
grep "GOLDEN:framework" ../recipe-app/Agents.md  # Should find markers
```

---

## For Complex Projects (>100 Lines of Project-Specific Content)

If a project has extensive project-specific guidance that can't fit in 100 lines:

1. Create `.ai-guidance/` directory in target repo
2. Split content into focused modules (e.g., `mobile-builds.md`, `api-patterns.md`)
3. Reference modules from main Agents.md with on-demand loading table

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

