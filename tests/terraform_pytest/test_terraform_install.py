"""Run Terraform plan/apply against each set of Terraform test files."""

import os
from pathlib import Path

import pytest
import tftest

AWS_DEFAULT_REGION = os.getenv("AWS_DEFAULT_REGION", default="us-east-1")
MOCKSTACK_HOST = os.getenv("MOCKSTACK_HOST", default="localhost")
MOCKSTACK_PORT = "4566"

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
        }
        if is_mock
        else {}
    )


@pytest.fixture(scope="function")
def apply_plan(tf_vars):
    """Return function that can be invoked with tf_test parameter."""

    def invoke_plan_and_apply(tf_test):
        """Execute Terraform plan and apply."""
        # Debugging info:  tftest's plan() will raise an exception if the
        # return code is 1.  Otherwise, it returns the text of the plan
        # output.  Adding an argument of "output=True" will return an object
        # that has members for outputs, resources, modules and variables.
        # For this test, we're simply looking for pass or fail.
        #
        # tftest's apply() will also raise an exception if the return code
        # is 1.  Otherwise, it returns the output as plain text.
        try:
            tf_test.apply(tf_vars=tf_vars)
        except tftest.TerraformTestError as exc:
            tf_test.destroy(tf_vars=tf_vars)
            pytest.exit(
                msg=f"catastropic error running Terraform 'apply':  {exc}",
                returncode=1,
            )

    return invoke_plan_and_apply


def test_modules(subdir, monkeypatch, tf_test_object, tf_vars, apply_plan):
    """Run plan/apply against a Terraform module found in tests subdir."""
    monkeypatch.setenv("AWS_DEFAULT_REGION", AWS_DEFAULT_REGION)

    # Run the Terraform module in "prereq" before executing the test itself.
    prereq_tf_test = None
    if Path(subdir / "prereq").exists():
        prereq_tf_test = tf_test_object(str(subdir / "prereq"))
        apply_plan(prereq_tf_test)

    # Apply the plan for the module under test.
    tf_test = tf_test_object(str(subdir))
    apply_plan(tf_test)

    # Destroy the "prereq" resources if a "prereq" subdirectory exists, then
    # resources for the module under test.
    if prereq_tf_test:
        prereq_tf_test.destroy(tf_vars=tf_vars)
    tf_test.destroy(tf_vars=tf_vars)
