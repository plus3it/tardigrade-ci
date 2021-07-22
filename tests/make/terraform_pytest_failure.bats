#!/usr/bin/env bats

TEST_DIR="$(pwd)/terraform_pytest_failure"

function setup() {
rm -rf "$TEST_DIR"
working_dirs=("$TEST_DIR/test" "$TEST_DIR/test/prereq")

# Bad prereq Terraform file
mkdir -p "$TEST_DIR/test/prereq"
cat > "$TEST_DIR/test/prereq/main.tf" <<-EOF
variable "foo" {
  default = "bar"
}

output "baz" {
  # this variable does not exist
  value = var.bar
}
EOF

# Good Terraform file
mkdir -p "$TEST_DIR/test"
cat > "$TEST_DIR/test/main.tf" <<-EOF
variable "foo" {
  default = "bar"
}

output "baz" {
  value = foo.bar
}
EOF
}

@test "test: terraform pytest failure" {
  run make terraform/pytest TERRAFORM_PYTEST_DIR=../terraform_pytest PYTEST_ARGS="-v --tf-dir $TEST_DIR"
  [ "$status" -eq 2 ]
  [[ "$output" == *"FAILED ../terraform_pytest/test_terraform_install.py::test_modules[test]"* ]]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
