#!/usr/bin/env bats
# P3: Sync Tests
# Tests for git sync functionality. Every test syncs a throwaway clone of a
# throwaway upstream; nothing touches this checkout or the network.

load 'test_helper'

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# g <args...>
# git with a fixed identity and no signing, independent of user config.
g() {
    git -c user.name=test -c user.email=test@example.com -c commit.gpgsign=false "$@"
}

# make_sync_fixture
# Creates $TEST_DIR/upstream (script + templates on main) and a clone at
# $TEST_DIR/clone whose origin is the upstream.
make_sync_fixture() {
    mkdir -p "$TEST_DIR/upstream"
    cp "$GENERATE_SCRIPT" "$TEST_DIR/upstream/"
    cp -R "$SCRIPT_DIR/templates" "$TEST_DIR/upstream/"
    g init -q -b main "$TEST_DIR/upstream"
    g -C "$TEST_DIR/upstream" add -A
    g -C "$TEST_DIR/upstream" commit -q -m init
    g clone -q "$TEST_DIR/upstream" "$TEST_DIR/clone"
}

# upstream_commit <file> <content>
upstream_commit() {
    echo "$2" > "$TEST_DIR/upstream/$1"
    g -C "$TEST_DIR/upstream" add -A
    g -C "$TEST_DIR/upstream" commit -q -m "upstream change"
}

# Test 1: Clean clone fast-forwards to upstream
@test "sync fast-forwards a clean clone" {
    make_sync_fixture
    upstream_commit templates/NEW.md "new template"

    run "$TEST_DIR/clone/generate-agents.sh" --sync
    [ "$status" -eq 0 ]
    [[ "$output" == *"Templates updated"* ]]
    [ -f "$TEST_DIR/clone/templates/NEW.md" ]
    [ "$(git -C "$TEST_DIR/clone" rev-parse HEAD)" = "$(git -C "$TEST_DIR/upstream" rev-parse HEAD)" ]
}

# Test 2: Sync in non-git directory fails
@test "sync fails when not in git repo" {
    # Create a copy of the script in a non-git directory
    cp "$GENERATE_SCRIPT" "$TEST_DIR/generate-agents.sh"
    chmod +x "$TEST_DIR/generate-agents.sh"
    
    cd "$TEST_DIR"
    run ./generate-agents.sh --sync
    
    [ "$status" -ne 0 ]
    [[ "$output" == *"git"* ]] || [[ "$output" == *"Not a git repo"* ]] || [[ "$output" == *"clone"* ]]
}

# Test 3: Local changes block sync and stay intact
@test "sync refuses a clone with uncommitted changes" {
    make_sync_fixture
    upstream_commit templates/NEW.md "new template"
    echo "LOCAL EDIT" >> "$TEST_DIR/clone/templates/core/anti-slop.md"
    local before
    before=$(git -C "$TEST_DIR/clone" rev-parse HEAD)

    run "$TEST_DIR/clone/generate-agents.sh" --sync
    [ "$status" -eq 1 ]
    [[ "$output" == *"uncommitted changes"* ]]
    [ "$(git -C "$TEST_DIR/clone" rev-parse HEAD)" = "$before" ]
    grep -q "LOCAL EDIT" "$TEST_DIR/clone/templates/core/anti-slop.md"
}

# Test 4: Diverged history is not rebased
@test "sync refuses to rewrite a clone with local commits" {
    make_sync_fixture
    upstream_commit templates/NEW.md "new template"
    echo "local" > "$TEST_DIR/clone/templates/LOCAL.md"
    g -C "$TEST_DIR/clone" add -A
    g -C "$TEST_DIR/clone" commit -q -m "local change"
    local before
    before=$(git -C "$TEST_DIR/clone" rev-parse HEAD)

    run "$TEST_DIR/clone/generate-agents.sh" --sync
    [ "$status" -eq 1 ]
    [[ "$output" == *"fast-forward"* ]]
    [ "$(git -C "$TEST_DIR/clone" rev-parse HEAD)" = "$before" ]
}
