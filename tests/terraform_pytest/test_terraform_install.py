"""Run Terraform plan/apply against each set of Terraform test files."""

import os
from pathlib import Path

import pytest
import tftest

AWS_DEFAULT_REGION = os.getenv("AWS_DEFAULT_REGION", default="us-east-1")
MOCKSTACK_HOST = os.getenv("MOCKSTACK_HOST", default="localhost")
MOCKSTACK_PORT = "4566"
MOTO_PORT = "4615"

VARIABLES_TF_FILENAME = "test_variables.tf"
MOCKSTACK_TF_FILENAME = "mockstack.tf"
AWS_TF_FILENAME = "aws.tf"


@pytest.fixture(scope="function")
def tf_test_object(is_mock, provider_alias, tf_dir, tmp_path):
    """Return function that will create tf_test object using given subdir."""

    def create_provider_alias_file(alias_path):
        """Create copy of Terraform file to insert alias into provider block.

        It's not possible with Terraform to use a variable for an alias.
        """
        with open(str(alias_path), encoding="utf8") as fhandle:
            all_lines = fhandle.readlines()
        all_lines.insert(1, f'  alias = "{provider_alias}"\n\n')

        path = tmp_path / f"{alias_path.stem}_alias.tf"
        path.write_text("".join(all_lines))
        return str(path)

    def make_tf_test(tf_module):
        """Return a TerraformTest object for given module."""
        tf_test = tftest.TerraformTest(tf_module, basedir=str(tf_dir), env=None)

        # Create a list of provider files that contain endpoints for all
        # the services in use.  The endpoints will be represented by
        # Terraform variables.
        current_dir = Path(__file__).resolve().parent
        copy_files = [str(Path(current_dir / VARIABLES_TF_FILENAME))]

        if is_mock:
            tf_provider_path = Path(current_dir / MOCKSTACK_TF_FILENAME)
        else:
            tf_provider_path = Path(current_dir / AWS_TF_FILENAME)
        copy_files.append(str(tf_provider_path))

        if provider_alias:
            copy_files.append(create_provider_alias_file(tf_provider_path))

        tf_test.setup(extra_files=copy_files)
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

    tf_test = None
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
        if tf_test:
            tf_test.destroy(tf_vars=tf_vars)
        if prereq_tf_test:
            prereq_tf_test.destroy(tf_vars=tf_vars)
