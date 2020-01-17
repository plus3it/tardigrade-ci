# tardigrade-ci

A docker based test framework

This project packages the make targets that provide the tools and command shortcuts Plus3IT uses to develop and maintain our terraform modules.

The makefile in this repository has been exposed as the entry point to the accompanying docker image. A list of the available make targets are provided below:

```bash
Available targets:

  docs/generate                       Generates terraform documentation
  docs/lint                           Lints terraform documentation
  help                                This help screen
  json/format                         Formats json files
  json/lint                           Lints json files
  sh/lint                             Lints bash script files
  terraform/format                    Formats terraform files
  terraform/lint                      Lints terraform files
  test                                Runs terraform tests in the tests directory
```

## How to use

**NOTE:** The target project _must_ be added as a bindmount to the `/ci-harness` directory.

```bash
IMAGE="plus3it/tardigrade-ci:latest"
docker pull "$IMAGE"
docker run --rm -ti -v "my-project-dir:/ci-harness/my-project" "$IMAGE" help
```
