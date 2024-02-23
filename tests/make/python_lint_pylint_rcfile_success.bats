#!/usr/bin/env bats

TEST_DIR="$(pwd)/python_lint_pylint_rcfile_success"

function setup() {
rm -rf "$TEST_DIR"
working_dirs=("$TEST_DIR" "$TEST_DIR/nested")
for working_dir in "${working_dirs[@]}"
do
  mkdir -p "$working_dir"
  cat > "$working_dir/test_good_length.py" <<"EOF"
"""Test rcfile."""

print("good len")
EOF
done
}

@test "python/lint rcfile: success" {
  # The test .pylintrc file specifies a line length of 20.
  run make PYLINT_RCFILE="./.test_pylintrc" python/lint

  # If there are no pylint issues, there will be no pylint output.
  [ "$status" -eq 0 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
