# tardigrade-ci Integration Testing

The tardigrade-ci `Makefile` provides targets to facilitate automated 
integration testing of terraform modules using a mock AWS stack.  

Those targets and the environment variables that can customize the targets 
are described here.  In addition, this document describes the steps to take
when trying out a test and the potential CI/CD changes to incorporate
automated integration testing.

TBD - use of prereq

## Integration test-specific targets and environment variables

Assumptions:

* `LocalStack` is used for the mock AWS stack, but there is an 
option to use `moto` instead (refer to the subsections that follow).
* The Terraform modules used for the integration tests are expected to
be found in the directory `tests` off the repo\'s root directory.

| Target name      | Description |
| ---------------- | ------------------------------------------ |
| mockstack/pytest | From within a Docker container, invoke `pytest` to execute the integration tests. |
| mockstack/up     | Start up a Docker container running the mock AWS stack. |
| mockstack/down   | Bring down the Docker container running the mock AWS stack. |
| mockstack/clean  | Bring down the Docker container running the mock AWS stack, then remove the docker image. |
| terraform/pytest | Invoke `pytest` to execute the integration tests. The mock AWS stack must be started before using this `Makefile` target. |

### Environment variables

| Environment variable             | Default value |
| -------------------------------- | --------------------------------------- |
| INTEGRATION_TEST_BASE_IMAGE_NAME | $(shell basename $(PWD))-integration-test |
| MOCKSTACK                        | localstack |
| TERRAFORM_PYTEST_ARGS            | |
| TERRAFORM_PYTEST_DIR             | $(PWD)/tests/terraform/pytest |

### Arguments to the automation script

These are values that can be specified through the environment variable
TERRAFORM_PYTEST_ARGS.

| Command line option | Description |
| ------------------- | ----------------------------------------------- |
| --nomock            | Use AWS, not mocked AWS services |
| --alternate-profile | Configure an alternate profile in addition to default profile |
| --moto              | Use moto versus LocalStack for mocked AWS services |
| --tf-dir=TF_DIR     | Directory of Terraform files under test; default: './tests' |

## Testing a test

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
