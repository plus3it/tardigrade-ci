## tardigrade-ci Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and this project adheres to [Semantic Versioning](http://semver.org/).

### 0.12.5

**Released**: 2021.05.06

**Commit Delta**: [Change from 0.12.5 release](https://github.com/plus3it/tardigrade-ci/compare/0.12.4..0.12.5)

**Summary**:

*   Update terraform-docs version to v0.13.0

### 0.12.4

**Released**: 2021.05.05

**Commit Delta**: [Change from 0.12.3 release](https://github.com/plus3it/tardigrade-ci/compare/0.12.3..0.12.4)

**Summary**:

*   Uses `pip` pyenv shim when available
*   Adds `PYTHONUSERBASE` bin directory to PATH

### 0.12.3

**Released**: 2021.05.04

**Commit Delta**: [Change from 0.12.2 release](https://github.com/plus3it/tardigrade-ci/compare/0.12.2..0.12.3)

**Summary**:

*   Updates version of black. Modifies pydocstyle unit test to accommodate change for the new version of black.

### 0.12.2

**Released**: 2021.05.03

**Commit Delta**: [Change from 0.12.1 release](https://github.com/plus3it/tardigrade-ci/compare/0.12.1..0.12.2)

**Summary**:

*   Provides a macro "stream_github_release" that supports piping a GitHub Release
    artifact to another tool (like `tar`). The target "stream/gh-release/%" is
    deprecated in favor of this macro, to avoid an unnecessary recursive `$(MAKE)`.
*   Updates the `terraform-docs/install` target to extract the binary from the
    tar.gz archive hosted by GitHub Releases, as the binary is no longer available
    as a separate artifact.

### 0.12.1

**Released**: 2021.05.3

**Commit Delta**: [Change from 0.12.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.12.0..0.12.1)

**Summary**:

*   Remove the "--user" option from the "python -m pip install" commands.

### 0.12.0

**Released**: 2021.04.23

**Commit Delta**: [Change from 0.11.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.11.0..0.12.0)

**Summary**:

*   Pins terraform-docs version using multi-stage docker build
*   Pins terraform version using multi-stage docker build
*   Pins shellcheck version using multi-stage docker build
*   Pins bats version using multi-stage docker build
*   Pins editorconfig-checker (ec) version using multi-stage docker build
*   Pins yq version using multi-stage docker build
*   Pins black version using requirements.txt and multi-stage docker build
*   Pins pylint version using requirements.txt and multi-stage docker build
*   Pins pylint-pytest version using requirements.txt and multi-stage docker build
*   Pins pydocstyle version using requirements.txt and multi-stage docker build
*   Pins yamllint version using requirements.txt and multi-stage docker build
*   Pins cfn-lint version using requirements.txt and multi-stage docker build
*   Pins bumpversion version using requirements.txt and multi-stage docker build

### 0.11.0

**Released**: 2021.03.19

**Commit Delta**: [Change from 0.10.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.10.0...0.11.0)

**Summary**:

*   Adds env TARDIGRADE_CI_AUTO_INIT that controls whether auto-init is enabled
    (defaults to true).
*   Suppresses the duplicative output from the auto-init logic in recursive calls
    to $(MAKE).

### 0.10.0

**Released**: 2021.03.18

**Commit Delta**: [Change from 0.9.2 release](https://github.com/plus3it/tardigrade-ci/compare/0.9.2...0.10.0)

**Summary**:

*   No longer requires a docker file with the fixed name of `Dockerfile`.
    The environment variable `TARDIGRADE_CI_DOCKERFILE` can be used to
    specify an alternative docker filename for the `docker/build` 
    target or for the file used for the bootstrap.
*   Corrects misspelling of the module name for terratest golang test.

### 0.9.2

**Released**: 2021.02.19

**Commit Delta**: [Change from 0.9.1 release](https://github.com/plus3it/tardigrade-ci/compare/0.9.1...0.9.2)

**Summary**:

*   Restores terraform-docs version to latest (currently v0.11.1), suppressing
    the `modules` and `resources` sections. Also, the newline behavior of `docs/generate`
    is managed explicitly so it is no longer subject to future changes in the
    terminating newline behavior of `terraform-docs`. See [PR #143](https://github.com/plus3it/tardigrade-ci/pull/143)

### 0.9.1

**Released**: 2021.02.18

**Commit Delta**: [Change from 0.9.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.9.0...0.9.1)

**Summary**:

*   Skips setting AWS_PROFILE when the env is not available

### 0.9.0

**Released**: 2021.02.18

**Commit Delta**: [Change from 0.8.1 release](https://github.com/plus3it/tardigrade-ci/compare/0.8.1...0.9.0)

**Summary**:

*   PYLINT_RCFILE defines location of the .pylintrc used by pylint
*   Loadable-plugin added to .pylintrc file to support pytest linting

### 0.8.1

**Released**: 2021.01.13

**Commit Delta**: [Change from 0.8.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.8.0...0.8.1)

**Summary**:

*   Runs auto-init in non-`tardigrade-ci` containers, so the make targets are available
*   Ensures `$PWD` is always set, including when invoking the container directly
    with `docker run`

### 0.8.0

**Released**: 2021.01.12

**Commit Delta**: [Change from 0.7.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.7.0...0.8.0)

**Summary**:

*   Provides auto-init functionality that removes requirement to run `make init`
    before calling other `make` targets
*   Documents the operational differences between **user mode** and **developer mode**
*   Documents software tools and versions required to use the Makefile operational
    modes
*   Improves safeties around `make clean` by restricting its operation to the tardigrade-ci
    subdirectory (relevant to **user mode**)
*   Removes `{project}/.tardigrade-ci` when calling `make clean`
*   Recommends the calling project `include` test for the `.tardigrade-ci` file
    to avoid unnecessary network I/O
*   Updates docker image to place the tardigrade-ci contents at `/tardigrade-ci`
*   Sets `docker/run` WORKDIR to `/workdir` and mounts calling project to `/workdir`
*   Exposes the env `entrypoint` to the `docker/run` target, keeping backwards
    compatibility by setting the default to `make`
*   Authenticates to GitHub API with GITHUB_ACCESS_TOKEN only if present

### 0.7.0

**Released**: 2021.01.06

**Commit Delta**: [Change from 0.6.2 release](https://github.com/plus3it/tardigrade-ci/compare/0.6.2...0.7.0)

**Summary**:

*   Provides `bumpversion` utility and targets to manage version update workflows
*   Exposes env `PKG_VERSION_CMD` so the target `install/pip/%` can tailor the
    version check per utility

### 0.6.2

**Released**: 2021.01.04

**Commit Delta**: [Change from 0.6.1 release](https://github.com/plus3it/tardigrade-ci/compare/0.6.1...0.6.2)

**Summary**:

*   Updates `docker/run` to grant the container access to the tardigrade-ci repo
    when the repo is outside the project directory

### 0.6.1

**Released**: 2020.12.29

**Commit Delta**: [Change from 0.6.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.6.0...0.6.1)

**Summary**:

*   Disables the `detachedHead` warning when bootstrapping tardigrade-ci repo
*   Retrieves version from Dockerfile when bootstrapping the tardigrade-ci repo
    With the change to how the container is mounted in v0.6.0, projects would
    _always_ retrieve the latest Makefile even when pinning an earlier version
    of the docker container. This could cause unexpected CI failures in work unrelated
    to an update of the container

### 0.6.0

**Released**: 2020.12.23

**Commit Delta**: [Change from 0.5.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.5.0...0.6.0)

**Summary**:

*   Uses the calling project's directory as the docker WORKDIR (`/ci-harness`)
    for the `docker/run` target. This removes a layer of abstraction, where before
    the tardigrade-ci directory was the `/ci-harness` WORKDIR, and the project's
    directory was mounted at `/ci-harness/{project}`. The prior approach meant all
    commands needed to change to the `{project}` directory to function properly.
    Now, commands operate the same as if they were being run outside the docker
    container

### 0.5.0

**Released**: 2020.12.18

**Commit Delta**: [Change from 0.4.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.4.0...0.5.0)

**Summary**:

*   Uses `pydocstyle` to lint python docstrings in `python/lint` target

### 0.4.0

**Released**: 2020.12.17

**Commit Delta**: [Change from 0.3.1 release](https://github.com/plus3it/tardigrade-ci/compare/0.3.1...0.4.0)

**Summary**:

*   Replaces `eclint` with `editorconfig-checker`
*   Improves friendliness of `ec/lint` tests by avoiding changes to the git working area

### 0.3.1

**Released**: 2020.12.11

**Commit Delta**: [Change from 0.3.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.3.0...0.3.1)

**Summary**:

*   Corrects `ec/lint` behavior when there are no matching files

### 0.3.0

**Released**: 2020.12.10

**Commit Delta**: [Change from 0.2.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.2.0...0.3.0)

**Summary**:

*   Modifies the envs `ECLINT_FILES` and `PYTHON_FILES` to be lists of files, instead
    of commands that return the files
*   Passes the `PROJECT_ROOT` env to `git ls-files` so `ECLINT_FILES` and `PYTHON_FILES`
    return the correct set of files

### 0.2.0

**Released**: 2020.12.03

**Commit Delta**: [Change from 0.1.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.1.0...0.2.0)

**Summary**:

*   Updates `python/lint` to lint python files with `pylint`

### 0.1.0

**Released**: 2020.08.20

**Commit Delta**: [Change from 0.0.18 release](https://github.com/plus3it/tardigrade-ci/compare/0.0.18...0.1.0)

**Summary**:

*   Adds support for terraform 0.13
*   Updates `docker/%` target to support building docker image locally on Ubuntu

### 0.0.18

**Released**: 2020.06.10

**Commit Delta**: [Change from 0.0.17 release](https://github.com/plus3it/tardigrade-ci/compare/0.0.17...0.0.18)

**Summary**:

*   Excludes cache directories from `make docs/%` targets

### 0.0.17

**Released**: 2020.04.08

**Commit Delta**: [Change from 0.0.16 release](https://github.com/plus3it/tardigrade-ci/compare/0.0.16...0.0.17)

**Summary**:

*   Exposes `TIMEOUT` env to customize the terratest timeout in the `make test`
    target

### 0.0.16

**Released**: 2020.04.08

**Commit Delta**: [Change from 0.0.15 release](https://github.com/plus3it/tardigrade-ci/compare/0.0.15...0.0.16)

**Summary**:

*   Updates hcl/format and hcl/lint targets

### 0.0.3

**Released**: 2020.1.28

**Commit Delta**: [Change from 0.0.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.0.2...0.0.3)

**Summary**:

*   Adds black and eclint make targets

### 0.0.2

**Released**: 2020.1.27

**Commit Delta**: [Change from 0.0.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.0.1...0.0.2)

**Summary**:

*   Adds remote Makefile functionality

### 0.0.1

**Released**: 2020.1.23

**Commit Delta**: [Change from 0.0.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.0.0...0.0.1)

**Summary**:

*   Updates terraform-docs make targets and associated tests

### 0.0.0

**Commit Delta**: N/A

**Released**: 2020.01.16

**Summary**:

*   Initial release!
