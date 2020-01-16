#!/usr/bin/env bats

TEST_DIR="$(pwd)/terraform_lint_success"

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
  [[ "$output" == *"[terraform/lint]: Terraform files PASSED lint test!"* ]]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
