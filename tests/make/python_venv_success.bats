#!/usr/bin/env bats

TEST_DIR="$(pwd)/python_venv_success"

# create an arbitrary executable for the target to find
function setup() {
rm -rf "$TEST_DIR"
mkdir -p "${TEST_DIR}/venv/bin" "${TEST_DIR}/user/.local/bin"
touch "${TEST_DIR}/venv/bin/test.bat"
chmod +x "${TEST_DIR}/venv/bin/test.bat"
export VIRTUAL_ENV="${TEST_DIR}/venv"
export PYTHONUSERBASE="${TEST_DIR}/user/.local"
}

@test "python/venv: success" {
  # If the executable is found, the target will exit 0
  run make guard/program/test.bat
  [ "$status" -eq 0 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
