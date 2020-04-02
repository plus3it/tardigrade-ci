# tardigrade-ci

A docker based test framework

This project packages the make targets that provide the tools and command shortcuts Plus3IT uses to develop and maintain our terraform modules.

The makefile in this repository has been exposed as the entry point to the accompanying docker image. A list of the available make targets are provided below:

```bash
Available targets:

  cfn/lint                            Lints CloudFormation files
  docs/generate                       Generates Terraform documentation
  docs/lint                           Lints Terraform documentation
  eclint/lint                         Runs eclint against the project
  hcl/format                          Formats hcl files
  hcl/lint                            Lints hcl files
  help                                This help screen
  json/format                         Formats json files
  json/lint                           Lints json files
  python/format                       Formats Python files
  python/lint                         Lints Python files
  sh/lint                             Lints bash script files
  terraform/format                    Formats terraform files
  terraform/lint                      Lints terraform files
  test                                Runs terraform tests in the tests directory
  yaml/lint                           Lints YAML files
```

## How to use

This project can be utilized one of two ways, via docker or via a Makefile include.

### Via Docker

  **NOTE:** The target project _must_ be added as a bindmount to the `/ci-harness` directory.

  ```bash
  IMAGE="plus3it/tardigrade-ci:latest"
  docker pull "$IMAGE"
  docker run --rm -ti -v "my-project-dir:/ci-harness/my-project" "$IMAGE" helps
  ```

### Makefile Include

1. Create a Dockerfile in the project in which you wish to utilize these ci tools with the following content.

  **NOTE:** This Dockerfile is intended to be used to enable version pinning of the underlying toolset.

  ```bash
  FROM plus3it/tardigrade-ci:0.0.2

  WORKDIR /ci-harness
  ENTRYPOINT ["make"]
  ```

2. Add a simple makefile with these two lines

  ```bash
  SHELL := /bin/bash

  -include $(shell curl -sSL -o .tardigrade-ci "https://raw.githubusercontent.com/plus3it/tardigrade-ci/master/bootstrap/Makefile.bootstrap"; echo .tardigrade-ci)
  ```

3. Add the following to your `.gitignore` file

  ```bash
  # tardigrade-ci
  .tardigrade-ci
  tardigrade-ci/

  # eclint
  .git/
  ```

4. Run `make` once to initialize the project and then `make docker/run target=<TARGET>`

5. Additionally, you can use the tardigrade-ci/Makefile vars and targets
directly in your own Makefile. For example, there is a target for installing
a binary from GitHub releases, which you can utilize pretty easily:

```
## Install gomplate
gomplate/% GOMPLATE_VERSION ?= latest
gomplate/install:
  @ $(MAKE) install/gh-release/$(@D) FILENAME="$(BIN_DIR)/$(@D)" OWNER=hairyhenderson REPO=$(@D) VERSION=$(GOMPLATE_VERSION) QUERY='.name | endswith("$(OS)-$(ARCH)")'
```

The target `install/gh-release/%` as well as the vars `$(OS)` and `$(ARCH)` are
provided by the tardigrade-ci/Makefile, and do not need to be redefined in your
local Makefile.
