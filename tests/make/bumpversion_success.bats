#!/usr/bin/env bats

TEST_DIR="$(pwd)/bumpversion_success"
BUMPVERSION_FILE="${TEST_DIR}/bumptest.cfg"

function setup() {
  rm -rf "$TEST_DIR"
  mkdir "$TEST_DIR"

  cat > ${BUMPVERSION_FILE} << EOF
[bumpversion]
current_version = 0.0.0
EOF
}

@test "bumpversion: success" {
  BUMPVERSION_ARGS="--config-file ${BUMPVERSION_FILE} --allow-dirty --no-commit"
 
  # Test bumpversion/patch ------------------------------------------------
  run make bumpversion/patch BUMPVERSION_ARGS="${BUMPVERSION_ARGS}"
  [ "$status" -eq 0 ]
  new_version=$(grep "current_version" ${BUMPVERSION_FILE} | cut -d"=" -f 2)
  [[ ${new_version} == " 0.0.1" ]]

  # Test bumpversion/minor ------------------------------------------------
  run make bumpversion/minor BUMPVERSION_ARGS="${BUMPVERSION_ARGS}"
  [ "$status" -eq 0 ]
  new_version=$(grep "current_version" ${BUMPVERSION_FILE} | cut -d"=" -f 2)
  [[ ${new_version} == " 0.1.0" ]]

  # Test bumpversion/major ------------------------------------------------
  run make bumpversion/major BUMPVERSION_ARGS="${BUMPVERSION_ARGS}"
  [ "$status" -eq 0 ]
  new_version=$(grep "current_version" ${BUMPVERSION_FILE} | cut -d"=" -f 2)
  [[ ${new_version} == " 1.0.0" ]]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
