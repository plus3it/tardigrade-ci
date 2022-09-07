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

PATH := $(BIN_DIR):$(PYTHONUSERBASE)/bin:${PATH}

MAKEFLAGS += --no-print-directory
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c

export PYTHON ?= python3

.PHONY: guard/% %/install %/lint

export DEFAULT_HELP_TARGET ?= help
export HELP_FILTER ?= .*

export PWD := $(shell pwd)

export TARDIGRADE_CI_PATH ?= $(PWD)
export TARDIGRADE_CI_PROJECT ?= tardigrade-ci
export TARDIGRADE_CI_DOCKERFILE_TOOLS ?= $(TARDIGRADE_CI_PATH)/Dockerfile.tools
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
	unzip $(@D).zip && rm -f $(@D).zip && chmod +x $(@D)
	mv $(@D) "$(BIN_DIR)"
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
ec/install: export EC_VERSION ?= tags/$(call match_pattern_in_file,$(TARDIGRADE_CI_DOCKERFILE_TOOLS),'mstruebing/editorconfig-checker','$(SEMVER_PATTERN)')
ec/install:
	@ echo "[$@]: Installing $(@D)..."
	$(call stream_github_release,editorconfig-checker,editorconfig-checker,$(EC_VERSION),.name | endswith("$(EC_BASE_NAME).tar.gz")) | tar -C "$(BIN_DIR)" -xzv --wildcards --no-anchored --transform='s/$(EC_BASE_NAME)/ec/' --strip-components=1 $(EC_BASE_NAME)
	$(@D) --version
	@ echo "[$@]: Completed successfully!"

install/pip/% install/pip_pkg_with_no_cli/% pytest/install: export PIP ?= $(if $(shell pyenv which $(PYTHON) 2> /dev/null),pip,$(PYTHON) -m pip)
install/pip/%: export PKG_VERSION_CMD ?= $* --version
install/pip/%: | $(BIN_DIR) guard/env/PYPI_PKG_NAME
	@ echo "[$@]: Installing $*..."
	$(PIP) install $(PYPI_PKG_NAME)
	$(PKG_VERSION_CMD)
	@ echo "[$@]: Completed successfully!"

install/pip_pkg_with_no_cli/%: | guard/env/PYPI_PKG_NAME
	@ echo "[$@]: Installing $*..."
	$(PIP) install $(PYPI_PKG_NAME)

fixuid/install: export FIXUID_VERSION ?= tags/v$(call match_pattern_in_file,$(TARDIGRADE_CI_GITHUB_TOOLS),'boxboat/fixuid','$(SEMVER_PATTERN)')
fixuid/install: QUERY = .name | endswith("$(OS)-$(ARCH).tar.gz")
fixuid/install: | $(BIN_DIR) guard/program/jq
	@ echo "[$@]: Installing $(@D)..."
	$(call stream_github_release,boxboat,$(@D),$(FIXUID_VERSION),$(QUERY)) | tar -C "$(BIN_DIR)" -xzv --wildcards --no-anchored $(@D)
	which $(@D)
	@ echo "[$@]: Completed successfully!"

docker-compose/install: export DOCKER_COMPOSE_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_PYTHON_TOOLS),'docker-compose==','$(SEMVER_PATTERN)')
docker-compose/install:
	@ $(SELF) install/pip/$(@D) PYPI_PKG_NAME='$(@D)==$(DOCKER_COMPOSE_VERSION)'

black/install: export BLACK_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_PYTHON_TOOLS),'black==','[0-9]+\.[0-9]+(b[0-9]+)?')
black/install:
	@ $(SELF) install/pip/$(@D) PYPI_PKG_NAME='$(@D)==$(BLACK_VERSION)'

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
yaml/lint: export YAMLLINT_CONFIG ?= .yamllint.yml
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
export PYTEST_ARGS ?=
export PYTEST_ONLY_MOTO_ARG ?= $(if $(ONLY_MOTO),--only-moto,)
pytest/%: | guard/program/pytest
pytest/%:
	@ echo "[$@] Starting Python tests found under the directory \"$*\""
	pytest $* $(PYTEST_ARGS) $(PYTEST_ONLY_MOTO_ARG)
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

docs/%: export TFDOCS ?= terraform-docs
docs/%: export TFDOCS_MODULES_OPTIONS ?= --hide modules --hide resources --sort-by required
docs/%: export HCLDOCS_MODULES_OPTIONS ?= --hide modules --hide resources --sort-by required --hide outputs --hide requirements --hide providers --indent 3
docs/%: export TFDOCS_OPTIONS ?= $(TFDOCS_RECURSIVE) --output-template '$(TFDOCS_TEMPLATE)' --output-file $(TFDOCS_FILE) markdown table $(TFDOCS_PATH)
docs/%: export TFDOCS_RECURSIVE ?= $(if $(wildcard $(TFDOCS_PATH)/modules),--recursive,)
docs/%: export TFDOCS_TEMPLATE ?= <!-- BEGIN TFDOCS -->\n{{ .Content }}\n\n<!-- END TFDOCS -->
docs/%: export TFDOCS_FILE ?= README.md
docs/%: export TFDOCS_PATH ?= .
docs/%: export README_FILES ?=  $(if $(wildcard $(TFDOCS_FILE)),true,)
#docs/%: export TF_FILES_OLD ?= $(if $(wildcard $(TFDOCS_PATH)/*.tf),true,)
docs/%: export TF_FILES = $(if $(shell find ./ -type f -name '*.tf'), true,)
#docs/%: export HCL_FILES_OLD ?= $(if $(wildcard $(TFDOCS_PATH)/*.pkr.hcl),true,)
docs/%: export HCL_FILES = $(if $(shell find ./ -type f -name '*.pkr.hcl'), true,)
docs/%: export TFCMD_OPTS ?= $(if $(README_FILES),$(if $(TF_FILES),$(TFDOCS_MODULES_OPTIONS),$(if $(HCL_FILES),$(HCLDOCS_MODULES_OPTIONS),)),)
docs/%: export TFDOCS_CMD ?= $(if $(TFCMD_OPTS),$(TFDOCS) $(TFCMD_OPTS) $(TFDOCS_OPTIONS),)
docs/%: export TFDOCS_LINT_CMD ?=  $(if $(TFCMD_OPTS),$(TFDOCS) --output-check $(TFCMD_OPTS) $(TFDOCS_OPTIONS),)

## Generates Terraform documentation
docs/generate: | terraform/format
	@echo "[$@]: TF_FILES: $(TF_FILES)"
	@echo "[$@]: HCL_FILES: $(HCL_FILES)"
	@echo "[$@]: README_FILES: $(README_FILES)"
	@[ "${TFDOCS_CMD}" ] && ( echo "[$@]: Generating docs";) || ( echo "[$@]: No docs to generate";)
	$(TFDOCS_CMD)
	@if [ -n $(README_FILES) ] && [ "$$(tail -c1 $(TFDOCS_FILE))" != "$('\n')" ]; then \
		echo "Adding newline to the end of $(TFDOCS_FILE) file"; \
		echo "" >> $(TFDOCS_FILE); \
	fi

## Lints Terraform documentation
docs/lint: | terraform/lint
	@[ "${TFDOCS_LINT_CMD}" ] && ( echo "[$@]: Linting docs";)  || ( echo "[$@]: No docs to lint";)
	$(TFDOCS_LINT_CMD)

docker/%: export IMAGE_NAME ?= $(shell basename $(PWD)):latest

## Builds the tardigrade-ci docker image
docker/build: export TARDIGRADE_CI_DOCKERFILE ?= Dockerfile
docker/build: export GET_IMAGE_ID ?= docker inspect --type=image -f '{{.Id}}' "$(IMAGE_NAME)" 2> /dev/null || true
docker/build: export IMAGE_ID ?= $(shell $(GET_IMAGE_ID))
docker/build: export DOCKER_BUILDKIT ?= $(shell [ -z $(TRAVIS) ] && echo "DOCKER_BUILDKIT=1" || echo "DOCKER_BUILDKIT=0";)
docker/build:
	@echo "[$@]: building docker image named: $(IMAGE_NAME)"
	[ -n "$(IMAGE_ID)" ] && echo "[$@]: Image already present: $(IMAGE_ID)" || \
	$(DOCKER_BUILDKIT) docker build -t $(IMAGE_NAME) \
		--build-arg PROJECT_NAME=$(TARDIGRADE_CI_PROJECT) \
		--build-arg USER_UID=$$(id -u) \
		--build-arg USER_GID=$$(id -g) \
		-f $(TARDIGRADE_CI_DOCKERFILE) .
	@echo "[$@]: Docker image build complete"

# Adds the current Makefile working directory as a bind mount
## Runs the tardigrade-ci docker image
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

export TERRAFORM_TEST_DIR ?= tests
terratest/install: | guard/program/go
	@ echo "[$@] Installing terratest"
	cd $(TERRAFORM_TEST_DIR) && go mod init tardigrade-ci/tests
	cd $(TERRAFORM_TEST_DIR) && go build ./...
	cd $(TERRAFORM_TEST_DIR) && go mod tidy
	@ echo "[$@]: Completed successfully!"

terratest/test: | guard/program/go
terratest/test: export TIMEOUT ?= 20m
terratest/test:
	@ echo "[$@] Starting Terraform tests"
	cd $(TERRAFORM_TEST_DIR) && go test -count=1 -timeout $(TIMEOUT)
	@ echo "[$@]: Completed successfully!"

export TERRAFORM_PYTEST_DIR ?= $(TARDIGRADE_CI_PATH)/tests/terraform_pytest
terraform/pytest: | guard/program/terraform guard/python_pkg/tftest
terraform/pytest: | pytest/$(TERRAFORM_PYTEST_DIR)

.PHONY: mockstack/pytest mockstack/up mockstack/down mockstack/clean
export INTEGRATION_TEST_BASE_IMAGE_NAME ?= $(shell basename $(PWD))-integration-test
mockstack/%: export LOCALSTACK_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_DOCKERFILE_TOOLS),'localstack/localstack','$(SEMVER_PATTERN)')
mockstack/%: export MOCKSTACK ?= localstack
mockstack/pytest:
	@ echo "[$@] Running Terraform tests against LocalStack"
	DOCKER_RUN_FLAGS="--network terraform_pytest_default --rm -e MOCKSTACK_HOST=$(MOCKSTACK) -e PYTEST_ARGS=\"$(PYTEST_ARGS)\"" \
		IMAGE_NAME=$(INTEGRATION_TEST_BASE_IMAGE_NAME):latest \
		$(SELF) docker/run target=terraform/pytest
	@ echo "[$@]: Completed successfully!"

mockstack/up:
	@ echo "[$@] Starting LocalStack container"
	TERRAFORM_PYTEST_DIR=$(TERRAFORM_PYTEST_DIR) docker-compose -f $(TERRAFORM_PYTEST_DIR)/docker-compose-localstack.yml up --detach

mockstack/down:
	@ echo "[$@] Stopping LocalStack container"
	TERRAFORM_PYTEST_DIR=$(TERRAFORM_PYTEST_DIR) docker-compose -f $(TERRAFORM_PYTEST_DIR)/docker-compose-localstack.yml down

mockstack/clean: | mockstack/down
	@ echo "[$@] Stopping and removing LocalStack image"
	set +o pipefail; docker images | grep $(INTEGRATION_TEST_BASE_IMAGE_NAME) | \
		awk '{print $$1 ":" $$2}' | xargs -r docker rmi

## Runs terraform tests in the tests directory
test: terraform/pytest

bats/install: export BATS_VERSION ?= tags/v$(call match_pattern_in_file,$(TARDIGRADE_CI_DOCKERFILE_TOOLS),'bats/bats','$(SEMVER_PATTERN)')
bats/install:
	$(CURL) $(shell $(CURL) https://api.github.com/repos/bats-core/bats-core/releases/$(BATS_VERSION) | jq -r '.tarball_url') | tar -C $(TMP) -xzvf -
	$(TMP)/bats-core-*/install.sh ~
	bats --version
	rm -rf $(TMP)/bats-core-*
	@ echo "[$@]: Completed successfully!"

bats/test: | guard/program/bats
bats/test:
	@ echo "[$@]: Starting make target unit tests"
	cd tests/make; bats -r *.bats
	@ echo "[$@]: Completed successfully!"

project/validate:
	@ echo "[$@]: Ensuring the target test folder is not empty"
	[ "$$(ls -A $(PWD))" ] || (echo "Project root folder is empty. Please confirm docker has been configured with the correct permissions" && exit 1)
	@ echo "[$@]: Target test folder validation successful"

install: terragrunt/install terraform/install shellcheck/install terraform-docs/install
install: bats/install black/install pylint/install pylint-pytest/install pydocstyle/install pytest/install
install: ec/install yamllint/install cfn-lint/install yq/install bumpversion/install jq/install
install: docker-compose/install rclone/install packer/install

lint: project/validate terraform/lint sh/lint json/lint docs/lint python/lint ec/lint cfn/lint hcl/lint
