#!/usr/bin/env bats
# Section E: the superpowers bootstrap is off unless --superpowers is passed,
# and then it sits after the framework end marker.

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# framework_has_bootstrap <file>
# True when the bootstrap command appears between the framework markers.
framework_has_bootstrap() {
    awk '
        index($0, "<!-- GOLDEN:framework:start -->") { inside = 1 }
        inside && index($0, "superpowers-augment.js bootstrap") { found = 1 }
        index($0, "<!-- GOLDEN:framework:end -->") { inside = 0 }
        END { exit !found }
    ' "$1"
}

@test "progressive generation omits the superpowers bootstrap" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    ! grep -q 'superpowers-augment.js' "$TEST_DIR/AGENTS.md"
}

@test "--superpowers writes the bootstrap after the framework end marker" {
    run "$GENERATE_SCRIPT" --language=go --superpowers --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    grep -q 'superpowers-augment.js bootstrap' "$TEST_DIR/AGENTS.md"
    ! framework_has_bootstrap "$TEST_DIR/AGENTS.md"
    awk '
        index($0, "<!-- GOLDEN:framework:end -->") { seen = 1; next }
        seen && index($0, "superpowers-augment.js bootstrap") { found = 1 }
        END { exit !found }
    ' "$TEST_DIR/AGENTS.md"
}

@test "upgrade removes an in-framework bootstrap and does not restore it" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    # Put the old block back inside the framework, as 1.4.x did.
    awk '
        index($0, "<!-- GOLDEN:framework:end -->") {
            print "node ~/.codex/superpowers-augment/superpowers-augment.js bootstrap"
        }
        { print }
    ' "$TEST_DIR/AGENTS.md" > "$TEST_DIR/old.md"
    mv "$TEST_DIR/old.md" "$TEST_DIR/AGENTS.md"

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    ! grep -q 'superpowers-augment.js' "$TEST_DIR/AGENTS.md"

    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    ! grep -q 'superpowers-augment.js' "$TEST_DIR/AGENTS.md"
}

@test "upgrade --superpowers writes the block after the marker once" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    run "$GENERATE_SCRIPT" --upgrade --apply --superpowers --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    ! framework_has_bootstrap "$TEST_DIR/AGENTS.md"
    local count
    count=$(grep -c 'superpowers-augment.js bootstrap' "$TEST_DIR/AGENTS.md")
    [ "$count" -eq 1 ]

    run "$GENERATE_SCRIPT" --upgrade --apply --superpowers --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    count=$(grep -c 'superpowers-augment.js bootstrap' "$TEST_DIR/AGENTS.md")
    [ "$count" -eq 1 ]
}

@test "upgrade --superpowers leaves a bootstrap the project already pasted" {
    run "$GENERATE_SCRIPT" --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    printf '\nOur bootstrap: node ~/.codex/superpowers-augment/superpowers-augment.js bootstrap\n' \
        >> "$TEST_DIR/AGENTS.md"
    cp "$TEST_DIR/AGENTS.md" "$TEST_DIR/before.md"

    run "$GENERATE_SCRIPT" --upgrade --apply --superpowers --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    grep -q 'Our bootstrap:' "$TEST_DIR/AGENTS.md"
    local count
    count=$(grep -c 'superpowers-augment.js bootstrap' "$TEST_DIR/AGENTS.md")
    [ "$count" -eq 1 ]
    ! framework_has_bootstrap "$TEST_DIR/AGENTS.md"
}
