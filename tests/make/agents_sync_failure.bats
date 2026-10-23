#!/usr/bin/env bats

TEST_DIR="$(pwd)/agents_sync_failure"
REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"

function setup() {
  rm -rf "$TEST_DIR"
  mkdir -p "$TEST_DIR"
}

@test "agents/sync: failure with unknown profile" {
  run bash -c "cd '$TEST_DIR' && make -f '$REPO_ROOT/Makefile' agents/sync TARDIGRADE_CI_PATH='$REPO_ROOT' AGENTS_PROFILE=nonexistent-profile"
  [ "$status" -eq 2 ]
  [[ "$output" == *"ERROR: Profile 'nonexistent-profile' does not exist"* ]]
  [ ! -e "$TEST_DIR/.agents" ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
