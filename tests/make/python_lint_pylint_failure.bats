#!/usr/bin/env bats

TEST_DIR="$(pwd)/python_lint_pylint_failure"

# generate a test terraform project with a nested project
function setup() {
rm -rf "$TEST_DIR"
working_dirs=("$TEST_DIR" "$TEST_DIR/nested")
for working_dir in "${working_dirs[@]}"
do

  mkdir -p "$working_dir"
  cat > "$working_dir/test.py" <<"EOF"

import json
import os
EOF
done

git add "$TEST_DIR/."
git commit -m 'pylint lint failure testing'
}

@test "python/lint pylint: failure" {
  run make python/lint
  [ "$status" -eq 2 ]
}

function teardown() {
  git rm -r -f "$TEST_DIR"
  git reset --hard HEAD^
}
