#!/usr/bin/env bats

TEST_DIR="$(pwd)/python_lint_pydocstyle_failure"

# generate a test terraform project with a nested project
function setup() {
rm -rf "$TEST_DIR"
working_dirs=("$TEST_DIR" "$TEST_DIR/nested")
for working_dir in "${working_dirs[@]}"
do

  mkdir -p "$working_dir"
  cat > "$working_dir/test.py" <<"EOF"
"""Simple test for pydocstyle
testing docstring style
"""
import os


def testing():
    """This should print the current OS name"""

    print(os.name)
EOF
done
}

@test "python/lint pydocstyle: failure" {
  run make python/lint
  [ "$status" -eq 2 ]
  [[ "$output" == *"D205: 1 blank line required between summary line and description"* ]]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
