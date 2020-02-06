#!/usr/bin/env bats

TEST_DIR="$(pwd)/hcl_lint_failure"

function setup() {
mkdir -p "$TEST_DIR/top/nested"
echo "test {" > "$TEST_DIR/top/nested/test.hcl"
}

@test "hcl/lint: nested file failure" {
  run make hcl/lint
  [ "$status" -eq 2 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}

