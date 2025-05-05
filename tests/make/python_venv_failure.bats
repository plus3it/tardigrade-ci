#!/usr/bin/env bats

TEST_DIR="$(pwd)/python_venv_failure"

# create an arbitrary executable for the target to find
function setup() {
rm -rf "$TEST_DIR"
mkdir -p "${TEST_DIR}/venv/bin" "${TEST_DIR}/user/.local/bin"
touch "${TEST_DIR}/venv/bin/test.bat"
chmod +x "${TEST_DIR}/venv/bin/test.bat"
}

@test "python/venv: failure" {
  # If the executable is not found, the target will exit 2
  run make guard/program/test.bat
  [ "$status" -eq 2 ]
  [[ "$output" == *"No rule to make target 'test.bat/install"* ]]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
