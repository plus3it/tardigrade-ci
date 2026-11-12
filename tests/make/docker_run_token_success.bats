#!/usr/bin/env bats

TEST_DIR="$(pwd)/docker_run_token_success"
DUMMY_TOKEN="dummy-token-value-not-real"

# Put a fake docker on the PATH that records its arguments and the value of
# GITHUB_ACCESS_TOKEN in its own environment.
function setup() {
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR/bin"

cat > "$TEST_DIR/bin/docker" <<"EOF"
#!/bin/bash
case "$1" in
  --version) echo "Docker version 0.0.0" ;;
  image) ;;
  run)
    printf '%s\n' "$@" > "$DOCKER_ARGS_FILE"
    printf '%s' "${GITHUB_ACCESS_TOKEN-unset}" > "$DOCKER_ENV_FILE"
    ;;
esac
EOF
chmod +x "$TEST_DIR/bin/docker"
}

@test "docker/run: GITHUB_ACCESS_TOKEN value is not in the docker run arguments" {
  export PATH="$TEST_DIR/bin:$PATH"
  export DOCKER_ARGS_FILE="$TEST_DIR/args"
  export DOCKER_ENV_FILE="$TEST_DIR/env"
  export GITHUB_ACCESS_TOKEN="$DUMMY_TOKEN"

  run make docker/run target=help
  [ "$status" -eq 0 ]

  # The variable is passed by name only, and docker reads it from its environment
  grep -qx -- "GITHUB_ACCESS_TOKEN" "$DOCKER_ARGS_FILE"
  [ "$(cat "$DOCKER_ENV_FILE")" = "$DUMMY_TOKEN" ]

  # The value is not anywhere in the arguments
  ! grep -q -- "$DUMMY_TOKEN" "$DOCKER_ARGS_FILE"
}

function teardown() {
  rm -rf "$TEST_DIR"
}
