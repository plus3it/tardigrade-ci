#!/usr/bin/env bats

TEST_DIR="$(pwd)/eclint_lint_failure"

# generate a test terraform project with a nested project
function setup() {
rm -rf "$TEST_DIR"
working_dirs=("$TEST_DIR" "$TEST_DIR/nested")
for working_dir in "${working_dirs[@]}"
do

  mkdir -p "$working_dir"
  cat > "$working_dir/testfile.txt" <<"EOF"
trailing whitespace test

		indent style test

   indent size test
EOF
done

}

@test "eclint/lint: unstaged commit failure" {
  run make eclint/lint
  [ "$status" -eq 2 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
