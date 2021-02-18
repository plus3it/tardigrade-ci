## tardigrade-ci Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and this project adheres to [Semantic Versioning](http://semver.org/).

### 0.9.0

**Released**: 2021.02.18

**Commit Delta**: [Change from 0.8.1 release](https://github.com/plus3it/tardigrade-ci/compare/0.8.1...0.9.0)

**Summary**:

*   PYLINT_RCFILE defines location of the .pylintrc used by pylint
*   Loadable-plugin added to .pylintrc file to support pytest linting
*   Unit test updated to support latest version of terraform-docs (0.11.0)

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
