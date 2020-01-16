#!/usr/bin/env bats

TEST_DIR="$(pwd)/terraform_format_failure"

function setup() {
mkdir -p "$TEST_DIR/top/nested"
cat > "$TEST_DIR/top/nested/main.tf" <<-EOF
variable "foo"
default = "bar"
}
EOF
}

@test "terraform/format: nested file failure" {
  run make terraform/format
  [ "$status" -eq 2 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}

