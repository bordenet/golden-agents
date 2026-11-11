#!/usr/bin/env bats
# Size threshold tests
# The AGENTS.md / .ai-guidance line limit is defined once in the script
# (MAX_GUIDANCE_LINES) and every output that states it must agree.

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    MAX=$(sed -n 's/^MAX_GUIDANCE_LINES=\([0-9][0-9]*\)$/\1/p' "$GENERATE_SCRIPT")
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# assert_all_equal_max <label> <numbers...>
# Fails unless at least one number is given and every number equals MAX.
assert_all_equal_max() {
    local label="$1"
    shift
    if [[ $# -eq 0 ]]; then
        echo "FAIL: no threshold found in $label" >&2
        return 1
    fi
    local n
    for n in "$@"; do
        if [[ "$n" != "$MAX" ]]; then
            echo "FAIL: $label states $n, script limit is $MAX" >&2
            return 1
        fi
    done
}

# numbers <file> <extended-regex> [exclude-regex]
# Prints the numbers inside each match of the regex in the file, skipping
# lines that match the optional exclude regex (other limits, not this one).
numbers() {
    grep -vE "${3:-^\$^}" "$1" | grep -oE "$2" | grep -oE '[0-9]+' || true
}

@test "THRESHOLD: script defines MAX_GUIDANCE_LINES=250" {
    [ "$MAX" = "250" ]
}

@test "THRESHOLD: upgrade does not trigger modular migration between 150 and the limit" {
    create_bloated_agents_with_markers "$TEST_DIR" 150
    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    local lines
    lines=$(wc -l < "$TEST_DIR/AGENTS.md" | tr -d ' ')
    [ "$lines" -gt 150 ]
    [ "$lines" -le "$MAX" ]
    [ ! -e "$TEST_DIR/MODULAR-MIGRATION-PROMPT.md" ]
}

@test "THRESHOLD: upgrade triggers modular migration above the limit and says so" {
    create_bloated_agents_with_markers "$TEST_DIR" 300
    run "$GENERATE_SCRIPT" --upgrade --apply --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -e "$TEST_DIR/MODULAR-MIGRATION-PROMPT.md" ]
    # shellcheck disable=SC2046
    assert_all_equal_max "upgrade warning" $(echo "$output" | grep -oE 'exceeds [0-9]+ lines' | grep -oE '[0-9]+')
}

@test "THRESHOLD: generated AGENTS.md, prompts and invariants all state the same limit" {
    create_realistic_claude_md "$TEST_DIR"
    run "$GENERATE_SCRIPT" --migrate --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]

    # shellcheck disable=SC2046
    assert_all_equal_max "AGENTS.md self-manage block" \
        $(numbers "$TEST_DIR/AGENTS.md" '>[0-9]+ lines')
    # shellcheck disable=SC2046
    assert_all_equal_max "MIGRATION-PROMPT.md" \
        $(numbers "$TEST_DIR/MIGRATION-PROMPT.md" 'under [0-9]+ lines')
    # shellcheck disable=SC2046
    assert_all_equal_max "invariants.md" \
        $(numbers "$TEST_DIR/.ai-guidance/invariants.md" '\| [0-9]+ lines \||≤[0-9]+|exceeds [0-9]+ lines')
    # shellcheck disable=SC2046
    assert_all_equal_max "modular-migration-prompt.md" \
        $(numbers "$SCRIPT_DIR/templates/modular-migration-prompt.md" \
            '>[0-9]+ lines|≤[0-9]+|[0-9]+-line limit|exceeds [0-9]+ lines' 'project overview')
}

@test "THRESHOLD: docs state the same limit and no Compact mode" {
    # shellcheck disable=SC2046
    assert_all_equal_max "README.md" \
        $(numbers "$SCRIPT_DIR/README.md" '>[0-9]+ lines|\| [0-9]+ lines \||≤[0-9]+ lines')
    # shellcheck disable=SC2046
    assert_all_equal_max "AGENTS.md (this repo)" \
        $(numbers "$SCRIPT_DIR/AGENTS.md" '>[0-9]+ lines|(≤\|<=\)[0-9]+ lines')
    run grep -n 'Compact' "$SCRIPT_DIR/AGENTS.md"
    [ "$status" -ne 0 ]
}
