#!/usr/bin/env bats

DIR="$(pwd)"
TEST_DIR="$DIR/json_format_failure"

function setup() {
mkdir -p "$TEST_DIR/top/nested"
cat > "$TEST_DIR/top/failure.json" <<-EOF
{
"foo": "bar"

EOF
}

# this make target needs to be fleshed out..
# b/c we're running jq in a subshell errors aren't being properly passed to the parent
# this has the added bonus of blanking out any improperly formatted json files.
@test "json/format: nested file failure" {
  run make json/format
  [ "$status" -eq 0 ]
  # [ "${lines[3]}" = "parse error: Invalid numeric literal at line 3, column 0" ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
