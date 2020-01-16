#!/usr/bin/env bats

TEST_DIR="$(pwd)/terraform_lint_failure"

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

@test "terraform/lint: nested file failure" {
  run make terraform/lint
  [ "$status" -eq 2 ]
  [[ "$output" == *"@@ -1,5 +1,5 @@"* ]]
}

function teardown() {
  rm -rf "$TEST_DIR"
}

