#!/usr/bin/env bats

TEST_DIR="$(pwd)/python_lint_black_failure"

# generate a test terraform project with a nested project
function setup() {
rm -rf "$TEST_DIR"
working_dirs=("$TEST_DIR" "$TEST_DIR/nested")
for working_dir in "${working_dirs[@]}"
do

  mkdir -p "$working_dir"
  cat > "$working_dir/test.py" <<"EOF"

test_dict == { key1: 1, key2: 2, key3: 3, key4: 4, key5: 5, key6: 6, key7: 7, ke
y8: 8, key9: 9, }
EOF
done

}

@test "python/lint black: failure" {
  run make python/lint
  [ "$status" -eq 1 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
