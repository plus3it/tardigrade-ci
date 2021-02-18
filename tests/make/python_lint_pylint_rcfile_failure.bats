#!/usr/bin/env bats

TEST_DIR="$(pwd)/python_lint_pylint_rcfile_failure"

function setup() {
rm -rf "$TEST_DIR"
working_dirs=("$TEST_DIR" "$TEST_DIR/nested")
for working_dir in "${working_dirs[@]}"
do
  mkdir -p "$working_dir"
  cat > "$working_dir/test_long_line.py" <<"EOF"
"""Pylintrc test."""
print("Line is more than 20 characters long")
EOF
done
}

@test "python/lint rcfile: failure" {
  # The test .pylintrc file specifies a line length of 20.
  run make PYLINT_RCFILE="./.test_pylintrc" python/lint
  [ "$status" -eq 2 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
