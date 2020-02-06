#!/usr/bin/env bats

TEST_DIR="$(pwd)/hcl_format_success"

function setup() {
mkdir -p "$TEST_DIR/top/nested"
echo "terragrunt {}" > "$TEST_DIR/top/nested/test.hcl"
}

@test "hcl/format: nested file success" {
  run make hcl/format
  [ "$status" -eq 0 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
