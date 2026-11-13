#!/usr/bin/env bats
# --self-test and --no-backup coverage

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# clone_checkout <dest>
# Copies the real entry + parts + templates into dest so self-test can be
# pointed at a throwaway tree without mutating this repo.
clone_checkout() {
    local dest="$1"
    mkdir -p "$dest/lib/golden-agents"
    cp "$GENERATE_ENTRY" "$dest/generate-agents.sh"
    chmod +x "$dest/generate-agents.sh"
    cp "$SCRIPT_DIR"/lib/golden-agents/part*.sh "$dest/lib/golden-agents/"
    chmod +x "$dest"/lib/golden-agents/part*.sh 2>/dev/null || true
    cp -R "$SCRIPT_DIR/templates" "$dest/"
}

@test "self-test passes on a healthy checkout" {
    run "$GENERATE_SCRIPT" --self-test
    [ "$status" -eq 0 ]
    [[ "$output" == *PASS* ]]
}

@test "--no-backup alone fails" {
    run "$GENERATE_SCRIPT" --no-backup
    [ "$status" -ne 0 ]
    [[ "$output" == *"--no-backup requires"* ]] || [[ "$output" == *"requires --apply"* ]]
}

@test "upgrade --apply --no-backup skips backup" {
    create_agents_with_markers "$TEST_DIR"

    run "$GENERATE_SCRIPT" --upgrade --apply --no-backup --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ ! -f "$TEST_DIR/AGENTS.md.backup" ]
    [[ "$output" == *"Skipping"* || "$output" == *"--no-backup"* || "$output" == *"Skipped"* ]]
}

@test "self-test fails when a part is truncated" {
    clone_checkout "$TEST_DIR/ga"
    # Keep first line shell-like so we hit the size check, not the stub head.
    printf '#!/usr/bin/env bash\n# tiny\n' > "$TEST_DIR/ga/lib/golden-agents/part02.sh"

    run bash "$TEST_DIR/ga/generate-agents.sh" --self-test
    [ "$status" -ne 0 ]
    [[ "$output" == *"only"* || "$output" == *"truncated"* || "$output" == *"1000"* ]]
}

@test "self-test fails when a part looks like a PLACEHOLDER stub" {
    clone_checkout "$TEST_DIR/ga"
    # Pad past the 1000-byte size gate so the stub-head case fires.
    {
        echo 'PLACEHOLDER: restore from upload'
        printf 'x%.0s' {1..1200}
        echo
    } > "$TEST_DIR/ga/lib/golden-agents/part02.sh"

    run bash "$TEST_DIR/ga/generate-agents.sh" --self-test
    [ "$status" -ne 0 ]
    [[ "$output" == *"stub"* || "$output" == *"PLACEHOLDER"* ]]
}

@test "self-test fails when a part is a LOAD_ path stub" {
    clone_checkout "$TEST_DIR/ga"
    {
        echo '# recovered part'
        echo 'LOAD_FROM_PRIOR_SUCCESSFUL_UPLOAD'
        printf 'y%.0s' {1..1200}
        echo
    } > "$TEST_DIR/ga/lib/golden-agents/part03.sh"

    run bash "$TEST_DIR/ga/generate-agents.sh" --self-test
    [ "$status" -ne 0 ]
    [[ "$output" == *"truncated"* || "$output" == *"stub"* || "$output" == *"LOAD_"* ]]
}

@test "self-test fails when a part fails bash -n" {
    clone_checkout "$TEST_DIR/ga"
    {
        echo '#!/usr/bin/env bash'
        echo 'if true; then'
        printf 'z%.0s' {1..1200}
        echo
        # Missing fi → bash -n fails
    } > "$TEST_DIR/ga/lib/golden-agents/part01.sh"

    run bash "$TEST_DIR/ga/generate-agents.sh" --self-test
    [ "$status" -ne 0 ]
    [[ "$output" == *"bash -n"* || "$output" == *"Self-test failed"* ]]
}

@test "migrate --no-backup skips timestamped AGENTS.md bak" {
    create_realistic_claude_md "$TEST_DIR"
    printf '# Team guide\nUNIQUE_AGENTS_ONLY_CONTENT\n' > "$TEST_DIR/AGENTS.md"

    run "$GENERATE_SCRIPT" --migrate --no-backup --language=go --path="$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -z "$(find "$TEST_DIR" -maxdepth 1 -name 'AGENTS.md.*.bak')" ]
    [[ "$output" == *"Skipped backup"* || "$output" == *"--no-backup"* ]]
}
