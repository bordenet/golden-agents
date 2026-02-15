# Self-Managing Agents.md Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enable AI agents to automatically detect and refactor bloated Agents.md files using the self-managing architecture.

**Architecture:** Inject a 5-line bootstrap block into Agents.md that instructs agents to: (1) load `.ai-guidance/invariants.md` at conversation start, (2) check `wc -l Agents.md` after edits, (3) refactor if >150 lines. The `--upgrade` command auto-detects bloated files (>150 lines) and generates a modular migration prompt.

**Tech Stack:** Bash (generate-agents.sh), BATS (testing), Markdown (templates)

**Design Reference:** See `docs/plans/2026-02-15-self-managing-agents-design.md` for validated design decisions.

---

## Phase 1: Bootstrap Block Injection

### Task 1.1: Add Self-Manage Markers to Globals

**Files:**
- Modify: `generate-agents.sh:40-43`

**Step 1: Add new marker constants after existing MARKER_END**

```bash
# After line 43:
SELF_MANAGE_START="<!-- GOLDEN:self-manage:start -->"
SELF_MANAGE_END="<!-- GOLDEN:self-manage:end -->"
```

**Step 2: Run shellcheck to verify syntax**

Run: `shellcheck generate-agents.sh`
Expected: No new errors

**Step 3: Commit**

```bash
git add generate-agents.sh
git commit -m "feat: add self-manage markers for bootstrap block"
```

---

### Task 1.2: Create generate_self_manage_block Function

**Files:**
- Modify: `generate-agents.sh` (add after `generate_footer()` ~line 935)

**Step 1: Write the function**

```bash
# generate_self_manage_block()
# Generates the 5-line self-management bootstrap block.
# This block is injected BEFORE the framework start marker.
# Arguments: none
# Returns: Bootstrap block content via stdout
generate_self_manage_block() {
    cat << 'SELF_MANAGE'
<!-- GOLDEN:self-manage:start -->
## ⚠️ Before ANY Task
1. Load `.ai-guidance/invariants.md` — contains critical rules
2. After editing THIS file, run: `wc -l Agents.md` — if >150, refactor before continuing
<!-- GOLDEN:self-manage:end -->

SELF_MANAGE
}
```

**Step 2: Run shellcheck**

Run: `shellcheck generate-agents.sh`
Expected: No errors

**Step 3: Commit**

```bash
git add generate-agents.sh
git commit -m "feat: add generate_self_manage_block function"
```

---

### Task 1.3: Inject Bootstrap Block in generate_progressive

**Files:**
- Modify: `generate-agents.sh:716-745` (generate_progressive function)

**Step 1: Add self-manage block output after header, before MARKER_START**

The current structure outputs:
```
HEADER (lines 734-742)
$MARKER_START (line 744)
```

Change to:
```
HEADER
$(generate_self_manage_block)
$MARKER_START
```

**Step 2: Write failing test first**

Create test in `test/self-manage.bats`:
```bash
@test "new file contains self-manage block" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    assert_file_contains "$TEST_DIR/Agents.md" "GOLDEN:self-manage:start"
    assert_file_contains "$TEST_DIR/Agents.md" "if >150, refactor"
}
```

**Step 3: Run test to verify it fails**

Run: `bats test/self-manage.bats`
Expected: FAIL (self-manage markers not found)

**Step 4: Implement the change in generate_progressive**

**Step 5: Run test to verify it passes**

Run: `bats test/self-manage.bats`
Expected: PASS

**Step 6: Commit**

```bash
git add generate-agents.sh test/self-manage.bats
git commit -m "feat: inject self-manage bootstrap block in new files"
```

---

### Task 1.4: Inject Bootstrap Block During Upgrade

**Files:**
- Modify: `generate-agents.sh:998-1011` (upgrade_agents_md function)

**Step 1: Write failing test**

Add to `test/self-manage.bats`:
```bash
@test "upgrade adds self-manage block to existing file" {
    create_agents_with_markers "$TEST_DIR"
    # Verify no self-manage block initially
    run grep "GOLDEN:self-manage" "$TEST_DIR/Agents.md"
    [ "$status" -ne 0 ]
    
    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    assert_file_contains "$TEST_DIR/Agents.md" "GOLDEN:self-manage:start"
}
```

**Step 2: Run test to verify it fails**

Run: `bats test/self-manage.bats`
Expected: FAIL

**Step 3: Modify upgrade_agents_md to inject self-manage block**

In the upgrade function, after extracting `before_marker`, check if self-manage block exists. If not, prepend it to `before_marker`.

**Step 4: Run test to verify it passes**

Run: `bats test/self-manage.bats`
Expected: PASS

**Step 5: Commit**

```bash
git add generate-agents.sh test/self-manage.bats
git commit -m "feat: inject self-manage block during upgrade"
```

---

## Phase 2: Invariants Template

### Task 2.1: Create invariants.md Template

**Files:**
- Create: `templates/core/invariants.md`

**Step 1: Write the template content**

```markdown
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
```

**Step 2: Run shellcheck on templates (validation)**

Run: `wc -l templates/core/invariants.md`
Expected: ≤50 lines

**Step 3: Commit**

```bash
git add templates/core/invariants.md
git commit -m "feat: add invariants.md template for self-management"
```

---

## Phase 3: Modular Migration Detection

### Task 3.1: Create Modular Migration Prompt Template

**Files:**
- Create: `templates/modular-migration-prompt.md`

**Step 1: Write the template (~100 lines)**

Key sections to include:
- Mission statement (refactor bloated Agents.md to modular structure)
- Success criteria (Agents.md ≤150 lines, sub-files ≤50 lines each)
- Classification rules (what goes where)
- Zero data loss checklist
- Step-by-step process
- Recovery instructions

**Step 2: Commit**

```bash
git add templates/modular-migration-prompt.md
git commit -m "feat: add modular migration prompt template"
```

---

### Task 3.2: Add Bloat Detection to Upgrade

**Files:**
- Modify: `generate-agents.sh` (upgrade_agents_md function)

**Step 1: Write failing test**

Add to `test/self-manage.bats`:
```bash
@test "upgrade detects bloated file and creates migration prompt" {
    create_bloated_agents_with_markers "$TEST_DIR" 200

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/MODULAR-MIGRATION-PROMPT.md" ]
    [[ "$output" == *"exceeds 150 lines"* ]] || [[ "$output" == *"bloat"* ]]
}
```

**Step 2: Add helper function to test_helper.bash**

```bash
create_bloated_agents_with_markers() {
    local dir="$1"
    local lines="${2:-200}"
    mkdir -p "$dir"
    cat > "$dir/Agents.md" << 'EOF'
# AI Agent Guidelines - Test Project

<!-- GOLDEN:framework:start -->
## Quality Gates
- Lint
- Build
- Test
<!-- GOLDEN:framework:end -->

## Project-Specific Rules
EOF
    # Add bloat lines
    for i in $(seq 1 "$lines"); do
        echo "- Rule $i: Do something specific" >> "$dir/Agents.md"
    done
}
```

**Step 3: Run test to verify it fails**

Run: `bats test/self-manage.bats`
Expected: FAIL (no MODULAR-MIGRATION-PROMPT.md created)

**Step 4: Implement bloat detection in upgrade_agents_md**

After applying upgrade, check line count:
```bash
local line_count
line_count=$(wc -l < "$existing_file" | tr -d ' ')
if [[ "$line_count" -gt 150 ]]; then
    echo "[WARN] Agents.md exceeds 150 lines ($line_count lines)"
    echo "  Creating modular migration prompt..."
    create_modular_migration_prompt "$OUTPUT_PATH"
fi
```

**Step 5: Create create_modular_migration_prompt function**

```bash
create_modular_migration_prompt() {
    local dir="$1"
    if [[ -f "$TEMPLATES_DIR/modular-migration-prompt.md" ]]; then
        cp "$TEMPLATES_DIR/modular-migration-prompt.md" "$dir/MODULAR-MIGRATION-PROMPT.md"
        echo "[OK] Created: $dir/MODULAR-MIGRATION-PROMPT.md"

        # Add to .gitignore
        if [[ -f "$dir/.gitignore" ]]; then
            if ! grep -q "MODULAR-MIGRATION-PROMPT.md" "$dir/.gitignore"; then
                echo "MODULAR-MIGRATION-PROMPT.md" >> "$dir/.gitignore"
            fi
        fi
    fi
}
```

**Step 6: Run test to verify it passes**

Run: `bats test/self-manage.bats`
Expected: PASS

**Step 7: Commit**

```bash
git add generate-agents.sh test/self-manage.bats test/test_helper.bash
git commit -m "feat: detect bloated files during upgrade and create migration prompt"
```

---

### Task 3.3: Create .ai-guidance Directory During Migration

**Files:**
- Modify: `generate-agents.sh` (create_modular_migration_prompt function)

**Step 1: Write failing test**

```bash
@test "upgrade creates .ai-guidance with invariants.md for bloated files" {
    create_bloated_agents_with_markers "$TEST_DIR" 200

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -d "$TEST_DIR/.ai-guidance" ]
    [ -f "$TEST_DIR/.ai-guidance/invariants.md" ]
}
```

**Step 2: Run test to verify it fails**

Run: `bats test/self-manage.bats`
Expected: FAIL

**Step 3: Implement directory creation**

In `create_modular_migration_prompt`:
```bash
# Create .ai-guidance directory with default invariants.md
mkdir -p "$dir/.ai-guidance"
if [[ -f "$TEMPLATES_DIR/core/invariants.md" ]]; then
    cp "$TEMPLATES_DIR/core/invariants.md" "$dir/.ai-guidance/invariants.md"
    echo "[OK] Created: $dir/.ai-guidance/invariants.md"
fi
```

**Step 4: Run test to verify it passes**

Run: `bats test/self-manage.bats`
Expected: PASS

**Step 5: Commit**

```bash
git add generate-agents.sh test/self-manage.bats
git commit -m "feat: create .ai-guidance/invariants.md during modular migration"
```

---

## Phase 4: Full Test Suite

### Task 4.1: Create Comprehensive self-manage.bats

**Files:**
- Create/Modify: `test/self-manage.bats`

**Tests to include:**

1. `new file contains self-manage block`
2. `new file contains self-manage markers in correct position`
3. `upgrade adds self-manage block to existing file`
4. `upgrade preserves existing self-manage block`
5. `upgrade detects bloated file and warns`
6. `upgrade creates migration prompt for bloated file`
7. `upgrade creates .ai-guidance directory for bloated file`
8. `upgrade creates invariants.md for bloated file`
9. `non-bloated file does not trigger migration prompt`
10. `self-manage block appears before framework markers`

**Step 1: Write all tests**

**Step 2: Run full test suite**

Run: `bats test/self-manage.bats`
Expected: All PASS

**Step 3: Run entire test suite for regression**

Run: `bats test/*.bats`
Expected: All existing tests still PASS

**Step 4: Commit**

```bash
git add test/self-manage.bats
git commit -m "test: comprehensive self-manage test suite"
```

---

### Task 4.2: Test Against genesis-tools Repos

**Files:**
- No file changes (manual verification)

**Step 1: Test upgrade on docforge-ai (295 lines)**

```bash
cd ../genesis-tools/docforge-ai
../../golden-agents/generate-agents.sh --upgrade --path=.
# Should show: "exceeds 150 lines (295 lines)"
```

**Step 2: Test upgrade on pr-faq-assistant (239 lines)**

```bash
cd ../genesis-tools/pr-faq-assistant
../../golden-agents/generate-agents.sh --upgrade --path=.
# Should show: "exceeds 150 lines (239 lines)"
```

**Step 3: Verify MODULAR-MIGRATION-PROMPT.md created**

**Step 4: Document results**

---

## Checklist Before Merge

- [ ] All new tests pass (`bats test/*.bats`)
- [ ] ShellCheck passes (`shellcheck generate-agents.sh`)
- [ ] Framework version bumped to 1.5.0 (if appropriate)
- [ ] Design document referenced in commit messages
- [ ] No data loss in upgrade scenarios (backup always created)
- [ ] Backward compatible with existing files

---

## Summary

| Phase | Tasks | Key Deliverables |
|-------|-------|------------------|
| 1 | 1.1-1.4 | Self-manage markers, bootstrap block injection |
| 2 | 2.1 | `templates/core/invariants.md` |
| 3 | 3.1-3.3 | Bloat detection, modular migration prompt, .ai-guidance creation |
| 4 | 4.1-4.2 | Test suite, genesis-tools validation |

**Estimated time:** 2-3 hours

---

**Plan complete and saved to `docs/plans/2026-02-15-self-managing-agents-implementation-plan.md`. Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?**

