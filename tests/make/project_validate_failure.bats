#!/usr/bin/env bats

TEST_DIR="$(pwd)/project_validate_failure"

# generate a folder without content
function setup() {
rm -rf "$TEST_DIR"
mkdir "$TEST_DIR"

}

@test "project/validate: success" {
  run make project/validate PROJECT_ROOT="$TEST_DIR"
  [ "$status" -eq 2 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
