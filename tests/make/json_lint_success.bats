#!/usr/bin/env bats

TEST_DIR="$(pwd)/json_lint_success"

function setup() {
mkdir -p "$TEST_DIR/top/nested"
cat > "$TEST_DIR/top/success.json" <<-EOF
{
    "foo": "bar"
}
EOF
}

@test "json/lint: nested file success" {
  run make json/lint
  [ "$status" -eq 0 ]
  [[ "$output" == *"[json/lint]: JSON files PASSED lint test!"* ]]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
