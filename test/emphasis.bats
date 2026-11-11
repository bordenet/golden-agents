#!/usr/bin/env bats
# Section D: strong wording stays only where a wrong action is hard to undo,
# and that line says why. The other siren lines are ordinary instructions.

load 'test_helper'

@test "kept lines state the reason" {
    grep -q 'CRITICAL - a leaked secret is not fixed by rewriting the sentence later' \
        "$SCRIPT_DIR/templates/workflows/security.md"
    grep -q 'STOP' "$SCRIPT_DIR/templates/core/invariants.md"
    grep -q 'size cap exists so agents do not grow the file they are reading' \
        "$SCRIPT_DIR/templates/core/invariants.md"
    grep -q 'STOP' "$SCRIPT_DIR/templates/adopt-prompt.md"
    grep -q 'Adopting without markers can overwrite project text' \
        "$SCRIPT_DIR/templates/adopt-prompt.md"
    grep -q 'Do not claim done when tests were not run' \
        "$SCRIPT_DIR/templates/workflows/testing.md"
    grep -q 'CRITICAL' "$SCRIPT_DIR/templates/languages/go.md"
    grep -q 'catches compile failures that lint does not' \
        "$SCRIPT_DIR/templates/languages/go.md"
}

@test "demoted templates no longer use the siren words" {
    local f
    for f in \
        templates/core/anti-slop.md \
        templates/core/superpowers.md \
        templates/languages/dart-flutter.md \
        templates/languages/javascript.md \
        templates/project-types/cli-tools.md \
        templates/project-types/web-apps.md \
        templates/workflows/build-hygiene.md \
        templates/workflows/deployment.md \
        templates/workflows/testing.md
    do
        if grep -qE 'CRITICAL|MANDATORY|🚨' "$SCRIPT_DIR/$f"; then
            echo "siren wording remains in $f" >&2
            return 1
        fi
    done
}
