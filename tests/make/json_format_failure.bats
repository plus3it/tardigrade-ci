#!/usr/bin/env bats

DIR="$(pwd)"
TEST_DIR="$DIR/json_format_failure"

function setup() {
mkdir -p "$TEST_DIR/top/nested"
cat > "$TEST_DIR/top/failure.json" <<-EOF
{
  asdf
  "foo": "bar"

EOF
}

@test "json/format: nested file failure" {
  run make json/format
  [ "$status" -eq 2 ]
  [ "${lines[1]}" = "[./json_format_failure/top/failure.json]: JSON format failed" ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
