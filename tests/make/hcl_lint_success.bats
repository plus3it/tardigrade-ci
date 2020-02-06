#!/usr/bin/env bats

TEST_DIR="$(pwd)/hcl_lint_success"

function setup() {
mkdir -p "$TEST_DIR/top/nested"
echo "terragrunt {}" > "$TEST_DIR/top/nested/test.hcl"
}

@test "hcl/lint: nested file success" {
  run make hcl/lint
  [ "$status" -eq 0 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
