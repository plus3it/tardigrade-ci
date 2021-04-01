#!/usr/bin/env bats

TEST_DIR="$(pwd)/golang_format_success"

# generate a nested test project
function setup() {
rm -rf "$TEST_DIR"
working_dirs=("$TEST_DIR" "$TEST_DIR/nested")
for working_dir in "${working_dirs[@]}"
do

  mkdir -p "$working_dir"
  cat > "$working_dir/test.go" <<"EOF"
package main

import (
	"fmt"
)

type person struct {
	surname string
	age     int
}

func main() {
	fmt.Println(person{"Bob", 20})
}
EOF
  cp "$working_dir/test.go" "$working_dir/test.original"
done
}

@test "golang/format: success" {
  run make golang/format
  [ "$status" -eq 0 ]

  diff "$TEST_DIR/test.go" "$TEST_DIR/test.original"
  [ "$status" -eq 0 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
