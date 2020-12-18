#!/usr/bin/env bats

TEST_DIR="$(pwd)/python_lint_pydocstyle_success"

# generate a test terraform project with a nested project
function setup() {
rm -rf "$TEST_DIR"
working_dirs=("$TEST_DIR" "$TEST_DIR/nested")
for working_dir in "${working_dirs[@]}"
do

  mkdir -p "$working_dir"
  cat > "$working_dir/test.py" <<"EOF"
"""Simple test for pydocstyle."""
import os


def testing():
    """Print the current OS name."""
    print(os.name)
EOF
done
}

@test "python/lint pydocstyle: success" {
  run make python/lint
  # If there are no pydocstyle issues, there will be no pydocstyle output.
  [ "$status" -eq 0 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
