#!/usr/bin/env bats

TEST_DIR="$(pwd)/python_format_success"

# generate a test terraform project with a nested project
function setup() {
rm -rf "$TEST_DIR"
working_dirs=("$TEST_DIR" "$TEST_DIR/nested")
for working_dir in "${working_dirs[@]}"
do

  mkdir -p "$working_dir"
  cat > "$working_dir/test.py" <<"EOF"

print("foo"
EOF
done

}

@test "python/format: failure" {
  run make python/format
  [ "$status" -eq 2 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
