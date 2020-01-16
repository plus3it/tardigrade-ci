#!/usr/bin/env bats

TEST_DIR="$(pwd)/json_lint_failure"

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
}

function teardown() {
  rm -rf "$TEST_DIR"
}
