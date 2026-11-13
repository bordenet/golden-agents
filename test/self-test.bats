#!/usr/bin/env bats
# --self-test catches truncated part*.sh before --upgrade --apply.

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    # Fresh copy of the generator so mutations do not touch the repo checkout.
    cp -a "$SCRIPT_DIR/generate-agents.sh" "$TEST_DIR/"
    mkdir -p "$TEST_DIR/lib/golden-agents" "$TEST_DIR/templates"
    cp -a "$SCRIPT_DIR"/lib/golden-agents/part*.sh "$TEST_DIR/lib/golden-agents/"
    # Minimal templates so a nested --version still resolves SCRIPT_DIR.
    cp -a "$SCRIPT_DIR/templates/." "$TEST_DIR/templates/" 2>/dev/null || true
    chmod +x "$TEST_DIR/generate-agents.sh" "$TEST_DIR"/lib/golden-agents/part*.sh
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

@test "--self-test passes on a complete checkout" {
    run "$TEST_DIR/generate-agents.sh" --self-test
    [ "$status" -eq 0 ]
    [[ "$output" == *'[OK] Self-test passed'* ]]
    [[ "$output" == *'bash -n'* ]]
}

@test "--self-test fails when a part file is under 1000 bytes" {
    printf '%s\n' '#!/usr/bin/env bash' 'echo stub' > "$TEST_DIR/lib/golden-agents/part02.sh"
    run "$TEST_DIR/generate-agents.sh" --self-test
    [ "$status" -ne 0 ]
    [[ "$output" == *'only'*'bytes'* || "$output" == *'likely truncated'* ]]
    [[ "$output" == *'[FAIL] Self-test failed'* ]]
}

@test "--self-test fails when a part file is a truncated path stub" {
    # Keep size >= 1000 so the stub-head check is what fails.
    {
        echo 'LOAD_FULL_P02_FROM_PRIOR_SUCCESSFUL_UPLOAD_d6f60126'
        # shellcheck disable=SC2034
        yes 'padding line for stub size' | head -n 80
    } > "$TEST_DIR/lib/golden-agents/part02.sh"
    run "$TEST_DIR/generate-agents.sh" --self-test
    [ "$status" -ne 0 ]
    [[ "$output" == *'truncated path stub'* || "$output" == *'not a shell script'* ]]
    [[ "$output" == *'[FAIL] Self-test failed'* ]]
}
