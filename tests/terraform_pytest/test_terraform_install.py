"""Run Terraform plan/apply against each set of Terraform test files."""

import os
from pathlib import Path

import pytest
import tftest

AWS_DEFAULT_REGION = os.getenv("AWS_REGION", default="us-east-1")

LOCALSTACK_TF_FILENAME = "localstack.tf"
MOTO_TF_FILENAME = "moto.tf"
AWS_TF_FILENAME = "aws.tf"


@pytest.fixture(scope="function")
def plan_and_apply(is_mock, use_moto, repo_root_dir):
    """Return the function that will invoke Terraform plan and apply."""

    def invoke_plan_and_apply(tf_module):
        """Execute Terraform plan and apply."""
        tf_dir = Path(repo_root_dir / "tests")
        tf_test = tftest.TerraformTest(tf_module, basedir=str(tf_dir), env=None)

        # Use the appropriate endpoints, either for a simulated AWS stack
        # or the real deal.
        provider_tf = AWS_TF_FILENAME
        if is_mock:
            provider_tf = MOTO_TF_FILENAME if use_moto else LOCALSTACK_TF_FILENAME

        current_dir = Path(__file__).resolve().parent
        tf_test.setup(extra_files=[str(Path(current_dir / provider_tf))])

        # tftest's plan() will raise an exception if the return code is 1.
        # Otherwise, it returns the text of the plan output.  Adding an
        # argument of "output=True" will return an object that has members for
        # outputs, resources, modules and variables.  For this test, we're
        # simply looking for pass or fail.
        #
        # tftest's apply() will also raise an exception if the return code
        # is 1.  Otherwise, it returns the output as plain text.
        try:
            tf_test.plan()
            tf_test.apply()
        except tftest.TerraformTestError as exc:
            pytest.exit(
                msg=f"catastropic error running Terraform 'plan' or 'apply':  {exc}",
                returncode=1,
            )
        finally:
            tf_test.destroy()

    return invoke_plan_and_apply


def test_modules(subdir, monkeypatch, plan_and_apply):
    """Run plan/apply against a Terraform module found in tests subdir."""
    monkeypatch.setenv("AWS_DEFAULT_REGION", AWS_DEFAULT_REGION)

    # Run the Terraform module in "prereq" before executing the module itself.
    if Path(subdir / "prereq").exists():
        plan_and_apply(str(subdir / "prereq"))
    plan_and_apply(str(subdir))
