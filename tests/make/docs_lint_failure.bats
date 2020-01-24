#!/usr/bin/env bats

TEST_DIR="$(pwd)/docs_lint_failure"

# generate a test terraform project with a nested "module"
function setup() {
rm -rf "$TEST_DIR"
working_dirs=("$TEST_DIR" "$TEST_DIR/nested")
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
  # intentionally generate incomplete READMEs
  cat > "$working_dir/README.md" <<EOF
# Foo

<!-- BEGIN TFDOCS -->

bar

<!-- END TFDOCS -->
EOF
done

}

@test "docs/lint: nested file failure" {
  run make docs/lint
  [ "$status" -eq 2 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
