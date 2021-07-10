"""Fixtures and command line processing for testing Terraform installation."""
from pathlib import Path

import pytest

DEFAULT_PROFILE_NAME = "tester"
ALTERNATE_PROFILE_NAME = "alternate_tester"


def pytest_addoption(parser):
    """Process command line options."""
    parser.addoption(
        "--nomock", action="store_true", help="Use AWS, not mocked AWS services"
    )
    parser.addoption(
        "--alternate-profile",
        action="store_true",
        help="Configure an alternate profile in addition to default profile",
    )
    parser.addoption(
        "--tf-dir",
        action="store",
        default=str(Path(Path.cwd() / "tests")),
        help="Directory of Terraform files under test; default: './tests'",
    )


@pytest.fixture(scope="function")
def aws_credentials(tmpdir, monkeypatch):
    """Return the function that creates mocked AWS credentials."""
    # It would make more sense for this fixture to have a scope of "session",
    # but unfortunately, monkeypatch does not support that scope.

    def create_aws_credentials(profile_names):
        """Create mocked AWS credentials."""
        # Create a temporary AWS credentials file.
        aws_creds = []
        for profile_name in profile_names:
            aws_creds.extend(
                [
                    f"[{profile_name}]",
                    "aws_access_key_id = testing",
                    "aws_secret_access_key = testing",
                ]
            )
        path = tmpdir.join("aws_test_creds")
        path.write("\n".join(aws_creds))
        monkeypatch.setenv("AWS_SHARED_CREDENTIALS_FILE", str(path))

        # Ensure that any existing AWS-related environment variables are
        # overridden with 'mock' values.
        monkeypatch.setenv("AWS_ACCESS_KEY_ID", "testing")
        monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "testing")
        monkeypatch.setenv("AWS_SECURITY_TOKEN", "testing")
        monkeypatch.setenv("AWS_SESSION_TOKEN", "testing")
        monkeypatch.setenv("AWS_PROFILE", DEFAULT_PROFILE_NAME)
        if ALTERNATE_PROFILE_NAME in profile_names:
            monkeypatch.setenv("AWS_ALTERNATE_PROFILE", ALTERNATE_PROFILE_NAME)

    return create_aws_credentials


@pytest.fixture(scope="function")
def is_mock(request, aws_credentials):
    """Return True if testing is to use mocked services, False otherwise.

    In addition, if mocking, create the mock AWS credentials.
    """
    if not request.config.option.nomock:
        profile_names = [DEFAULT_PROFILE_NAME]
        if request.config.option.alternate_profile:
            profile_names.append(ALTERNATE_PROFILE_NAME)
        aws_credentials(profile_names)
        return True

    if request.config.option.alternate_profile:
        pytest.exit(msg="conflicting options: 'alternate_profile' and 'nomock'")
    return False


@pytest.fixture(scope="session")
def tf_dir(request):
    """Return Path of directory where Terraform files are located."""
    terraform_dir = request.config.getoption("--tf-dir")
    if not Path(terraform_dir).exists():
        pytest.exit(msg=f"'{terraform_dir}' is a non-existent directory")
    return Path(terraform_dir).resolve()


def pytest_generate_tests(metafunc):
    """Generate list of subdirectories under test.

    Each subdirectory represents a different Terraform module.
    """
    # Can't use the fixture "test_dir" as pytest_generate_tests() does not
    # allow fixtures as arguments.
    terraform_dir = metafunc.config.getoption("--tf-dir")
    if not Path(terraform_dir).exists():
        pytest.exit(msg=f"'{terraform_dir}' is a non-existent directory")
    terraform_dir = Path(terraform_dir).resolve()

    subdirs = [x for x in terraform_dir.iterdir() if x.is_dir()]
    if not subdirs:
        subdirs = [terraform_dir]

    tf_modules = [x for x in subdirs if Path(x / "main.tf").exists()]
    metafunc.parametrize("subdir", tf_modules, ids=[x.name for x in tf_modules])
