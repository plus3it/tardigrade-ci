"""Run Terraform plan/apply against each set of Terraform test files."""

import os
from pathlib import Path

import pytest
import tftest

AWS_DEFAULT_REGION = os.getenv("AWS_DEFAULT_REGION", default="us-east-1")
MOCKSTACK_HOST = os.getenv("MOCKSTACK_HOST", default="localhost")
MOCKSTACK_PORT = "4566"
MOTO_PORT = "4615"

MOCKSTACK_TF_FILENAME = "mockstack.tf"
AWS_TF_FILENAME = "aws.tf"


@pytest.fixture(scope="function")
def tf_test_object(is_mock, tf_dir):
    """Return function that will create tf_test object using given subdir."""

    def make_tf_test(tf_module):
        """Return a TerraformTest object for given module."""
        tf_test = tftest.TerraformTest(tf_module, basedir=str(tf_dir), env=None)

        # Use the appropriate endpoints, either for a simulated AWS stack
        # or the real deal.
        provider_tf = MOCKSTACK_TF_FILENAME if is_mock else AWS_TF_FILENAME

        current_dir = Path(__file__).resolve().parent
        tf_test.setup(extra_files=[str(Path(current_dir / provider_tf))])
        return tf_test

    return make_tf_test


@pytest.fixture(scope="function")
def tf_vars(is_mock):
    """Return values for variables used for the Terraform apply.

    Set the Terraform variables for the hostname and port to differentiate
    between using "localhost" or the docker network name.
    """
    return (
        {
            "mockstack_host": MOCKSTACK_HOST,
            "mockstack_port": MOCKSTACK_PORT,
            "moto_port": MOTO_PORT,
        }
        if is_mock
        else {}
    )


def test_modules(subdir, monkeypatch, tf_test_object, tf_vars):
    """Run plan/apply against a Terraform module found in tests subdir."""
    monkeypatch.setenv("AWS_DEFAULT_REGION", AWS_DEFAULT_REGION)

    prereq_tf_test = None
    try:
        # Run the Terraform module in "prereq" before executing the test
        # itself.
        if Path(subdir / "prereq").exists():
            prereq_tf_test = tf_test_object(str(subdir / "prereq"))
            prereq_tf_test.apply(tf_vars=tf_vars)

        # Apply the plan for the module under test.
        tf_test = tf_test_object(str(subdir))
        tf_test.apply(tf_vars=tf_vars)
    except tftest.TerraformTestError as exc:
        pytest.exit(
            msg=f"catastropic error running Terraform 'apply': {exc}",
            returncode=1,
        )
    finally:
        # Destroy the resources for the module under test, then destroy the
        # "prereq" resources, if a "prereq" subdirectory exists.
        if prereq_tf_test:
            prereq_tf_test.destroy(tf_vars=tf_vars)
        tf_test.destroy(tf_vars=tf_vars)
