#!/usr/bin/env bats

TEST_DIR="$(pwd)/docs_lint_success"

# generate a test terraform project with a nested "module"
function setup() {
rm -rf "$TEST_DIR"
working_dirs=("$TEST_DIR" "$TEST_DIR/modules/nested")
for working_dir in "${working_dirs[@]}"
do

  mkdir -p "$working_dir"

  cat > "$working_dir/main.tf" <<EOF
variable "foo" {
  default     = "bar"
  type        = string
  description = "test var"
}
EOF
  cat > "$working_dir/README.md" <<"EOF"
# Foo

<!-- BEGIN TFDOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_foo"></a> [foo](#input\_foo) | test var | `string` | `"bar"` | no |

## Outputs

No outputs.

<!-- END TFDOCS -->
EOF
done

}

@test "docs/lint: nested file success" {
  run make docs/lint TFDOCS_PATH="$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"${TEST_DIR}/README.md is up to date"* ]]
  [[ "$output" == *"${TEST_DIR}/modules/nested/README.md is up to date"* ]]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
