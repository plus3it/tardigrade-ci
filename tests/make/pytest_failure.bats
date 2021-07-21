#!/usr/bin/env bats

TEST_DIR="$(pwd)/pytest_failure"

# Generate a simple pytest where the test fails.
function setup() {
rm -rf "$TEST_DIR"
working_dir="$TEST_DIR"
mkdir -p "$working_dir"

cat > "$working_dir/bad_test.py" <<"EOF"
"""Simple test of pytest."""
def inc(x):
    """Return x + 1."""
    return x + 1

def test_answer():
    """Test of inc(x)."""
    assert inc(2) == 4
EOF
}

@test "pytest: failure" {
  run make pytest/$TEST_DIR
  [ "$status" -eq 2 ]
  echo $output
  [[ "$output" == *"assert 3 == 4"* ]]
  [[ "$output" == *"FAILED"* ]]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
