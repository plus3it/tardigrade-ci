THIS_MAKEFILE := $(firstword $(MAKEFILE_LIST))
export ARCH ?= amd64
export OS ?= $(shell uname -s | tr '[:upper:]' '[:lower:'])
export CURL ?= curl --fail -sSL
export XARGS ?= xargs -I {}
export BIN_DIR ?= ${HOME}/bin
export TMP ?= /tmp
export FIND_EXCLUDES ?= ':!:*/.terraform/*' ':!:*/.terragrunt-cache/*'
export GIT_LS_FILES ?= git ls-files --cached --others --exclude-standard

# See https://docs.python.org/3/using/cmdline.html#envvar-PYTHONUSERBASE
export PYTHONUSERBASE ?= $(HOME)/.local

ifdef VIRTUAL_ENV
PATH := $(BIN_DIR):$(VIRTUAL_ENV)/bin:${PATH}
else
PATH := $(BIN_DIR):$(PYTHONUSERBASE)/bin:${PATH}
endif

MAKEFLAGS += --no-print-directory
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.SUFFIXES:

, := ,

export PYTHON ?= python3

.PHONY: guard/% %/install %/lint

export DEFAULT_HELP_TARGET ?= help
export HELP_FILTER ?= .*

export PWD := $(shell pwd)

export TARDIGRADE_CI_PATH ?= $(PWD)
export TARDIGRADE_CI_PROJECT ?= tardigrade-ci
export TARDIGRADE_CI_DOCKERFILE_TOOLS ?= $(TARDIGRADE_CI_PATH)/Dockerfile.tools
export TARDIGRADE_CI_DOCKERFILE_PYTHON312 ?= $(TARDIGRADE_CI_PATH)/.github/dependencies/python312/Dockerfile
export TARDIGRADE_CI_GITHUB_TOOLS ?= $(TARDIGRADE_CI_PATH)/.github/workflows/dependabot_hack.yml
export TARDIGRADE_CI_PYTHON_TOOLS ?= $(TARDIGRADE_CI_PATH)/requirements.txt
export SEMVER_PATTERN ?= [0-9]+(\.[0-9]+){1,3}

export TARDIGRADE_CI_AUTO_INIT = false

export SELF ?= $(MAKE) -f $(THIS_MAKEFILE)

default:: $(DEFAULT_HELP_TARGET)
	@exit 0

## This help screen
help:
	@printf "Available targets:\n\n"
	@$(SELF) -s help/generate | grep -E "\w($(HELP_FILTER))"

# Generate help output from MAKEFILE_LIST
help/generate:
	@awk '/^[a-zA-Z\_0-9%:\\\/-]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = $$1; \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
		gsub("\\\\", "", helpCommand); \
		gsub(":+$$", "", helpCommand); \
		printf "  \x1b[32;01m%-35s\x1b[0m %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST) | sort -u
	@printf "\n"

GITHUB_AUTHORIZATION := $(if $(GITHUB_ACCESS_TOKEN),-H "Authorization: token $$GITHUB_ACCESS_TOKEN",)

# Macro to return the download url for a github release
# For latest release, use version=latest
# To pin a release, use version=tags/<tag>
# $(call parse_github_download_url,owner,repo,version,asset select query)
parse_github_download_url = $(CURL) $(GITHUB_AUTHORIZATION) https://api.github.com/repos/$(1)/$(2)/releases/$(3) | jq --raw-output  '.assets[] | select($(4)) | .browser_download_url'
unexport parse_github_download_url

# Macro to download a github binary release
# $(call download_github_release,file,owner,repo,version,asset select query)
download_github_release = $(CURL) $(GITHUB_AUTHORIZATION) -o $(1) $(shell $(call parse_github_download_url,$(2),$(3),$(4),$(5)))
unexport download_github_release

# Macro to stream a github binary release
# $(call stream_github_release,owner,repo,version,asset select query)
stream_github_release = $(CURL) $(GITHUB_AUTHORIZATION) $(shell $(call parse_github_download_url,$(1),$(2),$(3),$(4)))
unexport stream_github_release

# Macro to download a hashicorp archive release
# $(call download_hashicorp_release,file,app,version)
download_hashicorp_release = $(CURL) -o $(1) https://releases.hashicorp.com/$(2)/$(3)/$(2)_$(3)_$(OS)_$(ARCH).zip
unexport download_hashicorp_release

# Macro to match a pattern from a line in a file
# $(call match_pattern_in_file,file,line,pattern)
match_pattern_in_file = $(or $(shell grep $(2) $(1) 2> /dev/null | grep -oE $(3) 2> /dev/null),$(error Could not match pattern from file: file=$(1), line=$(2), pattern=$(3)))
unexport match_pattern_in_file

# Macro to retry a command
# $(call retry,<max attempts>,<command>)
define retry
i=0; set +e; until [[ $$i -ge $(1) ]]; do sleep $$i; echo "$(2)"; ($(2)) && exit 0; ret=$$?; ((i++)); echo "Attempt ($$i) failed, trying until ($(1)) times"; done ; exit $$ret
endef
unexport retry

guard/env/%:
	@ _="$(or $($*),$(error Make/environment variable '$*' not present))"

guard/program/%:
	@ which $* > /dev/null || $(SELF) $*/install

guard/python_pkg/%:
	@ $(PYTHON) -m pip freeze | grep $* > /dev/null || $(SELF) $*/install

$(BIN_DIR):
	@ echo "[make]: Creating directory '$@'..."
	mkdir -p $@

install/gh-release/%: guard/env/FILENAME guard/env/OWNER guard/env/REPO guard/env/VERSION guard/env/QUERY
install/gh-release/%:
	@ echo "[$@]: Installing $*..."
	$(call download_github_release,$(FILENAME),$(OWNER),$(REPO),$(VERSION),$(QUERY))
	chmod +x $(FILENAME)
	$* --version
	@ echo "[$@]: Completed successfully!"

stream/gh-release/%: guard/env/OWNER guard/env/REPO guard/env/VERSION guard/env/QUERY
	$(warning WARNING: The target stream/gh-release is deprecated and will be removed in a future version. Use the macro "stream_github_release" instead.)
	$(CURL) $(GITHUB_AUTHORIZATION) $(shell $(call parse_github_download_url,$(OWNER),$(REPO),$(VERSION),$(QUERY)))

zip/install:
	@ echo "[$@]: Installing $(@D)..."
	apt-get install zip -y
	@ echo "[$@]: Completed successfully!"

packer/install: export PACKER_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_DOCKERFILE_TOOLS),'hashicorp/packer','$(SEMVER_PATTERN)')
packer/install: | $(BIN_DIR) guard/program/jq
	@ echo "[$@]: Installing $(@D) $(PACKER_VERSION)..."
	$(call download_hashicorp_release,$(@D).zip,$(@D),$(PACKER_VERSION))
	unzip $(@D).zip && rm -f $(@D).zip && chmod +x $(@D)
	mv $(@D) "$(BIN_DIR)"
	$(@D) --version
	@ echo "[$@]: Completed successfully!"

# Do not export RCLONE_VERSION, because rclone is weird and processes RCLONE_ envs even for the --version command
# See also: https://github.com/rclone/rclone/issues/4888
rclone/install: RCLONE_VERSION ?= tags/v$(call match_pattern_in_file,$(TARDIGRADE_CI_DOCKERFILE_TOOLS),'rclone/rclone','$(SEMVER_PATTERN)')
rclone/install: | $(BIN_DIR) guard/program/unzip
	@ echo "[$@]: Installing $(@D) $(RCLONE_VERSION) ..."
	$(call download_github_release,$(@D).zip,$(@D),$(@D),$(RCLONE_VERSION),.name | endswith("$(OS)-$(ARCH).zip"))
	unzip $(@D).zip
	mv $(@D)-*/$(@D) $(BIN_DIR)
	rm -rf $(@D)*
	chmod +x $(BIN_DIR)/$(@D)
	$(@D) --version
	@ echo "[$@]: Completed successfully!"

terraform/install: export TERRAFORM_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_DOCKERFILE_TOOLS),'hashicorp/terraform','$(SEMVER_PATTERN)')
terraform/install: | $(BIN_DIR) guard/program/jq
	@ echo "[$@]: Installing $(@D)..."
	$(call download_hashicorp_release,$(@D).zip,$(@D),$(TERRAFORM_VERSION))
	unzip -d $(TMP) $(@D).zip && rm -f $(@D).zip $(TMP)/LICENSE.txt && chmod +x $(TMP)/$(@D)
	mv $(TMP)/$(@D) "$(BIN_DIR)"
	$(@D) --version
	@ echo "[$@]: Completed successfully!"

terragrunt/install: export TERRAGRUNT_VERSION ?= tags/v$(call match_pattern_in_file,$(TARDIGRADE_CI_GITHUB_TOOLS),'gruntwork-io/terragrunt','$(SEMVER_PATTERN)')
terragrunt/install: | $(BIN_DIR) guard/program/jq
	@ $(SELF) install/gh-release/$(@D) FILENAME="$(BIN_DIR)/$(@D)" OWNER=gruntwork-io REPO=$(@D) VERSION=$(TERRAGRUNT_VERSION) QUERY='.name | endswith("$(OS)_$(ARCH)")'

terraform-docs/install: export TFDOCS_VERSION ?= tags/v$(call match_pattern_in_file,$(TARDIGRADE_CI_DOCKERFILE_TOOLS),'terraform-docs/terraform-docs','$(SEMVER_PATTERN)')
terraform-docs/install: | $(BIN_DIR) guard/program/jq
	@ echo "[$@]: Installing $(@D)..."
	$(call stream_github_release,$(@D),$(@D),$(TFDOCS_VERSION),.name | endswith("$(OS)-$(ARCH).tar.gz")) | tar -C "$(BIN_DIR)" -xzv --wildcards --no-anchored $(@D)
	$(@D) --version
	@ echo "[$@]: Completed successfully!"

jq/install: export JQ_VERSION ?= tags/jq-$(call match_pattern_in_file,$(TARDIGRADE_CI_GITHUB_TOOLS),'stedolan/jq','$(SEMVER_PATTERN)')
jq/install: | $(BIN_DIR)
	@ $(SELF) install/gh-release/$(@D) FILENAME="$(BIN_DIR)/$(@D)" OWNER=stedolan REPO=$(@D) VERSION=$(JQ_VERSION) QUERY='.name | endswith("$(OS)64")'

shellcheck/install: export SHELLCHECK_VERSION ?= tags/v$(call match_pattern_in_file,$(TARDIGRADE_CI_DOCKERFILE_TOOLS),'koalaman/shellcheck','$(SEMVER_PATTERN)')
shellcheck/install: $(BIN_DIR) guard/program/xz
	@ echo "[$@]: Installing $(@D)..."
	$(call stream_github_release,koalaman,$(@D),$(SHELLCHECK_VERSION),.name | endswith("$(OS).x86_64.tar.xz")) | tar -C "$(BIN_DIR)" -xJv --wildcards --no-anchored --strip-components=1 $(@D)
	$(@D) --version
	@ echo "[$@]: Completed successfully!"

# For editorconfig-checker, the tar file consists of a single file,
# ./bin/ec-linux-amd64.
ec/install: EC_BASE_NAME := ec-$(OS)-$(ARCH)
ec/install: export EC_VERSION ?= tags/v$(call match_pattern_in_file,$(TARDIGRADE_CI_DOCKERFILE_TOOLS),'mstruebing/editorconfig-checker','$(SEMVER_PATTERN)')
ec/install:
	@ echo "[$@]: Installing $(@D)..."
	$(call stream_github_release,editorconfig-checker,editorconfig-checker,$(EC_VERSION),.name | endswith("$(EC_BASE_NAME).tar.gz")) | tar -C "$(BIN_DIR)" -xzv --wildcards --no-anchored --transform='s/$(EC_BASE_NAME)/ec/' --strip-components=1 $(EC_BASE_NAME)
	$(@D) --version
	@ echo "[$@]: Completed successfully!"

install/pip/% install/pip_pkg_with_no_cli/% install/pip_requirements/% pytest/install: export PIP ?= $(if $(shell pyenv which $(PYTHON) 2> /dev/null),pip,$(PYTHON) -m pip)

install/pip_requirements/%:
	@ echo "[$@]: Installing pip requirements from $*..."
	$(PIP) install -r $*
	@ echo "[$@]: Completed successfully!"

install/pip/%: export PKG_VERSION_CMD ?= $* --version
install/pip/%: | $(BIN_DIR) guard/env/PYPI_PKG_NAME
	@ echo "[$@]: Installing $*..."
	$(PIP) install $(PYPI_PKG_NAME)
	$(PKG_VERSION_CMD)
	@ echo "[$@]: Completed successfully!"

install/pip_pkg_with_no_cli/%: | guard/env/PYPI_PKG_NAME
	@ echo "[$@]: Installing $*..."
	$(PIP) install $(PYPI_PKG_NAME)
	@ echo "[$@]: Completed successfully!"

fixuid/install: export FIXUID_VERSION ?= tags/v$(call match_pattern_in_file,$(TARDIGRADE_CI_GITHUB_TOOLS),'boxboat/fixuid','$(SEMVER_PATTERN)')
fixuid/install: QUERY = .name | endswith("$(OS)-$(ARCH).tar.gz")
fixuid/install: | $(BIN_DIR) guard/program/jq
	@ echo "[$@]: Installing $(@D)..."
	$(call stream_github_release,boxboat,$(@D),$(FIXUID_VERSION),$(QUERY)) | tar -C "$(BIN_DIR)" -xzv --wildcards --no-anchored $(@D)
	which $(@D)
	@ echo "[$@]: Completed successfully!"

black/install: export BLACK_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_PYTHON_TOOLS),'black==','[0-9]+\.[0-9]+(b[0-9]+)?')
black/install:
	@ $(SELF) install/pip/$(@D) PYPI_PKG_NAME='$(@D)==$(BLACK_VERSION)'

python312/%: export PYTHON_312_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_DOCKERFILE_PYTHON312),'python:3.12','$(SEMVER_PATTERN)')

python312/install:
	@ $(SELF) install/pyenv/$(PYTHON_312_VERSION)

python312/select:
	@ $(SELF) select/pyenv/$(PYTHON_312_VERSION)

python312/version:
	@ echo $(PYTHON_312_VERSION)

select/pyenv/%: | guard/program/pyenv
	@ echo "[$@]: Selecting python $(@F)"
	pyenv global $(@F)
	python --version
	@ python --version | grep $(@F) > /dev/null || (echo "[$@]: Failed to select python $(@F)"; exit 1)
	@ echo "[$@]: Completed successfully!"

install/pyenv/%: | guard/program/pyenv
	@ echo "[$@]: Installing python $(@F)"
	pyenv install $(@F)
	pyenv rehash
	@ pyenv versions | grep $(@F) || (echo "[$@]: Failed to install python $(@F)"; exit 1)
	pyenv versions | grep $(@F)
	@ echo "[$@]: Completed successfully!"

# pyenv is not version-pinned by default, so recent python versions are always available
# To get a specific version, export PYENV_VERSION
pyenv/install: export PYENV_INSTALLER ?= https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer
pyenv/install: export PYENV_GIT_TAG = $(PYENV_VERSION)
pyenv/install:
	@ echo "[$@]: Installing $(@D)..."
	$(CURL) $(PYENV_INSTALLER) | bash
	$(@D) --version
	@ echo "[$@]: Completed successfully!"

pytest/install:
	@ $(PIP) install -r $(TERRAFORM_PYTEST_DIR)/requirements.txt

pylint/install: export PYLINT_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_PYTHON_TOOLS),'pylint==','$(SEMVER_PATTERN)')
pylint/install:
	@ $(SELF) install/pip/$(@D) PYPI_PKG_NAME='$(@D)==$(PYLINT_VERSION)'

pylint-pytest/install: export PYLINT_PYTEST_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_PYTHON_TOOLS),'pylint-pytest==','$(SEMVER_PATTERN)')
pylint-pytest/install:
	@ $(SELF) install/pip_pkg_with_no_cli/$(@D) PYPI_PKG_NAME='$(@D)==$(PYLINT_PYTEST_VERSION)'

pydocstyle/install: export PYDOCSTYLE_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_PYTHON_TOOLS),'pydocstyle==','$(SEMVER_PATTERN)')
pydocstyle/install:
	@ $(SELF) install/pip/$(@D) PYPI_PKG_NAME='$(@D)==$(PYDOCSTYLE_VERSION)'

yamllint/install: export YAMLLINT_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_PYTHON_TOOLS),'yamllint==','$(SEMVER_PATTERN)')
yamllint/install:
	@ $(SELF) install/pip/$(@D) PYPI_PKG_NAME='$(@D)==$(YAMLLINT_VERSION)'

cfn-lint/install: export CFN_LINT_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_PYTHON_TOOLS),'cfn-lint==','$(SEMVER_PATTERN)')
cfn-lint/install:
	@ $(SELF) install/pip/$(@D) PYPI_PKG_NAME='$(@D)==$(CFN_LINT_VERSION)'

yq/install: export YQ_VERSION ?= tags/v$(call match_pattern_in_file,$(TARDIGRADE_CI_DOCKERFILE_TOOLS),'mikefarah/yq','$(SEMVER_PATTERN)')
yq/install:
	@ $(SELF) install/gh-release/$(@D) FILENAME="$(BIN_DIR)/$(@D)" OWNER=mikefarah REPO=$(@D) VERSION=$(YQ_VERSION) QUERY='.name | endswith("$(OS)_$(ARCH)")'

bump2version/install: export BUMPVERSION_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_PYTHON_TOOLS),'bump2version==','$(SEMVER_PATTERN)')
bump2version/install:
	@ $(SELF) install/pip/$(@D) PYPI_PKG_NAME='$(@D)==$(BUMPVERSION_VERSION)' PKG_VERSION_CMD="bumpversion -h | grep 'bumpversion: v'"

bumpversion/install: bump2version/install

node/install: export NODE_VERSION ?= 16.x
node/install: export NODE_SOURCE ?= https://deb.nodesource.com/setup_$(NODE_VERSION)
node/install:
	@ echo "[$@]: Installing $(@D)..."
	$(CURL) "$(NODE_SOURCE)" | bash -
	apt-get install nodejs -y
	npm --version
	@ echo "[$@]: Completed successfully"

npm/install: node/install

install/npm/%: | guard/program/npm
	@ echo "[$@]: Installing $*..."
	npm install -g $(NPM_PKG_NAME)
	$* --version
	@ echo "[$@]: Completed successfully!"

bumpversion/%: export BUMPVERSION_ARGS ?=
## Bumps the major, minor, or patch version
bumpversion/major bumpversion/minor bumpversion/patch: | guard/program/bump2version
	@ bumpversion $(BUMPVERSION_ARGS) $(@F)

yaml/%: export FIND_YAML ?= $(GIT_LS_FILES) -- '*.yml' '*.yaml' $(FIND_EXCLUDES)
## Lints YAML files
yaml/lint: | guard/program/yamllint
yaml/lint: export YAMLLINT_CONFIG ?= $(or $(wildcard .yamllint.yml),$(TARDIGRADE_CI_PATH)/.yamllint.yml)
yaml/lint:
	@ echo "[$@]: Running yamllint..."
	$(FIND_YAML) | $(XARGS) yamllint -c $(YAMLLINT_CONFIG) --strict {}
	@ echo "[$@]: Project PASSED yamllint test!"

cfn/%: export FIND_CFN ?= $(GIT_LS_FILES) -- '*.template.cfn.*' $(FIND_EXCLUDES)
## Lints CloudFormation files
cfn/lint: | guard/program/cfn-lint
	$(FIND_CFN) | $(XARGS) cfn-lint -t {}

## Runs editorconfig-checker, aka 'ec', against the project
ec/lint: | guard/program/ec guard/program/git
ec/lint: export ECLINT_FILES ?= $(GIT_LS_FILES) -- ':!:*.bats' $(FIND_EXCLUDES)
ec/lint:
	@ echo "[$@]: Running ec..."
	ec -v $$($(ECLINT_FILES))
	@ echo "[$@]: Project PASSED ec lint test!"

python/%: export PYTHON_FILES ?= $(shell $(GIT_LS_FILES) -- '*.py' $(FIND_EXCLUDES))
## Checks format and lints Python files
python/lint:
	@if [[ -n "$(PYTHON_FILES)" ]]; then $(SELF) python/lint/exec; fi
python/lint/exec: export PYLINT_RCFILE ?= $(TARDIGRADE_CI_PATH)/.pylintrc
python/lint/exec: | guard/program/pylint guard/python_pkg/pylint-pytest guard/program/black guard/program/pydocstyle guard/program/git
python/lint/exec:
	@ echo "[$@]: Linting Python files..."
	@ echo "[$@]: Pylint rcfile:  $(PYLINT_RCFILE)"
	black --check $(PYTHON_FILES)
	for python_file in $(PYTHON_FILES); do \
		echo "[$@]: pylint file: $$python_file"; \
		$(PYTHON) -m pylint --rcfile $(PYLINT_RCFILE) \
			--msg-template="{path}:{line} [{symbol}] {msg}" \
			--report no --score no $$python_file; \
		echo "EXIT CODE=$$?"; \
	done
	pydocstyle $(PYTHON_FILES)
	@ echo "[$@]: Python files PASSED lint test!"

## Formats Python files
python/format:
	@if [[ -n "$(PYTHON_FILES)" ]]; then $(SELF) python/format/exec; fi
python/format/exec: | guard/program/black guard/program/git
python/format/exec:
	@ echo "[$@]: Formatting Python files..."
	black $(PYTHON_FILES)
	@ echo "[$@]: Successfully formatted Python files!"

# Run pytests, typically for unit tests.
export PYTEST_ARGS ?= -v
export PYTEST_USE_LOCALSTACK ?= $(if $(USE_LOCALSTACK),--use-localstack,)
pytest/%: | guard/program/pytest
pytest/%:
	@ echo "[$@] Starting Python tests found under the directory \"$*\""
	pytest $* $(PYTEST_ARGS) $(PYTEST_USE_LOCALSTACK)
	@ echo "[$@]: Tests executed!"

## Lints terraform files
terraform/lint: | guard/program/terraform
	@ echo "[$@]: Linting Terraform files..."
	terraform fmt -recursive -check=true -diff=true
	@ echo "[$@]: Terraform files PASSED lint test!"

## Formats terraform files
terraform/format: | guard/program/terraform
	@ echo "[$@]: Formatting Terraform files..."
	terraform fmt -recursive
	@ echo "[$@]: Successfully formatted terraform files!"

hcl/%: export FIND_HCL ?= $(GIT_LS_FILES) -- '*.hcl' $(FIND_EXCLUDES)

## Validates hcl files
hcl/validate: | guard/program/terraform
	@ echo "[$@]: Validating hcl files..."
	@ $(FIND_HCL) | $(XARGS) bash -c 'cat {} | terraform fmt - > /dev/null 2>&1 || (echo "[$@]: Found invalid HCL file: "{}""; exit 1)'
	@ echo "[$@]: hcl files PASSED validation test!"

## Lints hcl files
hcl/lint: | guard/program/terraform hcl/validate
	@ echo "[$@]: Linting hcl files..."
	@ $(FIND_HCL) | $(XARGS) bash -c 'cat {} | terraform fmt -check=true -diff=true - || (echo "[$@]: Found unformatted HCL file: "{}""; exit 1)'
	@ echo "[$@]: hcl files PASSED lint test!"

## Formats hcl files
hcl/format: | guard/program/terraform hcl/validate
	@ echo "[$@]: Formatting hcl files..."
	$(FIND_HCL) | $(XARGS) bash -c 'echo "$$(cat "{}" | terraform fmt -)" > "{}"'
	@ echo "[$@]: Successfully formatted hcl files!"

sh/%: export FIND_SH ?= $(GIT_LS_FILES) -- '*.sh' $(FIND_EXCLUDES)
## Lints bash script files
sh/lint: | guard/program/shellcheck
	@ echo "[$@]: Linting shell scripts..."
	$(FIND_SH) | $(XARGS) shellcheck {}
	@ echo "[$@]: Shell scripts PASSED lint test!"

json/%: export FIND_JSON ?= $(GIT_LS_FILES) -- '*.json' $(FIND_EXCLUDES)
json/validate:
	@ $(FIND_JSON) | $(XARGS) bash -c 'jq --indent 4 -S . "{}" > /dev/null 2>&1 || (echo "[{}]: Found invalid JSON file: "{}" "; exit 1)'
	@ echo "[$@]: JSON files PASSED validation test!"

## Lints json files
json/lint: | guard/program/jq json/validate
	@ echo "[$@]: Linting JSON files..."
	$(FIND_JSON) | $(XARGS) bash -c 'cmp {} <(jq --indent 4 -S . {})'
	@ echo "[$@]: JSON files PASSED lint test!"

## Formats json files
json/format: | guard/program/jq json/validate
	@ echo "[$@]: Formatting JSON files..."
	$(FIND_JSON) | $(XARGS) bash -c 'echo "$$(jq --indent 4 -S . "{}")" > "{}"'
	@ echo "[$@]: Successfully formatted JSON files!"

# Establish default for TFDOCS
TFDOCS_FILE ?= README.md
TFDOCS_PATH ?= .

# Get lists of existing TF and HCL files
TF_FILES ?= $(wildcard $(TFDOCS_PATH)/*.tf $(TFDOCS_PATH)/modules/*/*.tf)
HCL_FILES ?= $(wildcard $(TFDOCS_PATH)/*.pkr.hcl)

# Get lists of the parent dirs of TF and HCL files
TF_DIRS ?= $(sort $(dir $(TF_FILES)))
HCL_DIRS ?= $(sort $(dir $(HCL_FILES)))

# Get list of existing files matching $(TFDOC_FILE)
TFDOCS_FILES ?= $(wildcard $(TFDOCS_PATH)/$(TFDOCS_FILE) $(TFDOCS_PATH)/modules/*/$(TFDOCS_FILE))

# Get list of intersection of directories with TFDOCS_FILES that are also TF_DIRS or HCL_DIRS
TFDOCS_DIRS ?= $(filter $(TF_DIRS) $(HCL_DIRS),$(sort $(dir $(TFDOCS_FILES) $(HCL_FILES))))

# Establish targets of TFDOCS_FILES that meet requirement for TF and HCL files to exist
TFDOCS_TARGETS ?= $(addsuffix $(TFDOCS_FILE),$(TFDOCS_DIRS))

docs/%: export TFDOCS ?= terraform-docs
docs/%: export TFDOCS_CONFIG ?= $(or $(wildcard .terraform-docs.yml),$(TARDIGRADE_CI_PATH)/.terraform-docs.yml)
docs/%: export TFDOCS_OPTIONS ?= --config $(TFDOCS_CONFIG) --output-file $(TFDOCS_FILE)
docs/%: export TFDOCS_CMD ?= $(TFDOCS) $(TFDOCS_OPTIONS)
docs/%: export TFDOCS_LINT_CMD ?=  $(TFDOCS) --output-check $(TFDOCS_OPTIONS)

## Generates Terraform documentation
docs/generate: $(addprefix docs/generate/,$(TFDOCS_TARGETS))
	@ echo "[$@]: Successfully generated all docs files!"

docs/generate/%: | terraform/format guard/program/terraform-docs
	$(TFDOCS_CMD) $(dir $*)
	@ if [ -e $* ] && [ "$$(tail -c1 '$*')" != "$('\n')" ]; then \
		echo "Adding newline to the end of '$*'"; \
		echo "" >> "$*"; \
	fi

## Lints Terraform documentation
docs/lint: $(addprefix docs/lint/,$(TFDOCS_TARGETS))
	@ echo "[$@]: Docs files PASSED lint test!"

docs/lint/%: | terraform/lint guard/program/terraform-docs
	$(TFDOCS_LINT_CMD) $(dir $*)

docker/%: export IMAGE_NAME ?= $(shell basename $(PWD)):latest

## Builds the tardigrade-ci docker image
docker/build: export PYTHON_312_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_DOCKERFILE_PYTHON312),'python:3.12','$(SEMVER_PATTERN)')
docker/build: export TARDIGRADE_CI_DOCKERFILE ?= Dockerfile
docker/build: export DOCKER_BUILDKIT ?= $(shell [ -z $(TRAVIS) ] && echo "DOCKER_BUILDKIT=1" || echo "DOCKER_BUILDKIT=0";)
docker/build:
	@echo "[$@]: building docker image named: $(IMAGE_NAME)"
	$(DOCKER_BUILDKIT) docker build -t $(IMAGE_NAME) \
		--build-arg PROJECT_NAME=$(TARDIGRADE_CI_PROJECT) \
		--build-arg PYTHON_312_VERSION=$(PYTHON_312_VERSION) \
		--build-arg USER_UID=$$(id -u) \
		--build-arg USER_GID=$$(id -g) \
		$(if $(GITHUB_ACCESS_TOKEN),--secret id=GITHUB_ACCESS_TOKEN$(,)env=GITHUB_ACCESS_TOKEN,) \
		-f $(TARDIGRADE_CI_DOCKERFILE) .
	@echo "[$@]: Docker image build complete"

# Adds the current Makefile working directory as a bind mount
## Runs the tardigrade-ci docker image
docker/run/%:
	@echo "[$@]: Running docker image target=$*"
	@$(SELF) docker/run target=$*
docker/run: export DOCKER_RUN_FLAGS ?= --rm
docker/run: export AWS_DEFAULT_REGION ?= us-east-1
docker/run: export target ?= help
docker/run: export entrypoint ?= entrypoint.sh
docker/run: | guard/env/TARDIGRADE_CI_PATH guard/env/TARDIGRADE_CI_PROJECT
docker/run: docker/build
	@echo "[$@]: Running docker image"
	docker run $(DOCKER_RUN_FLAGS) \
	--user "$$(id -u):$$(id -g)" \
	-v "$(PWD)/:/workdir/" \
	-v "$(TARDIGRADE_CI_PATH)/:/$(TARDIGRADE_CI_PROJECT)/" \
	-v "$(HOME)/.aws/:/home/$(TARDIGRADE_CI_PROJECT)/.aws/:ro" \
	-e AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION) \
	$(if $(AWS_PROFILE),-e AWS_PROFILE=$(AWS_PROFILE),) \
	-e GITHUB_ACCESS_TOKEN=$(GITHUB_ACCESS_TOKEN) \
	-w /workdir/ \
	--entrypoint $(entrypoint) \
	$(IMAGE_NAME) $(target)

## Cleans local docker environment
docker/clean:
	@echo "[$@]: Cleaning docker environment"
	docker image prune -a -f
	docker system prune -a -f
	@echo "[$@]: cleanup successful"

tftest/install: pytest/install

export TERRAFORM_PYTEST_DIR ?= $(TARDIGRADE_CI_PATH)/tests/terraform_pytest
terraform/pytest: | guard/program/terraform guard/python_pkg/tftest
terraform/pytest: | pytest/$(TERRAFORM_PYTEST_DIR)

.PHONY: mockstack/pytest mockstack/up mockstack/down mockstack/clean
export INTEGRATION_TEST_BASE_IMAGE_NAME ?= $(shell basename $(PWD))-integration-test
mockstack/%: export LOCALSTACK_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_DOCKERFILE_TOOLS),'localstack/localstack','$(SEMVER_PATTERN)')
mockstack/%: export MOTO_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_DOCKERFILE_TOOLS),'motoserver/moto','$(SEMVER_PATTERN)')
mockstack/%: export MOCKSTACK ?= localstack
mockstack/pytest:
	@ echo "[$@] Running Terraform tests against LocalStack"
	DOCKER_RUN_FLAGS="--network terraform_pytest_default --rm -e MOCKSTACK_HOST=$(MOCKSTACK) -e PYTEST_ARGS=\"$(PYTEST_ARGS)\"" \
		IMAGE_NAME=$(INTEGRATION_TEST_BASE_IMAGE_NAME):latest \
		$(SELF) docker/run target=terraform/pytest
	@ echo "[$@]: Completed successfully!"

mockstack/up:
	@ echo "[$@] Starting LocalStack container"
	TERRAFORM_PYTEST_DIR=$(TERRAFORM_PYTEST_DIR) docker compose -f $(TERRAFORM_PYTEST_DIR)/docker-compose-localstack.yml up --detach

mockstack/down:
	@ echo "[$@] Stopping LocalStack container"
	TERRAFORM_PYTEST_DIR=$(TERRAFORM_PYTEST_DIR) docker compose -f $(TERRAFORM_PYTEST_DIR)/docker-compose-localstack.yml down

mockstack/clean: | mockstack/down
	@ echo "[$@] Stopping and removing LocalStack image"
	set +o pipefail; docker images | grep $(INTEGRATION_TEST_BASE_IMAGE_NAME) | \
		awk '{print $$1 ":" $$2}' | xargs -r docker rmi

## Runs terraform tests in the tests directory
test: terraform/pytest

bats/install: export BATS_VERSION ?= tags/v$(call match_pattern_in_file,$(TARDIGRADE_CI_DOCKERFILE_TOOLS),'bats/bats','$(SEMVER_PATTERN)')
bats/install:
	$(CURL) $(GITHUB_AUTHORIZATION) $(shell $(CURL) $(GITHUB_AUTHORIZATION) https://api.github.com/repos/bats-core/bats-core/releases/$(BATS_VERSION) | jq -r '.tarball_url') | tar -C $(TMP) -xzvf -
	$(TMP)/bats-core-*/install.sh ~
	bats --version
	rm -rf $(TMP)/bats-core-*
	@ echo "[$@]: Completed successfully!"

bats/test: BATS_OPTS ?= --print-output-on-failure -r *.bats
bats/test: | guard/program/bats
bats/test:
	@ echo "[$@]: Starting make target unit tests"
	cd tests/make; bats $(BATS_OPTS)
	@ echo "[$@]: Completed successfully!"

project/validate:
	@ echo "[$@]: Ensuring the target test folder is not empty"
	[ "$$(ls -A $(PWD))" ] || (echo "Project root folder is empty. Please confirm docker has been configured with the correct permissions" && exit 1)
	@ echo "[$@]: Target test folder validation successful"

lint/install: black/install pylint/install pylint-pytest/install pydocstyle/install
lint/install: pytest/install terraform/install terraform-docs/install cfn-lint/install
lint/install: ec/install shellcheck/install jq/install yamllint/install

install: lint/install
install: rclone/install packer/install pyenv/install

lint: project/validate terraform/lint sh/lint json/lint docs/lint python/lint ec/lint cfn/lint hcl/lint yaml/lint

pullrequest: python/format hcl/format terraform/format json/format docs/generate lint
pr: pullrequest
