#!/usr/bin/env bats

DIR="$(pwd)"
TEST_DIR="$DIR/terraform_lint_success"

function setup() {
mkdir -p "$TEST_DIR/top/nested"
cat > "$TEST_DIR/top/nested/main.tf" <<-EOF
variable "foo" {
  default = "bar"
}

output "baz" {
  value = var.foo
}
EOF
}

@test "terraform/lint: nested file success" {
  run make terraform/lint
  [ "$status" -eq 0 ]
  [ "${lines[2]}" = "[terraform/lint]: Terraform files PASSED lint test!" ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
