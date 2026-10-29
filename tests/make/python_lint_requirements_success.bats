#!/usr/bin/env bats

TEST_DIR="$(pwd)/python_lint_requirements_success"
REQUIREMENTS_FILE="$(pwd)/requirements-lint.txt"

# generate a python file that imports a package that is not in the venv, and a
# requirements file that provides it
function setup() {
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
cat > "$TEST_DIR/test.py" <<"EOF2"
"""Simple test of pylint with a lint requirement."""

import tabulate

print(tabulate.__name__)
EOF2
echo "tabulate" > "$REQUIREMENTS_FILE"
}

@test "python/lint requirements: success" {
  run make python/lint
  [ "$status" -eq 0 ]
}

function teardown() {
  rm -rf "$TEST_DIR" "$REQUIREMENTS_FILE"
  uv pip uninstall tabulate || true
}
