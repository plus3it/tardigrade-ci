#!/usr/bin/env bats

TEST_DIR="$(pwd)/json_format_success"

function setup() {
mkdir -p "$TEST_DIR/top/nested"
cat > "$TEST_DIR/top/success.json" <<-EOF
{
"foo": "bar"
}
EOF
}

@test "json/format: nested file success" {
  run make json/format
  [ "$status" -eq 0 ]
  [[ "$output" == *"[json/format]: Successfully formatted JSON files!"* ]]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
