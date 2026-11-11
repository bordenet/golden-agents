#!/usr/bin/env bats
# Docs must not freeze a test total that drifts from the suite.

load 'test_helper'

@test "guidance docs do not hardcode a BATS or suite total" {
    local file hit=0
    for file in AGENTS.md docs/USAGE.md docs/TEST-PLAN.md; do
        if grep -E '[0-9]+ BATS|[0-9]+ tests\)|Total: [0-9]+ tests' "$file"; then
            echo "hardcoded test count in $file" >&2
            hit=1
        fi
    done
    [ "$hit" -eq 0 ]
}

@test "upgrade guide does not call design v2 unimplemented" {
    grep -q 'Sections A-H of `docs/DESIGN-v2.md` are in this generator.' \
        "$SCRIPT_DIR/docs/UPGRADE-GUIDE.md"
    ! grep -q 'are not implemented' "$SCRIPT_DIR/docs/UPGRADE-GUIDE.md"
    ! grep -q 'no behavior change' "$SCRIPT_DIR/docs/SUMMARY.md"
    grep -q 'The Cursor column of the score sheet has one run.' "$SCRIPT_DIR/docs/SUMMARY.md"
}
