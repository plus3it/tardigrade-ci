#!/usr/bin/env bats

TEST_DIR="$(pwd)/json_format_failure"

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
  [[ "$output" == *"[./json_format_failure/top/failure.json]: Found invalid JSON file: ./json_format_failure/top/failure.json"* ]]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
