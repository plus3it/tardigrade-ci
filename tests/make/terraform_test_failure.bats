#!/usr/bin/env bats

TEST_DIR="$(pwd)/../terraform"

function setup() {
cat > "$TEST_DIR/main.tf" <<-EOF
variable "foo" {
  default = "bar"
}

output "baz" {
  # this variable does not exist
  value = var.bar
}
EOF
}

@test "test: terraform test failure" {
  run make TERRAFORM_TEST_DIR="../terraform" test
  [ "$status" -eq 2 ]
}

function teardown() {
  find "$TEST_DIR/example_testcase" -name "*terraform*" -exec rm -rf {} \;
  rm $TEST_DIR/main.tf
}
