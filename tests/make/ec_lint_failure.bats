#!/usr/bin/env bats

# NOTE: edit this file in an editor not configured to auto remediate
# required editor config changes (vim, nano, etc)

TEST_DIR="$(pwd)/ec_lint_failure"

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

@test "ec/lint: failure" {
  # The 'ec/lint' Makefile target excludes *.bats files.
  ECLINT_FILES=$(find "${TEST_DIR}" -type f | xargs echo)

  run make ec/lint ECLINT_FILES="${ECLINT_FILES}"
  echo "${output}"
  [ "$status" -eq 2 ]
}

function teardown() {
  rm -r -f "$TEST_DIR"
}
