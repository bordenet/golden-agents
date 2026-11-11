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
