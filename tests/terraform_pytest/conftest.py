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
        "--alternate_profile",
        action="store_true",
        help="Configure an alternate profile in addition to default profile",
    )
    parser.addoption(
        "--moto",
        action="store_true",
        help="Use moto versus LocalStack for mocked AWS services",
    )


@pytest.fixture(scope="function")
def aws_credentials(tmpdir, monkeypatch):
    """Return the function that creates mocked AWS credentials."""
    # It would make more sense for this fixture to have a scope of "session",
    # but unfortunately, monkeypatch does not support that scope.

    def create_aws_credentials(profile_names):
        """Helper function to create mocked AWS credentials."""
        # Create a temporary AWS credentials file.
        for profile_name in profile_names:
            aws_creds = [
                f"[{profile_name}]",
                "aws_access_key_id = testing",
                "aws_secret_access_key = testing",
            ]
        path = tmpdir.join("aws_test_creds")
        path.write("\n".join(aws_creds))
        monkeypatch.setenv("AWS_SHARED_CREDENTIALS_FILE", str(path))

        # Ensure that any existing AWS-related environment variables are
        # overridden with 'mock' values.
        monkeypatch.setenv("AWS_ACCESS_KEY_ID", "testing")
        monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "testing")
        monkeypatch.setenv("AWS_SECURITY_TOKEN", "testing")
        monkeypatch.setenv("AWS_SESSION_TOKEN", "testing")
        monkeypatch.setenv("AWS_PROFILE", profile_name)

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
def use_moto(request):
    """Return True if moto should be used, not LocalStack."""
    if request.config.option.nomock:
        pytest.exit(msg="conflicting options:  'moto' and 'nomock'")
    return request.config.option.moto


@pytest.fixture(scope="session")
def repo_root_dir():
    """Return path of repo's root directory. Default is the current dir."""
    return Path.cwd()


def pytest_generate_tests(metafunc):
    """Generate list of subdirectories under test.

    Each subdirectory represents a different Terraform module.
    """
    # Can't use the fixture repo_root_dir as the pytest_generate_tests()
    # API does not allow fixtures as arguments.
    subdirs = [x for x in Path(Path.cwd() / "tests").iterdir() if x.is_dir()]
    if not subdirs:
        pytest.exit(msg="no integration tests")

    tf_modules = [x for x in subdirs if Path(x / "main.tf").exists()]
    metafunc.parametrize("subdir", tf_modules, ids=[x.name for x in tf_modules])
