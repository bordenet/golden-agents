#!/usr/bin/env bats
# SAFE WRITE tests - P0 Critical
# The generator must never overwrite a file that holds non-generated content.
# Plain runs refuse atomically; --adopt and --migrate back up first.

load 'test_helper'

FIXED_STAMP="20260101-120000"

setup() {
    TEST_DIR="$(mktemp -d)"
    REPO="$TEST_DIR/repo"
    mkdir -p "$REPO" "$TEST_DIR/bin"
    # Fake date so .bak names are deterministic; other formats pass through.
    cat > "$TEST_DIR/bin/date" << EOF
#!/bin/sh
if [ "\$1" = "+%Y%m%d-%H%M%S" ]; then echo "$FIXED_STAMP"; exit 0; fi
exec /bin/date "\$@"
EOF
    chmod +x "$TEST_DIR/bin/date"
    export TEST_DIR REPO
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# run_generator <args...>
# Runs the generator with the fake date first on PATH.
run_generator() {
    run env PATH="$TEST_DIR/bin:$PATH" "$GENERATE_SCRIPT" "$@"
}

# write_real_redirect_targets <dir>
# Creates hand-written files at paths the generator uses for redirects.
write_real_redirect_targets() {
    local dir="$1"
    mkdir -p "$dir/.github"
    printf '# Gemini rules\nUse pnpm, never npm.\n' > "$dir/GEMINI.md"
    printf 'Codex: run make check before commit\n' > "$dir/CODEX.md"
    printf '# Copilot\nPrefer table-driven tests.\n' > "$dir/.github/copilot-instructions.md"
}

# write_legacy_stub <file> <title> <agents_name>
# Writes a redirect exactly as golden-agents 1.4.x produced it.
write_legacy_stub() {
    printf '# %s\n\nSee **[%s](./%s)** for all AI guidance.\n' "$2" "$3" "$3" > "$1"
}

# write_legacy_copilot_stub <file> <agents_name>
write_legacy_copilot_stub() {
    mkdir -p "$(dirname "$1")"
    cat > "$1" << EOF
# GitHub Copilot Custom Instructions

See **[../$2](../$2)** for all AI guidance.

## Summary

This project uses the Golden Agents Framework for AI coding assistant guidance.
All instructions are consolidated in $2 at the project root.
EOF
}

@test "SAFE WRITE: plain run refuses real GEMINI.md, CODEX.md, copilot-instructions.md and writes nothing" {
    write_real_redirect_targets "$REPO"
    cp -R "$REPO" "$TEST_DIR/before"

    run_generator --language=go --path="$REPO"
    [ "$status" -eq 1 ]
    [[ "$output" == *"GEMINI.md"* ]]
    [[ "$output" == *"CODEX.md"* ]]
    [[ "$output" == *".github/copilot-instructions.md"* ]]

    # Atomic refusal: no file changed, no file created (no AGENTS.md, no .bak)
    diff -r "$TEST_DIR/before" "$REPO"
}

@test "SAFE WRITE: plain run refuses a short real CLAUDE.md" {
    echo "Use pnpm." > "$REPO/CLAUDE.md"
    cp -R "$REPO" "$TEST_DIR/before"

    run_generator --language=go --path="$REPO"
    [ "$status" -eq 1 ]
    [[ "$output" == *"CLAUDE.md"* ]]
    diff -r "$TEST_DIR/before" "$REPO"
}

@test "SAFE WRITE: plain run refuses an existing AGENTS.md with markers" {
    run_generator --language=go --path="$REPO"
    [ "$status" -eq 0 ]
    echo "MY_PROJECT_RULE_KEEP_ME" >> "$REPO/AGENTS.md"
    cp -R "$REPO" "$TEST_DIR/before"

    run_generator --language=go --path="$REPO"
    [ "$status" -eq 1 ]
    [[ "$output" == *"AGENTS.md"* ]]
    [[ "$output" == *"--upgrade"* ]]
    diff -r "$TEST_DIR/before" "$REPO"
}

@test "SAFE WRITE: generated redirects carry the sentinel line" {
    run_generator --language=go --path="$REPO"
    [ "$status" -eq 0 ]
    for f in CLAUDE.md CODEX.md AGENT.md GEMINI.md COPILOT.md .github/copilot-instructions.md; do
        grep -qxF "<!-- golden-agents:generated -->" "$REPO/$f" || return 1
    done
}

@test "SAFE WRITE: sentinel-marked redirects are overwritten" {
    run_generator --language=go --path="$REPO"
    [ "$status" -eq 0 ]
    rm "$REPO/AGENTS.md"
    echo "local edit" >> "$REPO/GEMINI.md"

    run_generator --language=go --path="$REPO"
    [ "$status" -eq 0 ]
    run grep -q "local edit" "$REPO/GEMINI.md"
    [ "$status" -ne 0 ]
}

@test "SAFE WRITE: 1.4.x redirect stubs (both AGENTS.md spellings) count as generated" {
    write_legacy_stub "$REPO/CLAUDE.md" "Claude Code Instructions" "AGENTS.md"
    write_legacy_stub "$REPO/CODEX.md" "OpenAI Codex CLI Instructions" "Agents.md"
    write_legacy_stub "$REPO/AGENT.md" "Amp by Sourcegraph Instructions" "AGENTS.md"
    write_legacy_stub "$REPO/GEMINI.md" "Google Gemini Code Assist Instructions" "Agents.md"
    write_legacy_stub "$REPO/COPILOT.md" "GitHub Copilot Instructions" "AGENTS.md"
    write_legacy_copilot_stub "$REPO/.github/copilot-instructions.md" "Agents.md"

    run_generator --language=go --path="$REPO"
    [ "$status" -eq 0 ]
    grep -qxF "<!-- golden-agents:generated -->" "$REPO/GEMINI.md"
    grep -qxF "<!-- golden-agents:generated -->" "$REPO/.github/copilot-instructions.md"
}

@test "SAFE WRITE: --migrate backs up real redirect files to timestamped .bak" {
    create_realistic_claude_md "$REPO"
    write_real_redirect_targets "$REPO"
    cp -R "$REPO" "$TEST_DIR/before"

    run_generator --migrate --language=go --path="$REPO"
    [ "$status" -eq 0 ]
    cmp "$TEST_DIR/before/CLAUDE.md" "$REPO/CLAUDE.md.$FIXED_STAMP.bak"
    cmp "$TEST_DIR/before/GEMINI.md" "$REPO/GEMINI.md.$FIXED_STAMP.bak"
    cmp "$TEST_DIR/before/CODEX.md" "$REPO/CODEX.md.$FIXED_STAMP.bak"
    cmp "$TEST_DIR/before/.github/copilot-instructions.md" \
        "$REPO/.github/copilot-instructions.md.$FIXED_STAMP.bak"
}

@test "SAFE WRITE: --adopt backs up real redirect files and keeps AGENTS.md.original" {
    create_agents_without_markers "$REPO"
    write_real_redirect_targets "$REPO"
    cp -R "$REPO" "$TEST_DIR/before"

    run_generator --adopt --language=go --path="$REPO"
    [ "$status" -eq 0 ]
    cmp "$TEST_DIR/before/AGENTS.md" "$REPO/AGENTS.md.original"
    cmp "$TEST_DIR/before/GEMINI.md" "$REPO/GEMINI.md.$FIXED_STAMP.bak"
    cmp "$TEST_DIR/before/CODEX.md" "$REPO/CODEX.md.$FIXED_STAMP.bak"
}

@test "SAFE WRITE: .bak name gets a numeric suffix on collision" {
    create_realistic_claude_md "$REPO"
    printf '# Gemini rules\nreal\n' > "$REPO/GEMINI.md"
    echo "older backup" > "$REPO/GEMINI.md.$FIXED_STAMP.bak"
    cp "$REPO/GEMINI.md" "$TEST_DIR/gemini.orig"

    run_generator --migrate --language=go --path="$REPO"
    [ "$status" -eq 0 ]
    [ "$(cat "$REPO/GEMINI.md.$FIXED_STAMP.bak")" = "older backup" ]
    cmp "$TEST_DIR/gemini.orig" "$REPO/GEMINI.md.$FIXED_STAMP-1.bak"
}

@test "SAFE WRITE: .bak files are not added to .gitignore" {
    create_realistic_claude_md "$REPO"
    write_real_redirect_targets "$REPO"

    run_generator --migrate --language=go --path="$REPO"
    [ "$status" -eq 0 ]
    run grep -q '\.bak' "$REPO/.gitignore"
    [ "$status" -ne 0 ]
}
