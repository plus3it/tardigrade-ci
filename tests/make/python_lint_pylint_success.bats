#!/usr/bin/env bats

TEST_DIR="$(pwd)/python_lint_pylint_success"

# generate a test terraform project with a nested project
function setup() {
rm -rf "$TEST_DIR"
working_dirs=("$TEST_DIR" "$TEST_DIR/nested")
for working_dir in "${working_dirs[@]}"
do

  mkdir -p "$working_dir"
  cat > "$working_dir/test.py" <<"EOF"
"""Simple test of pylint"""
import os

print(os.name)
EOF
done

git add "$TEST_DIR/."
git commit -m 'pylint lint success testing'
}

@test "python/lint pylint: success" {
  run make python/lint
  [ "$status" -eq 0 ]
}

function teardown() {
  git rm -r -f "$TEST_DIR"
  git reset --hard HEAD^
}
