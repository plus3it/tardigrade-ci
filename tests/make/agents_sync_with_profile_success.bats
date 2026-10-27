#!/usr/bin/env bats

TEST_DIR="$(pwd)/agents_sync_with_profile_success"
REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"

function setup() {
  rm -rf "$TEST_DIR"
  mkdir -p "$TEST_DIR"
}

@test "agents/sync: success with terraform-module profile" {
  run bash -c "cd '$TEST_DIR' && make -f '$REPO_ROOT/Makefile' agents/sync TARDIGRADE_CI_PATH='$REPO_ROOT' AGENTS_PROFILE=terraform-module"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Successfully synced agent instructions"* ]]
  [ -f "$TEST_DIR/.agents/plus3it/AGENTS.md" ]
  [ -f "$TEST_DIR/.agents/plus3it/.gitignore" ]
  grep -q "Shared Plus3 IT Agent Instructions" "$TEST_DIR/.agents/plus3it/AGENTS.md"
  grep -q "Terraform Module Profile" "$TEST_DIR/.agents/plus3it/AGENTS.md"
}

@test "agents/sync: success with tardigrade-deployment profile" {
  run bash -c "cd '$TEST_DIR' && make -f '$REPO_ROOT/Makefile' agents/sync TARDIGRADE_CI_PATH='$REPO_ROOT' AGENTS_PROFILE=tardigrade-deployment"
  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/.agents/plus3it/AGENTS.md" ]
  grep -q "Shared Plus3 IT Agent Instructions" "$TEST_DIR/.agents/plus3it/AGENTS.md"
  grep -q "Tardigrade Deployment Profile" "$TEST_DIR/.agents/plus3it/AGENTS.md"
}

@test "agents/sync: success with salt-formula profile" {
  run bash -c "cd '$TEST_DIR' && make -f '$REPO_ROOT/Makefile' agents/sync TARDIGRADE_CI_PATH='$REPO_ROOT' AGENTS_PROFILE=salt-formula"
  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/.agents/plus3it/AGENTS.md" ]
  grep -q "Shared Plus3 IT Agent Instructions" "$TEST_DIR/.agents/plus3it/AGENTS.md"
  grep -q "Salt Formula Profile" "$TEST_DIR/.agents/plus3it/AGENTS.md"
  grep -q "not versioned or released" "$TEST_DIR/.agents/plus3it/AGENTS.md"
}

function teardown() {
  rm -rf "$TEST_DIR"
}
