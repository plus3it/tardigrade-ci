#!/usr/bin/env bats

TEST_DIR="$(pwd)/ec_lint_success"

# generate a test terraform project with a nested project
function setup() {
rm -rf "$TEST_DIR"
working_dirs=("$TEST_DIR" "$TEST_DIR/nested")
for working_dir in "${working_dirs[@]}"
do

  mkdir -p "$working_dir"
  cat > "$working_dir/Makefile" <<"EOF"
echo "foo"
EOF

done
}

@test "ec/lint: success" {
  # The 'ec/lint' Makefile target excludes *.bats files.
  ECLINT_FILES="find ${TEST_DIR} -type f | xargs echo"

  run make ec/lint ECLINT_FILES="${ECLINT_FILES}"
  [ "$status" -eq 0 ]
}

function teardown() {
  rm -r -f "$TEST_DIR"
}
