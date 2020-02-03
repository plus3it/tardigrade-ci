#!/usr/bin/env bats

TEST_DIR="$(pwd)/yaml_lint_failure"

# generate a test terraform project with a nested project
function setup() {
rm -rf "$TEST_DIR"
working_dirs=("$TEST_DIR" "$TEST_DIR/nested")
for working_dir in "${working_dirs[@]}"
do

  mkdir -p "$working_dir"
  echo "foo: \"bar" > $working_dir/test.yml
done

}

@test "yaml/lint: failure" {
  run make yaml/lint
  [ "$status" -eq 2 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
