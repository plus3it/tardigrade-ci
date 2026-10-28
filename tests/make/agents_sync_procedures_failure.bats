#!/usr/bin/env bats

TEST_DIR="$(pwd)/agents_sync_procedures_failure"
REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
TEMPLATE_DIR="$TEST_DIR/template"
EMPTY_DIR="$TEST_DIR/empty-template"
WORK_DIR="$TEST_DIR/work"
PIN_FILE=".github/workflows/dependabot_hack.yml"

function setup() {
  rm -rf "$TEST_DIR"
  mkdir -p "$TEMPLATE_DIR/agents/procedures" "$EMPTY_DIR" "$WORK_DIR/.github/workflows"
  echo "# Stacks" > "$TEMPLATE_DIR/agents/procedures/stacks.md"
  echo "# Readme" > "$EMPTY_DIR/README.md"
  for dir in "$TEMPLATE_DIR" "$EMPTY_DIR"; do
    git -C "$dir" init -q
    git -C "$dir" add .
    git -C "$dir" -c user.name=test -c user.email=test@example.com commit -q -m "init"
    git -C "$dir" tag 1.2.3
  done
  echo "      - uses: plus3it/tardigrade@1.2.3" > "$WORK_DIR/$PIN_FILE"
}

@test "agents/sync: pinned tag without procedures fails and creates nothing" {
  echo "      - uses: ${EMPTY_DIR#/}@1.2.3" > "$WORK_DIR/$PIN_FILE"
  run bash -c "cd '$WORK_DIR' && make -f '$REPO_ROOT/Makefile' agents/sync TARDIGRADE_CI_PATH='$REPO_ROOT' AGENTS_PROFILE=tardigrade-deployment TARDIGRADE_GIT_URL='$EMPTY_DIR'"
  [ "$status" -ne 0 ]
  [[ "$output" == *"ERROR: Tag 1.2.3 of ${EMPTY_DIR#/} "* ]]
  [[ "$output" == *"has no agents/procedures/*.md"* ]]
  [ ! -e "$WORK_DIR/.agents" ]
}

@test "agents/sync: TARDIGRADE_PATH without procedures fails and creates nothing" {
  run bash -c "cd '$WORK_DIR' && make -f '$REPO_ROOT/Makefile' agents/sync TARDIGRADE_CI_PATH='$REPO_ROOT' AGENTS_PROFILE=tardigrade-deployment TARDIGRADE_PATH='$EMPTY_DIR'"
  [ "$status" -ne 0 ]
  [[ "$output" == *"has no agents/procedures/*.md"* ]]
  [ ! -e "$WORK_DIR/.agents" ]
}

@test "agents/sync: pinned tag that cannot be downloaded fails and creates nothing" {
  echo "      - uses: ${TEMPLATE_DIR#/}@9.9.9" > "$WORK_DIR/$PIN_FILE"
  run bash -c "cd '$WORK_DIR' && make -f '$REPO_ROOT/Makefile' agents/sync TARDIGRADE_CI_PATH='$REPO_ROOT' AGENTS_PROFILE=tardigrade-deployment TARDIGRADE_GIT_URL='$TEMPLATE_DIR'"
  [ "$status" -ne 0 ]
  [[ "$output" == *"ERROR: Could not download tag 9.9.9"* ]]
  [ ! -e "$WORK_DIR/.agents" ]
}

@test "agents/sync: a failed sync leaves the previous sync untouched" {
  echo "      - uses: ${TEMPLATE_DIR#/}@1.2.3" > "$WORK_DIR/$PIN_FILE"
  run bash -c "cd '$WORK_DIR' && make -f '$REPO_ROOT/Makefile' agents/sync TARDIGRADE_CI_PATH='$REPO_ROOT' AGENTS_PROFILE=tardigrade-deployment TARDIGRADE_GIT_URL='$TEMPLATE_DIR'"
  [ "$status" -eq 0 ]
  cp -r "$WORK_DIR/.agents" "$TEST_DIR/before"
  echo "      - uses: ${TEMPLATE_DIR#/}@9.9.9" > "$WORK_DIR/$PIN_FILE"
  run bash -c "cd '$WORK_DIR' && make -f '$REPO_ROOT/Makefile' agents/sync TARDIGRADE_CI_PATH='$REPO_ROOT' AGENTS_PROFILE=tardigrade-deployment TARDIGRADE_GIT_URL='$TEMPLATE_DIR'"
  [ "$status" -ne 0 ]
  run diff -r "$TEST_DIR/before" "$WORK_DIR/.agents"
  [ "$status" -eq 0 ]
}

@test "agents/sync: a URL with no project path fails and creates nothing" {
  run bash -c "cd '$WORK_DIR' && make -f '$REPO_ROOT/Makefile' agents/sync TARDIGRADE_CI_PATH='$REPO_ROOT' AGENTS_PROFILE=tardigrade-deployment TARDIGRADE_PATH='$TEMPLATE_DIR' TARDIGRADE_GIT_URL='https://git.example.com/'"
  [ "$status" -ne 0 ]
  [[ "$output" == *"ERROR: Could not derive the template project from TARDIGRADE_GIT_URL"* ]]
  [ ! -e "$WORK_DIR/.agents" ]
}

@test "agents/sync: unknown profile fails first even with a pin" {
  run bash -c "cd '$WORK_DIR' && make -f '$REPO_ROOT/Makefile' agents/sync TARDIGRADE_CI_PATH='$REPO_ROOT' AGENTS_PROFILE=nonexistent-profile TARDIGRADE_PATH='$TEMPLATE_DIR'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"ERROR: Profile 'nonexistent-profile' does not exist"* ]]
  [ ! -e "$WORK_DIR/.agents" ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
