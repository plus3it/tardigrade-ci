#!/usr/bin/env bats

TEST_DIR="$(pwd)/hcl_format_failure"

function setup() {
mkdir -p "$TEST_DIR/top/nested"
echo "test {" > "$TEST_DIR/top/nested/test.hcl"
}

@test "hcl/format: nested file failure" {
  run make hcl/format
  [ "$status" -eq 2 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}

