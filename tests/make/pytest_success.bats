#!/usr/bin/env bats

TEST_DIR="$(pwd)/pytest_success"

# Generate a simple pytest where the test succeeds.
function setup() {
rm -rf "$TEST_DIR"
working_dir="$TEST_DIR"
mkdir -p "$working_dir"

cat > "$working_dir/good_test.py" <<"EOF"
"""Simple test of pytest."""
def inc(x):
    """Return x + 1."""
    return x + 1

def test_answer():
    """Test of inc(x)."""
    assert inc(2) == 3
EOF
}

@test "pytest: success" {
  run make pytest/$TEST_DIR
  [ "$status" -eq 0 ]
}

function teardown() {
  rm -rf "$TEST_DIR"
}
