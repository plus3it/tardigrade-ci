#!/usr/bin/env bats

TEST_DIR="$(pwd)/hcl_lint_failure"

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
echo "test {" > "$TEST_DIR/top/nested/test.tfvars"
echo "test {" > "$TEST_DIR/top/nested/test.hcl"
}

@test "hcl/lint: nested file failure" {
  run make hcl/lint
  [ "$status" -eq 2 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}

