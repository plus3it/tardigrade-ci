#!/usr/bin/env bats

DIR="$(pwd)"
TEST_DIR="$DIR/docs_generate_success"

# generate a test terraform project with a nested "module"
function setup() {
working_dirs=("$TEST_DIR/top" "$TEST_DIR/top/nested")
for working_dir in "${working_dirs[@]}"
do
  mkdir -p "$working_dir/_docs"
  cat > "$working_dir/main.tf" <<EOF
  variable "foo" {
    default     = "bar"
    type        = string
    description = "test var"

EOF

  cat > "$working_dir/_docs/MAIN.md" <<EOF
  # Test
EOF
done

}

@test "docs/generate: nested file failure" {
  run make docs/generate
  [ "$status" -eq 2 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
