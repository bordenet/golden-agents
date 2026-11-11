#!/usr/bin/env bats
# Section I: the fixture is real and the score sheet has no recorded run.

load 'test_helper'

@test "EVAL: fixture defects are still in place" {
    run bash "$SCRIPT_DIR/evals/fixture/check.sh"
    [ "$status" -eq 0 ]
}

@test "EVAL: score sheet lists every task and records the Cursor run" {
    local sheet="$SCRIPT_DIR/docs/evals/SCORE.md"
    [ -f "$sheet" ]
    grep -q 'A missing eval is not a passing eval.' "$sheet"
    local id
    for id in 01-lint-failure 02-failing-test 03-secret-in-diff 04-over-size-cap \
              05-wrong-command 06-broken-build 07-keep-project-rule 08-piped-curl; do
        grep -q "| $id | Claude Code |" "$sheet"
        grep -q "| $id | Codex |" "$sheet"
        grep -q "| $id | Cursor | Grok 4.7 | 2026-11-11 | pass:" "$sheet"
    done
    local count
    count=$(grep -c '| not run | not run |' "$sheet")
    [ "$count" -eq 16 ]
}
