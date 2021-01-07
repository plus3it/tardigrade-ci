# tardigrade-ci

A docker based test framework

This project packages the make targets that provide the tools and command shortcuts
Plus3IT uses to develop and maintain projects of all sorts.

The targets in this tardigrade-ci Makefile are included when using the accompanying
docker image with your own project. A list of the available make targets are provided
below:

```bash
Available targets:

  bumpversion/major                   Uses 'bumpversion' to update the major version
  bumpversion/minor                   Uses 'bumpversion' to update the minor version
  bumpversion/patch                   Uses 'bumpversion' to update the patch version
  cfn/lint                            Lints CloudFormation files
  clean                               Clean build-harness
  docker/build                        Builds the tardigrade-ci docker image
  docker/clean                        Cleans local docker environment
  docker/run                          Runs the tardigrade-ci docker image
  docs/generate                       Generates Terraform documentation
  docs/lint                           Lints Terraform documentation
  ec/lint                             Runs editorconfig-checker, aka 'ec', against the project
  hcl/format                          Formats hcl files
  hcl/lint                            Lints hcl files
  hcl/validate                        Validates hcl files
  help                                This help screen
  init                                Init build-harness
  json/format                         Formats json files
  json/lint                           Lints json files
  python/format                       Formats Python files
  python/lint                         Checks format and lints Python files
  sh/lint                             Lints bash script files
  terraform/format                    Formats terraform files
  terraform/lint                      Lints terraform files
  test                                Runs terraform tests in the tests directory
  yaml/lint                           Lints YAML files
```

## How to use

This project can be utilized one of two ways, via docker or via a Makefile include.

### Via Docker

**NOTE:** The target project _must_ be added as a bindmount to the docker WORKDIR.

```bash
IMAGE="plus3it/tardigrade-ci:latest"
docker pull "$IMAGE"
docker run --rm -ti -v "$PWD/:/workdir/" -w /workdir "$IMAGE" help
```

### Makefile Include

This option uses `make` to invoke the targets. It is recommended to use the target
`make docker/run`, with a Dockerfile based on the plus3it/tardigrade-ci image,
as this container includes all the tools needed by all the targets. In this case,
you need only `make` and `docker` on your system. See below for an example.

However, you may invoke any make target directly, e.g. `make ec/lint`. Be aware
if you do so, the make target will attempt to install the tools it requires to your
system. Generally, this option requires more expertise to utilize (and more
flexibility/understanding), as the install routines may not be tailored for your
system.

1. Create a Dockerfile in the project in which you wish to utilize these ci tools
with the following content.

    **NOTE:** This Dockerfile is intended to be used to enable version pinning of
    the underlying toolset.

    ```bash
    FROM plus3it/tardigrade-ci:0.8.0
    ```

2. Add a simple makefile with these two lines

    ```bash
    SHELL := /bin/bash

    include $(test -f .tardigrade-ci || shell curl -sSL -o .tardigrade-ci "https://raw.githubusercontent.com/plus3it/tardigrade-ci/master/bootstrap/Makefile.bootstrap"; echo .tardigrade-ci)
    ```

3. Add the following to your `.gitignore` file

    ```bash
    # tardigrade-ci
    .tardigrade-ci
    tardigrade-ci/
    ```

4. Run `make docker/run target=<TARGET>`.

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

## Makefile prerequisites

Using the Makefile approach involves calling `make` directly. This means make,
as well as a few other prerequisites must be installed on the system for it to
work.

* `make` v4.2 or later
* `jq` v1.5 or later
* `git` v2.20 or later
* `bash` v4 or later
* `sed` v4 or later
* `awk` v4 or later
* `grep` v3 or later
* `xargs` v4.7 or later
* `curl` v7 or later

The Makefile is written with Debian-based systems in mind, including Ubuntu, and
all those packages can be installed using `apt` from default repos. Other platforms
ought to work fine, as long as these packages/versions can be installed. For example,
MacOS is known to work, using `brew` to get a modern version of `bash` and GNU
tools (there are many guides, [here is one](https://www.topbug.net/blog/2013/04/14/install-and-use-gnu-command-line-tools-in-mac-os-x/)).

There are a couple make targets that call out to `apt` directly. You can avoid
that requirement by pre-installing these packages using your own package manager,
or simply do not invoke targets that rely on these packages:

* `zip`
* `nodejs`

## Makefile "operating modes"

When using the Makefile approach, the `include` directive is a shell command that
retrieves the "bootstrap" Makefile from this project, saves it to the current working
directory, and then echoes back the name of the saved file. Make reads the bootstrap
Makefile and processes its directives and targets.

The bootstrap Makefile is very barebones. Its primary purpose is to bootstrap this
`tardigrade-ci` project so all the make targets are available. It does this through
its own `include` directive. The bootstrap include directive processes a shell
command with logic to determine whether to clone this project, and then echoes
back the path to this project's Makefile.

The bootstrap Makefile supports two "operating modes" that we're calling **user mode**
and **developer mode**.

In **user mode**, the bootstrap Makefile automatically clones the `tardigrade-ci`
repo to a subdirectory of the calling project, e.g. `/{project}/tardigrade-ci/`.
This feature is called **auto-init**. In this mode, the `tardigrade-ci` subdirectory
is considered "owned" by the bootstrap Makefile. The bootstrap Makefile will
manage and update the clone (through the `include` logic) to ensure the checkout
matches the git branch or tag specified by the env `TARDIGRADE_CI_BRANCH`. By
default, this env will resolve to either the version specified in the `Dockerfile`
(if present) or the `master` branch (if the Dockerfile is missing or is not
specifying a version). The user may override the default behavior by providing
the env explicitly, e.g. `TARDIGRADE_CI_BRANCH=foo make help`.

In **developer mode**, the user is responsible for cloning the `tardigrade-ci`
repo to a sibling directory of the current project, e.g. `/{project}/` and
`/tardigrade-ci/`. When the bootstrap Makefile detects this condition, it will
include the tardigrade-ci Makefile from the user-managed clone. This makes it easier
for a developer to edit the tardigrade-ci project, and test those changes from
a calling project.

The bootstrap Makefile provides two make targets to help manage these modes:

- `make init` will enable **user mode** explicitly, by cloning the `tardigrade-ci`
repo as a subdirectory of the calling project. This way a developer who has a separate
clone of the `tardigrade-ci` repo can easily switch to **user mode**.

- `make clean` will delete both the `tardigrade-ci` subdirectory and the bootstrap
Makefile. The next call to `make` will then retrieve the bootstrap Makefile and
either auto-init to **user mode** or fall into **developer mode**, based on the
logic described above.
