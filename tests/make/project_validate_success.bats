#!/usr/bin/env bats

TEST_DIR="$(pwd)/project_validate_success"

# generate folders with content
function setup() {
rm -rf "$TEST_DIR"
working_dirs=("$TEST_DIR" "$TEST_DIR/nested")
for working_dir in "${working_dirs[@]}"
do

  mkdir -p "$working_dir"
  cat > "$working_dir/test.py" <<"EOF"

print("foo")
EOF
done

}

@test "project/validate: success" {
  run make project/validate
  [ "$status" -eq 0 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
