#!/usr/bin/env bats

TEST_DIR="$(pwd)/cfn_lint_success"

# generate a test terraform project with a nested "module"
function setup() {
rm -rf "$TEST_DIR"
working_dirs=("$TEST_DIR" "$TEST_DIR/nested")
for working_dir in "${working_dirs[@]}"
do

  mkdir -p "$working_dir"
  cat > "$working_dir/test.template.cfn.json" <<"EOF"
{
  "AWSTemplateFormatVersion" : "2010-09-09",

  "Description" : "AWS CloudFormation Sample Template S3 Bucket.",

  "Resources" : {
    "S3Bucket" : {
      "Type" : "AWS::S3::Bucket"
    }
  }
}
EOF

  cat > "$working_dir/test.template.cfn.yaml" <<"EOF"
AWSTemplateFormatVersion: 2010-09-09
Description: >-
  AWS CloudFormation Sample Template S3 Bucket.
Resources:
  S3Bucket:
    Type: 'AWS::S3::Bucket'
EOF
done

}

@test "cfn/lint: nested file success" {
  run make cfn/lint
  [ "$status" -eq 0 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
