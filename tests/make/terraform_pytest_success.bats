#!/usr/bin/env bats

TEST_DIR="$(pwd)/terraform_pytest_success"

function setup() {
rm -rf "$TEST_DIR"
working_dirs=("$TEST_DIR/test" "$TEST_DIR/test/prereq")
for working_dir in "${working_dirs[@]}"
do

  mkdir -p "$working_dir"
  cat > "$working_dir/main.tf" <<-EOF
variable "foo" {
  default = "bar"
}

output "baz" {
  value = var.foo
}
EOF
done
}

@test "test: terraform pytest success" {
  run make terraform/pytest TERRAFORM_PYTEST_DIR=../terraform_pytest TERRAFORM_PYTEST_ARGS="--tf-dir $TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"test_modules[test] PASSED [100%]"* ]]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
