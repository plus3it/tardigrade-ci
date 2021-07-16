# Tardigrade-ci Integration Testing

The tardigrade-ci `Makefile` provides targets to facilitate automated 
integration testing of terraform modules through the use of a mock AWS stack.

This document describes the integration-specific `Makefile` targets and
the environment variables to customize those targets.  In addition,
the steps to try out a test are described as are the potential CI/CD
changes to incorporate automated integration testing.

## Integration test-specific targets and environment variables

| Target name      | Description |
| ---------------- | ------------------------------------------ |
| mockstack/pytest | From within a Docker container, invoke `pytest` to execute the integration tests. |
| mockstack/up     | Start up a Docker container running the mock AWS stack. |
| mockstack/down   | Bring down the Docker container running the mock AWS stack. |
| mockstack/clean  | Bring down the Docker container running the mock AWS stack, then remove the docker image. |
| terraform/pytest | Invoke `pytest` to execute the integration tests. The mock AWS stack must be started before using this `Makefile` target. |

Defaults:

* `LocalStack` is used for the mock AWS stack, with moto serving ports for 
services not yet suported by `LocalStack`.
* The Terraform modules used for the integration tests are expected to
be located in the directory `tests` off the repo\'s root directory.

### Environment variables

| Environment variable             | Default value |
| -------------------------------- | --------------------------------------- |
| INTEGRATION_TEST_BASE_IMAGE_NAME | $(basename $PWD)-integration-test |
| TERRAFORM_PYTEST_ARGS            | |
| TERRAFORM_PYTEST_DIR             | $PWD/tests/terraform/pytest |

### Arguments to the automation script

These are values that can be specified through the environment variable
TERRAFORM_PYTEST_ARGS.

| Command line option | Description |
| ------------------- | ----------------------------------------------- |
| --nomock            | Use AWS, not mocked AWS services |
| --alternate-profile | Configure an alternate profile in addition to default profile |
| --tf-dir=TF_DIR     | Directory of Terraform files under test; default: './tests' |

## Executing a Terraform test

The tardigrade-ci `Makefile` expects the test Terraform modules to be under
the repo\s `tests` directory.  There can be multiple sets of tests, each
under their own `tests` subdirectory.

If a test requires an initial test setup, then those Terraform "test setup"
files should be placed in the directory `prereq` under that test\'s
subdirectory.  For example:

```
.
├── tests
│   ├── create_all
│   │   ├── main.tf
│   │   └── prereq
│   │       └── main.tf
│   ├── create_groups
│   │   ├── main.tf

...
```

To verify that a Terraform test will work, bring up the default AWS mock
stack (`LocalStack`) first, then execute the test:

```bash
make mockstack/up
make terraform/pytest

# To execute a specific set of tests, use the "-k" option and a string
# that will pattern match on the desired subdirectory name.  The "-k"
# option also allows booleans, e.g., "not" or "or".
#
# The following will match on the subdirectory "create_groups".
make terraform/pytest TERRAFORM_PYTEST_ARGS="-k groups"

# When testing is complete:
make mockstack/clean
```

## Potential CI/CD changes 

These are suggested changes and may not apply to all repos:

1.  If the repo currently does not contain or use Python scripts,
    update `.gitignore` to add:

```bash
# Caching directory created by pytest.
tests/__pycache__/
```

2.  For a Travis workflow, logic similar to the following would
    need to be added to the `.travis.yml` file:

```bash
stage: test

name: Terraform Integration Tests

language: python

python:
  - "3.8"

install: make mockstack/up

script: make mockstack/pytest
after_script: make mockstack/clean
```
