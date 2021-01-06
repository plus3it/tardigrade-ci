#!/usr/bin/env bats

TEST_DIR="$(pwd)/bumpversion_failure"
BUMPVERSION_FILE="${TEST_DIR}/bumptest.cfg"

function setup() {
  rm -rf "$TEST_DIR"
  mkdir "$TEST_DIR"

  cat > ${BUMPVERSION_FILE} << EOF
[bumpversion]
current_version = 0.0.0
EOF
}

@test "bumpversion: failure" {
  run make bumpversion/majority BUMPVERSION_ARGS="--dry-run"
  [ "$status" -eq 2 ]
  [[ "$output" == *"No rule to make target"* ]]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
