#!/usr/bin/env bats

TEST_DIR="$(pwd)/eclint_lint_success"

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

git add "$TEST_DIR/."
git commit -m 'eclint success testing'
}

@test "eclint/lint: success" {
  ECLINT_FILES=$(find "${TEST_DIR}" -type f | xargs echo)
  run make eclint/lint ECLINT_FILES="${ECLINT_FILES}"
  [ "$status" -eq 0 ]
}

function teardown() {
  git rm -r -f "$TEST_DIR"
  git reset --hard HEAD^
}
