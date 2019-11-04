#!/usr/bin/env bats

DIR="$(pwd)"
TEST_DIR="$DIR/json_lint_success"

function setup() {
mkdir -p "$TEST_DIR/top/nested"
cat > "$TEST_DIR/top/failure.json" <<-EOF
{
  "foo": bar

EOF
}

@test "json/lint: nested file failure" {
  run make json/lint
  [ "$status" -eq 2 ]
  [ "${lines[2]}" = "parse error: Invalid numeric literal at line 3, column 0" ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
