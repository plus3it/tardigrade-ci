#!/usr/bin/env bats

TEST_DIR="$(pwd)/docs_generate_success"

# generate a test terraform project with a nested "module"
function setup() {
rm -rf "$TEST_DIR"
working_dirs=("$TEST_DIR" "$TEST_DIR/modules/nested")
for working_dir in "${working_dirs[@]}"
do

  mkdir -p "$working_dir"
  cat > "$working_dir/main.tf" <<"EOF"
  variable "foo" {
    default     = "bar"
    type        = string
    description = "test var"
  }
EOF
  cat > "$working_dir/README.md" <<"EOF"
# Foo

<!-- BEGIN TFDOCS -->
<!-- END TFDOCS -->
EOF
done

}

@test "docs/generate: nested file success" {
  run make docs/generate TFDOCS_PATH="$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"${TEST_DIR}/README.md updated successfully"* ]]
  [[ "$output" == *"${TEST_DIR}/modules/nested/README.md updated successfully"* ]]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
