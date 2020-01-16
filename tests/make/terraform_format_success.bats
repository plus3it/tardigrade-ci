#!/usr/bin/env bats

TEST_DIR="$(pwd)/terraform_format_success"

function setup() {
mkdir -p "$TEST_DIR/top/nested"
cat > "$TEST_DIR/top/nested/main.tf" <<-EOF
variable "foo" {
default = "bar"
}
EOF
}

@test "terraform/format: nested file success" {
  run make terraform/format
  [ "$status" -eq 0 ]
  [[ "$output" == *"[terraform/format]: Successfully formatted terraform files!"* ]]
}

function teardown() {
  rm -rf "$TEST_DIR"
}

