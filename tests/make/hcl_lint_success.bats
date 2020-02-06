#!/usr/bin/env bats

TEST_DIR="$(pwd)/hcl_lint_success"

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
echo "foo = \"bar\"" > "$TEST_DIR/top/nested/test.tfvars"
echo "terragrunt {}" > "$TEST_DIR/top/nested/test.hcl"
}

@test "hcl/lint: nested file success" {
  run make hcl/lint
  [ "$status" -eq 0 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
