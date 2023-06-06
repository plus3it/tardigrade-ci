## tardigrade-ci Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and this project adheres to [Semantic Versioning](http://semver.org/).

### [0.24.7](https://github.com/plus3it/tardigrade-ci/releases/tag/0.24.7)

**Released**: 2023.06.06

**Summary**:

* Adds general target for installing any python version using pyenv, `install/pyenv/%`
* Adds `yamllint` to container image and lints yaml as part of `lint` target

* Updates tool versions:
    * black 23.3.0
    * cfn-lint 0.77.6
    * golang 1.20.4
    * localstack 2.1.0
    * packer 1.9.1
    * pylint 2.17.4
    * pytest 7.3.1
    * python 3.12.0b1
    * python-hcl2 4.3.2
    * rclone 1.62.2
    * terraform 1.4.6
    * terragrunt 0.46.1
    * terratest 0.43.0
    * tftest 1.8.4
    * yamllint 1.32.0
    * yq 4.34.1

### [0.24.6](https://github.com/plus3it/tardigrade-ci/releases/tag/0.24.6)

**Released**: 2023.02.15

**Summary**:

* Updates .pylintrc to specify module name for overgeneral-exceptions

* Updates tool versions:
    * bats 1.9.0
    * cfn-lint 0.73.2
    * editorconfig-checker 2.7.0
    * golang 1.20.1
    * localstack 1.4.0
    * packer 1.8.6
    * pylint 2.16.2
    * python 3.12.0a5
    * terraform 1.3.9
    * terratest 0.41.11
    * tftest==1.8.2
    * yq 4.31.1 

### [0.24.5](https://github.com/plus3it/tardigrade-ci/releases/tag/0.24.5)

**Released**: 2023.02.10

**Summary**:

* Updates shebang in mockstack startup script so moto server is started properly,
  and listening for connections

* Updates tool versions:
    * black 23.1.0
    * golang 1.20.0
    * pylint 2.16.1
    * terragrunt 0.43.2
    * terratest 0.41.10

### 0.24.4

**Released**: 2023.02.02

**Commit Delta**: [Change from 0.24.3 release](https://github.com/plus3it/tardigrade-ci/compare/0.24.3..0.24.4)

**Summary**:

* Adds tftest target to makefile for dependency support

* Updates tool versions:
    * cfn-lint 0.72.10
    * golang 1.19.5
    * pydocstyle 6.3.0
    * pylint 2.15.10
    * pytest 7.2.1
    * python 3.12.0a4
    * python-hcl2 4.3.0
    * terragrunt 0.43.0
    * terratest 0.41.9
    * yamllint 1.29.0
    * yq 4.30.8

### 0.24.3

**Released**: 2023.01.12

**Commit Delta**: [Change from 0.24.2 release](https://github.com/plus3it/tardigrade-ci/compare/0.24.2..0.24.3)

**Summary**:

* Updates mockstack tf provider config with endpoints for all aws services
* Defaults to pytest verbose output so tf stdout is displayed in tests
* Addresses deprecation warnings in mock provider config
* Uses localstack 1.3 location for init scripts

* Updates tool versions:
    * black 22.12.0
    * cfn-lint 0.72.6
    * golang 1.19.4
    * localstack 1.3.1
    * packer 1.8.5
    * pydocstyle 6.2.3
    * pylint 2.15.9
    * python 3.8.16
    * python 3.12.0a3
    * python-hcl2 4.2.0
    * rclone 1.61.1
    * shellcheck 0.9.0
    * terraform 1.3.7
    * terragrunt 0.42.7
    * terratest 0.41.7
    * tftest 1.8.1
    * yq 4.30.6

### 0.24.2

**Released**: 2022.10.31

**Commit Delta**: [Change from 0.24.1 release](https://github.com/plus3it/tardigrade-ci/compare/0.24.1..0.24.2)

**Summary**:

* Adds github auth header to bats/install target

* Updates tool versions:
    * bats 1.8.2
    * cfn-lint 0.69.1
    * packer 1.8.4
    * pytest 7.2.0
    * python 3.12.0a1
    * terraform 1.3.3
    * terragrunt 0.39.2
    * yq 4.29.2

### 0.24.1

**Released**: 2022.10.18

**Commit Delta**: [Change from 0.24.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.24.0..0.24.1)

**Summary**:

* Creates targets for installing python 3.8 and returning the expected version

* Updates tool versions:
    * python 3.11.0rc2

### 0.24.0

**Released**: 2022.10.17

**Commit Delta**: [Change from 0.23.2 release](https://github.com/plus3it/tardigrade-ci/compare/0.23.2..0.24.0)

**Summary**:

* Provides make target to install pyenv, and adds pyenv to docker image
* Uses pyenv to install Python 3.8 to the docker image
* Eliminates check whether to rebuild image, relying on docker change detection
* Uses specs bundled with cfn-lint

* Updates tool versions:
    * bats 1.8.0
    * black 22.10.0
    * cfn-lint 0.66.1
    * golang 1.19.2
    * localstack 1.2.0
    * pyenv (master)
    * pylint 2.15.3
    * python 3.8.15
    * rclone 1.59.2
    * terraform 1.3.2
    * terragrunt 0.39.1
    * tftest 1.7.4
    * yamllint 1.28.0
    * yq 4.28.1

### 0.23.2

**Released**: 2022.09.12

**Commit Delta**: [Change from 0.23.1 release](https://github.com/plus3it/tardigrade-ci/compare/0.23.1..0.23.2)

**Summary**:

* Creates target for each file in scope for docs lint and generate

* Updates tool versions:
    * black 22.8.0
    * cfn-lint 0.64.1
    * golang 1.19.1
    * pylint 2.15.2
    * pytest 7.1.3
    * python 3.10.7
    * terraform 1.2.9
    * terragrunt 0.38.9
    * terratest 0.40.22
    * yq 4.27.5

### 0.23.1

**Released**: 2022.09.09

**Commit Delta**: [Change from 0.23.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.23.0..0.23.1)

**Summary**:

* Adds a newline to all makedown files if one does not exist.  Runs terraform-docs on all Terraform files in the root and modules directories.  This fixes a bug with the previous version that would not run terraform-docs on modules directories if a Terraform files did not exist at the root level.

### 0.23.0

**Released**: 2022.09.07

**Commit Delta**: [Change from 0.22.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.22.0..0.23.0)

**Summary**:

* Adds a newline to the end of a README.md file if one does not exist.  

* Updates tool versions:
    * cfn-lint 0.61.5
    * localstack 1.1.0
    * terragrunt 0.38.7
    * terratest 0.40.21
    * yq 4.27.3

### 0.22.0

**Released**: 2022.08.23

**Commit Delta**: [Change from 0.21.9 release](https://github.com/plus3it/tardigrade-ci/compare/0.21.9..0.22.0)

**Summary**:

* Replaces all "find" logic with `git ls-files` to honor `.gitignore` by default
    * Patterns for FIND_EXCLUDES will now need to be based on the git pathspec (e.g. `':!:*/.terraform/*'`), instead of `find`. See also, <https://git-scm.com/docs/gitglossary#Documentation/gitglossary.txt-aiddefpathspecapathspec>
    * ECLINT_FILES now takes the command that returns the files, and not the list of files
    * All FIND_* variables can now be overriden by providing the command that returns the files

* Updates tool versions:
    * cfn-lint 0.61.5
    * golang 1.19.0
    * localstack 1.0.4
    * packer 1.8.3
    * pylint 2.14.5
    * python 3.10.6
    * rclone 1.59.1
    * terraform 1.2.7
    * terragrunt 0.38.7
    * terratest 0.40.19
    * tftest 1.7.1
    * yq 4.27.2

### 0.21.9

**Released**: 2022.07.14

**Commit Delta**: [Change from 0.21.8 release](https://github.com/plus3it/tardigrade-ci/compare/0.21.8..0.21.9)

**Summary**:

* Exports all variables that support overrides using `?=`
* Marks make macros as unexported, fixing .EXPORT_ALL_VARIABLES

* Updates tool versions:
    * black 22.6.0
    * cfn-lint 0.61.2
    * localstack 0.14.5
    * pylint 2.14.4
    * rclone 1.59.0
    * terraform 1.2.4
    * terragrunt 0.38.4
    * yamllint 1.27.1

### 0.21.8

**Released**: 2022.06.28

**Commit Delta**: [Change from 0.21.7 release](https://github.com/plus3it/tardigrade-ci/compare/0.21.7..0.21.8)

**Summary**:

* Avoids warnings about deleted pylint checks
* Defaults to node/install to version 16

* Updates tool versions:
    * cfn-lint 0.61.1
    * localstack 0.14.4
    * packer 1.8.2
    * terragrunt 0.38.1
    * yq 4.25.3

### 0.21.7

**Released**: 2022.06.22

**Commit Delta**: [Change from 0.21.6 release](https://github.com/plus3it/tardigrade-ci/compare/0.21.6..0.21.7)

**Summary**:

* Ensures root Makefile targets are available even to "guard" targets

* Updates tool versions:
    * cfn-lint 0.61.0
    * golang 1.18.3
    * localstack 0.14.3
    * packer 1.8.1
    * pylint 2.14.3
    * python 3.10.5
    * terraform 1.2.3
    * terragrunt 0.38.0
    * terratest 0.40.17
    * yq 4.25.2

### 0.21.6

**Released**: 2022.05.18

**Commit Delta**: [Change from 0.21.5 release](https://github.com/plus3it/tardigrade-ci/compare/0.21.5..0.21.6)

**Summary**:

* Updates cfn-lint specs with each tardigrade-ci release

* Updates tool versions:
    * bats 1.7.0
    * cfn-lint 0.60.0
    * golang 1.18.2
    * pylint 2.13.9
    * pytest 7.1.2
    * rclone 1.58.1
    * terraform 1.1.9
    * terragrunt 0.37.1
    * terratest 0.40.8
    * tftest 1.6.5
    * yq 4.25.1

### 0.21.5

**Released**: 2022.04.13

**Commit Delta**: [Change from 0.21.4 release](https://github.com/plus3it/tardigrade-ci/compare/0.21.4..0.21.5)

**Summary**:

* Updates tool versions:
    * black 22.3
    * cfn-lint 0.58.4
    * golang 1.17.8
    * hcl2 3.0.5
    * localstack 0.14.2
    * packer 1.8.0
    * pylint 2.13.5
    * pytest 7.1.0
    * python 3.10.4
    * rclone 1.58.0
    * terraform 1.1.8
    * terragrunt 0.36.3
    * terratest 0.40.6
    * yq 4.24.2

### 0.21.4

**Released**: 2022.02.15

**Commit Delta**: [Change from 0.21.3 release](https://github.com/plus3it/tardigrade-ci/compare/0.21.3..0.21.4)

**Summary**:

* Detects python files to determine whether to format/lint.

* Updates tool versions:
    * bats 1.6.0
    * cfn-lint 0.58.2
    * hcl2 3.0.4
    * terraform 1.1.6
    * terragrunt 0.36.2
    * terratest 0.40.4
    * yq 4.21.1

### 0.21.3

**Released**: 2022.02.15

**Commit Delta**: [Change from 0.21.2 release](https://github.com/plus3it/tardigrade-ci/compare/0.21.2..0.21.3)

**Summary**:

* Detects README.md and terrraform or packer files to detect whether to generate and/or lint docs.

* Updates tool versions:
    * cfn-lint 0.58.0
    * black 22.1.0
    * localstack 0.14.0
    * packer 1.7.10
    * pytest 7.0.1
    * terraform 1.1.5
    * terragrunt 0.36.1
    * terratest 0.40.1
    * tftest 1.6.4
    * yq 4.19.1
    * Docker now using golang 1.17.7-buster

### 0.21.2

**Released**: 2022.01.26

**Commit Delta**: [Change from 0.20.1 release](https://github.com/plus3it/tardigrade-ci/compare/0.20.1..0.21.2)

**Summary**:

* Allows callers to use any name for the Makefile, set with `make -f`.

### 0.21.1

**Released**: 2022.01.20

**Commit Delta**: [Change from 0.20.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.20.0..0.21.1)

**Summary**:

* Uses built-in features of terraform-docs to inject content into readme files.

### 0.21.0

**Released**: 2022.01.06

**Commit Delta**: [Change from 0.19.7 release](https://github.com/plus3it/tardigrade-ci/compare/0.19.7..0.21.0)

**Summary**:

* Uses override file to inject mockstack config for aws provider. Allows test configs
  to manage their aws provider config entirely, including any argument supported
  by the aws provider. Test configs should now always work without modification
  for the "--nomock" use case, running against real aws endpoints. For more,
  see [PR #372](https://github.com/plus3it/tardigrade-ci/pull/372).
* Removes pytest argument `--alias`.
* Skips tftest cleanup on exit, so the tfstate remains intact. This is useful if
  there were errors when tftest ran the destroy action, as it allows us to manually
  inspect the state and re-run `terraform destroy`.

* Updates tool versions:
    * tftest 1.6.3

### 0.19.7

**Released**: 2022.01.03

**Commit Delta**: [Change from 0.19.6 release](https://github.com/plus3it/tardigrade-ci/compare/0.19.6..0.19.7)

**Summary**:

* Updates tool versions:
    * localstack 0.13.2

### 0.19.6

**Released**: 2021.12.27

**Commit Delta**: [Change from 0.19.5 release](https://github.com/plus3it/tardigrade-ci/compare/0.19.5..0.19.6)

**Summary**:

* Pins localstack version, with updates managed by dependabot. This helps stabilize
  the mockstack usage of tardigrade-ci in other projects.

* Updates tool versions:
    * editorconfig-checker 2.4.0
    * localstack 0.12.20
    * tftest 1.6.2
    * yq 4.16.2

### 0.19.5

**Released**: 2021.12.21

**Commit Delta**: [Change from 0.19.4 release](https://github.com/plus3it/tardigrade-ci/compare/0.19.4..0.19.5)

**Summary**:

* Patch release primarily to include terraform 1.1.2, as 1.1.0 had regressions
  that did not work with modules that specify refs. See: https://github.com/hashicorp/terraform/issues/30119

* Updates tool versions:
    * terraform 1.1.2
    * terragrunt 0.35.16
    * terratest 0.38.8

### 0.19.4

**Released**: 2021.12.13

**Commit Delta**: [Change from 0.19.3 release](https://github.com/plus3it/tardigrade-ci/compare/0.19.3..0.19.4)

**Summary**:

*   Adds the environment variable MOTO_DOCKER_NETWORK_NAME to the docker
    compose file used for LocalStack and moto.  This environment variable
    is used by moto_server to determine the IP address for the docker
    container.

* Updates tool versions:
    * black 21.12b0
    * cfn-lint 0.56.3
    * golang 1.17.5-buster
    * pylint 2.12.2
    * python 3.10.1-buster
    * shellcheck 0.8.0
    * terraform 1.1.0
    * terragrunt 0.35.14
    * terratest 0.38.6
    * tftest 1.6.1
    * yq 4.16.1

### 0.19.3

**Released**: 2021.11.04

**Commit Delta**: [Change from 0.19.2 release](https://github.com/plus3it/tardigrade-ci/compare/0.19.2..0.19.3)

**Summary**:

*   If ONLY_MOTO is set to true in a Makefile and a integration test is run
    against AWS itself (versus a mock AWS), instead of failing due to the
    conflicting command line options, a warning will be printed.

### 0.19.2

**Released**: 2021.11.03

**Commit Delta**: [Change from 0.19.1 release](https://github.com/plus3it/tardigrade-ci/compare/0.19.1..0.19.2)

**Summary**:

*   Adds new Makefile targets for the purpose of installing packer and rclone

*   Adds install targets for the tools:
    * packer 1.7.8
    * rclone 1.57.0

### 0.19.1

**Released**: 2021.11.01

**Commit Delta**: [Change from 0.19.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.19.0..0.19.1)

**Summary**:

*   Added moto-only services to mockstack.tf:  Cloudtrail, Directory Service,
    Route53 and Route53 Resolver.

* Updates tool versions:
    * black 21.10b0
    * cfn-lint 0.54.4
    * terraform 1.0.10
    * yq 4.14.1
    * terragrunt 0.35.5

### 0.19.0

**Released**: 2021.10.25

**Commit Delta**: [Change from 0.18.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.18.0..0.19.0)

**Summary**:

*   The new environment variable "ONLY_MOTO" can be used to specify that
    moto should be used for mock AWS services, and not LocalStack or some
    combination of moto and LocalStack.

* Updates tool versions:
    * bats 1.50
    * cfn-lint 0.54.3
    * terraform 1.0.9
    * terraform-docs 1.16.0
    * terragrunt 0.35.4
    * terratest 0.38.2
    * yq 4.13.5
    * Docker now using golang:1.17.2-buster
    * Docker now using python:3.10.0-buster

### 0.18.0

**Released**: 2021.09.13

**Commit Delta**: [Change from 0.17.1 release](https://github.com/plus3it/tardigrade-ci/compare/0.17.1..0.18.0)

**Summary**:

*   The new environment variable "PROVIDER_ALIAS" can be used to specify the
    name of a Terraform provider alias.  Used as a value for the new "--alias"
    command line option, it instructs the automated integration test tool
    to create the aliased provider information in preparation for a test run.

*   When running Terraform tests, the Firehose service will now be provided
    by moto and not LocalStack.

*   Updates tool versions:
    * black 21.9b0
    * cfn-lint 0.54.1
    * pylint 2.11.1
    * pytest 6.2.5
    * terraform 1.0.7
    * terraform-docs 1.15.0
    * terragrunt 0.31.10
    * terratest 0.37.8
    * yamllint 1.26.3
    * yq 4.13.2
    * Docker now using golang:1.17.1-buster
    * Docker now using python:3.9.7-buster

### 0.17.1

**Released**: 2021.07.30

**Commit Delta**: [Change from 0.17.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.17.0..0.17.1)

**Summary**:

*   Uses fixuid in entrypoint to fix permissions issues with bindmounts.
    The user that builds the tardigrade-ci container and the user that runs
    the tardigrade-ci container (or containers built from it) must have the
    same UID, or permissions issues will occur. Fixuid checks the user running
    the container and chowns any file or directory owned by a specified user/group
    in its configuration. This ensures the user has permissions to those files
    and directories.

### 0.17.0

**Released**: 2021.07.29

**Commit Delta**: [Change from 0.16.1 release](https://github.com/plus3it/tardigrade-ci/compare/0.16.1..0.17.0)

**Summary**:

*   Creates a non-root user in docker image and passes user context when
    building the image. This ensures that files created in volumes mounted to
    the docker container are owned by the user running the container.
*   Mounts the `.aws` directory as read-only in the docker container.

### 0.16.1

**Released**: 2021.07.22

**Commit Delta**: [Change from 0.16.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.16.0..0.16.1)

**Summary**:

*   Modifies Travis workflow to run lint generically, not just ec and a shell check.

*   Corrects various lint errors.

*   No changes to tool versions.

### 0.16.0

**Released**: 2021.07.22

**Commit Delta**: [Change from 0.15.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.15.0..0.16.0)

**Summary**:

*   Adds the target "pytest/%" for Python unit testing.

*   Replaces the environment variable TERRAFORM_PYTEST_ARGS with PYTEST_ARGS.

*   Corrects an error with the integration test utility that occurs when
    Terraform fails during the apply.

*   No changes to tool versions.

### 0.15.0

**Released**: 2021.07.15

**Commit Delta**: [Change from 0.14.1 release](https://github.com/plus3it/tardigrade-ci/compare/0.14.1..0.15.0)

**Summary**:

*   Adds new Makefile targets for the purpose of testing Terraform modules
    using Terraform and the mock AWS stacks LocalStack and/or moto.  The new
    readme file `INTEGRATION_TESTING.md` describes the expected testing
    environment and the associated Makefile targets.

*   Updates tool versions:
    * docker-compose 1.29.2

*   Adds install targets for the tools:
    * pytest-compose 6.2.4
    * tftest 1.6.0

### 0.14.1

**Released**: 2021.07.9

**Commit Delta**: [Change from 0.14.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.14.0..0.14.1)

**Summary**:

*   Updates language versions:
    * python 3.9.6
*   Updates tool versions:
    * black 21.6b0
    * cfn-lint 0.52.0
    * pylint 2.9.3
    * terraform 1.0.2
    * terraform-docs 0.14.1
    * terragrunt 0.31.0
    * terratest 0.36.5
    * yq 4.9.8

### 0.14.0

**Released**: 2021.05.28

**Commit Delta**: [Change from 0.13.1 release](https://github.com/plus3it/tardigrade-ci/compare/0.13.1..0.14.0)

**Summary**:

*   Modifies "install" targets to install the version pinned in a file managed
    by Dependabot. Depending on the tool and how it is packaged/hosted, the version
    may be pinned in `Dockerfile.tools`, `requirements.txt`, or `.github/workflows/dependabot_hack.yml`.
*   Uses "install" targets in Dockerfile, to ensure the targets are all tested
    when building the image in Ci.

### 0.13.1

**Released**: 2021.05.07

**Commit Delta**: [Change from 0.13.0 release](https://github.com/plus3it/tardigrade-ci/compare/0.13.0..0.13.1)

**Summary**:

*   Provides a target for installing terragrunt, `terragrunt/install`, and adds
    terragrunt to the docker container.

### 0.13.0

**Released**: 2021.05.06

**Commit Delta**: [Change from 0.12.4 release](https://github.com/plus3it/tardigrade-ci/compare/0.12.4..0.13.0)

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
