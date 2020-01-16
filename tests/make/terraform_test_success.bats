#!/usr/bin/env bats


DIR="$(pwd)"
TEST_DIR="$DIR/../terraform"

function setup() {
cat > "$TEST_DIR/main.tf" <<-EOF
variable "foo" {
  default = "bar"
}

output "baz" {
  value = var.foo
}
EOF
}


@test "test: terraform test success" {
  run make TERRAFORM_TEST_DIR="../terraform" test
  [ "$status" -eq 0 ]
}

function teardown() {
  find "$TEST_DIR/example_testcase/" -name "*terraform*" -exec rm -rf {} \;
  rm $TEST_DIR/main.tf
}
