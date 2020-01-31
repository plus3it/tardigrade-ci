#!/usr/bin/env bats

TEST_DIR="$(pwd)/yaml_lint_success"

# generate a test terraform project with a nested project
function setup() {
rm -rf "$TEST_DIR"
working_dirs=("$TEST_DIR" "$TEST_DIR/nested")
for working_dir in "${working_dirs[@]}"
do

  mkdir -p "$working_dir"
  cat > "$working_dir/test.yml" <<"EOF"
foo: "bar"
EOF
done

}

@test "yaml/lint: success" {
  run make yaml/lint
  [ "$status" -eq 0 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
