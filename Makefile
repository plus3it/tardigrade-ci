ARCH ?= amd64
OS ?= $(shell uname -s | tr '[:upper:]' '[:lower:'])
CURL ?= curl --fail -sSL
XARGS ?= xargs -I {}
BIN_DIR ?= ${HOME}/bin
TMP ?= /tmp
FIND_EXCLUDES ?= -not \( -name .terraform -prune \) -not \( -name .terragrunt-cache -prune \)

# See https://docs.python.org/3/using/cmdline.html#envvar-PYTHONUSERBASE
PYTHONUSERBASE ?= $(HOME)/.local

PATH := $(BIN_DIR):$(PYTHONUSERBASE)/bin:${PATH}

MAKEFLAGS += --no-print-directory
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c

PYTHON ?= python3

.PHONY: guard/% %/install %/lint

DEFAULT_HELP_TARGET ?= help
HELP_FILTER ?= .*

export PWD := $(shell pwd)

TARDIGRADE_CI_PATH ?= $(PWD)
TARDIGRADE_CI_PROJECT ?= tardigrade-ci
TARDIGRADE_CI_DOCKERFILE_TOOLS ?= $(TARDIGRADE_CI_PATH)/Dockerfile.tools
TARDIGRADE_CI_GITHUB_TOOLS ?= $(TARDIGRADE_CI_PATH)/.github/workflows/dependabot_hack.yml
TARDIGRADE_CI_PYTHON_TOOLS ?= $(TARDIGRADE_CI_PATH)/requirements.txt
SEMVER_PATTERN ?= [0-9]+(\.[0-9]+){1,2}

export TARDIGRADE_CI_AUTO_INIT = false

export SELF ?= $(MAKE)

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

# Macro to download a github binary release
# $(call download_github_release,file,owner,repo,version,asset select query)
download_github_release = $(CURL) $(GITHUB_AUTHORIZATION) -o $(1) $(shell $(call parse_github_download_url,$(2),$(3),$(4),$(5)))

# Macro to stream a github binary release
# $(call stream_github_release,owner,repo,version,asset select query)
stream_github_release = $(CURL) $(GITHUB_AUTHORIZATION) $(shell $(call parse_github_download_url,$(1),$(2),$(3),$(4)))

# Macro to download a hashicorp archive release
# $(call download_hashicorp_release,file,app,version)
download_hashicorp_release = $(CURL) -o $(1) https://releases.hashicorp.com/$(2)/$(3)/$(2)_$(3)_$(OS)_$(ARCH).zip

# Macro to match a pattern from a line in a file
# $(call match_pattern_in_file,file,line,pattern)
match_pattern_in_file = $(or $(shell grep $(2) $(1) 2> /dev/null | grep -oE $(3) 2> /dev/null),$(error Could not match pattern from file: file=$(1), line=$(2), pattern=$(3)))

guard/env/%:
	@ _="$(or $($*),$(error Make/environment variable '$*' not present))"

guard/program/%:
	@ which $* > /dev/null || $(MAKE) $*/install

guard/python_pkg/%:
	@ $(PYTHON) -m pip freeze | grep $* > /dev/null || $(MAKE) $*/install

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

terraform/install: TERRAFORM_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_DOCKERFILE_TOOLS),'hashicorp/terraform','$(SEMVER_PATTERN)')
terraform/install: | $(BIN_DIR) guard/program/jq
	@ echo "[$@]: Installing $(@D)..."
	$(call download_hashicorp_release,$(@D).zip,$(@D),$(TERRAFORM_VERSION))
	unzip $(@D).zip && rm -f $(@D).zip && chmod +x $(@D)
	mv $(@D) "$(BIN_DIR)"
	$(@D) --version
	@ echo "[$@]: Completed successfully!"

terragrunt/install: TERRAGRUNT_VERSION ?= tags/v$(call match_pattern_in_file,$(TARDIGRADE_CI_GITHUB_TOOLS),'gruntwork-io/terragrunt','$(SEMVER_PATTERN)')
terragrunt/install: | $(BIN_DIR) guard/program/jq
	@ $(MAKE) install/gh-release/$(@D) FILENAME="$(BIN_DIR)/$(@D)" OWNER=gruntwork-io REPO=$(@D) VERSION=$(TERRAGRUNT_VERSION) QUERY='.name | endswith("$(OS)_$(ARCH)")'

terraform-docs/install: TFDOCS_VERSION ?= tags/v$(call match_pattern_in_file,$(TARDIGRADE_CI_DOCKERFILE_TOOLS),'terraform-docs/terraform-docs','$(SEMVER_PATTERN)')
terraform-docs/install: | $(BIN_DIR) guard/program/jq
	@ echo "[$@]: Installing $(@D)..."
	$(call stream_github_release,$(@D),$(@D),$(TFDOCS_VERSION),.name | endswith("$(OS)-$(ARCH).tar.gz")) | tar -C "$(BIN_DIR)" -xzv --wildcards --no-anchored $(@D)
	$(@D) --version
	@ echo "[$@]: Completed successfully!"

jq/install: JQ_VERSION ?= tags/jq-$(call match_pattern_in_file,$(TARDIGRADE_CI_GITHUB_TOOLS),'stedolan/jq','$(SEMVER_PATTERN)')
jq/install: | $(BIN_DIR)
	@ $(MAKE) install/gh-release/$(@D) FILENAME="$(BIN_DIR)/$(@D)" OWNER=stedolan REPO=$(@D) VERSION=$(JQ_VERSION) QUERY='.name | endswith("$(OS)64")'

shellcheck/install: SHELLCHECK_VERSION ?= tags/v$(call match_pattern_in_file,$(TARDIGRADE_CI_DOCKERFILE_TOOLS),'koalaman/shellcheck','$(SEMVER_PATTERN)')
shellcheck/install: $(BIN_DIR) guard/program/xz
	@ echo "[$@]: Installing $(@D)..."
	$(call stream_github_release,koalaman,$(@D),$(SHELLCHECK_VERSION),.name | endswith("$(OS).x86_64.tar.xz")) | tar -C "$(BIN_DIR)" -xJv --wildcards --no-anchored --strip-components=1 $(@D)
	$(@D) --version
	@ echo "[$@]: Completed successfully!"

# For editorconfig-checker, the tar file consists of a single file,
# ./bin/ec-linux-amd64.
ec/install: EC_BASE_NAME := ec-$(OS)-$(ARCH)
ec/install: EC_VERSION ?= tags/$(call match_pattern_in_file,$(TARDIGRADE_CI_DOCKERFILE_TOOLS),'mstruebing/editorconfig-checker','$(SEMVER_PATTERN)')
ec/install:
	@ echo "[$@]: Installing $(@D)..."
	$(call stream_github_release,editorconfig-checker,editorconfig-checker,$(EC_VERSION),.name | endswith("$(EC_BASE_NAME).tar.gz")) | tar -C "$(BIN_DIR)" -xzv --wildcards --no-anchored --transform='s/$(EC_BASE_NAME)/ec/' --strip-components=1 $(EC_BASE_NAME)
	$(@D) --version
	@ echo "[$@]: Completed successfully!"

install/pip/%: PKG_VERSION_CMD ?= $* --version
install/pip/%: PIP ?= $(if $(shell pyenv which $(PYTHON) 2> /dev/null),pip,$(PYTHON) -m pip)
install/pip/%: | $(BIN_DIR) guard/env/PYPI_PKG_NAME
	@ echo "[$@]: Installing $*..."
	$(PIP) install $(PYPI_PKG_NAME)
	$(PKG_VERSION_CMD)
	@ echo "[$@]: Completed successfully!"

install/pip_pkg_with_no_cli/%: PIP ?= $(if $(shell pyenv which $(PYTHON) 2> /dev/null),pip,$(PYTHON) -m pip)
install/pip_pkg_with_no_cli/%: | guard/env/PYPI_PKG_NAME
	@ echo "[$@]: Installing $*..."
	$(PIP) install $(PYPI_PKG_NAME)

docker-compose/install: DOCKER_COMPOSE_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_PYTHON_TOOLS),'docker-compose==','$(SEMVER_PATTERN)')
docker-compose/install:
	@ $(MAKE) install/pip/$(@D) PYPI_PKG_NAME='$(@D)==$(DOCKER_COMPOSE_VERSION)'

black/install: BLACK_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_PYTHON_TOOLS),'black==','[0-9]+\.[0-9]+(b[0-9]+)?')
black/install:
	@ $(MAKE) install/pip/$(@D) PYPI_PKG_NAME='$(@D)==$(BLACK_VERSION)'

tftest/install: TFTEST_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_PYTHON_TOOLS),'tftest==','$(SEMVER_PATTERN)')
tftest/install:
	@ $(MAKE) install/pip_pkg_with_no_cli/$(@D) PYPI_PKG_NAME='$(@D)==$(TFTEST_VERSION)'

pytest/install: PYTEST_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_PYTHON_TOOLS),'^pytest==','$(SEMVER_PATTERN)')
pytest/install:
	@ $(MAKE) install/pip/$(@D) PYPI_PKG_NAME='$(@D)==$(PYTEST_VERSION)'

pylint/install: PYLINT_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_PYTHON_TOOLS),'pylint==','$(SEMVER_PATTERN)')
pylint/install:
	@ $(MAKE) install/pip/$(@D) PYPI_PKG_NAME='$(@D)==$(PYLINT_VERSION)'

pylint-pytest/install: PYLINT_PYTEST_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_PYTHON_TOOLS),'pylint-pytest==','$(SEMVER_PATTERN)')
pylint-pytest/install:
	@ $(MAKE) install/pip_pkg_with_no_cli/$(@D) PYPI_PKG_NAME='$(@D)==$(PYLINT_PYTEST_VERSION)'

pydocstyle/install: PYDOCSTYLE_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_PYTHON_TOOLS),'pydocstyle==','$(SEMVER_PATTERN)')
pydocstyle/install:
	@ $(MAKE) install/pip/$(@D) PYPI_PKG_NAME='$(@D)==$(PYDOCSTYLE_VERSION)'

yamllint/install: YAMLLINT_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_PYTHON_TOOLS),'yamllint==','$(SEMVER_PATTERN)')
yamllint/install:
	@ $(MAKE) install/pip/$(@D) PYPI_PKG_NAME='$(@D)==$(YAMLLINT_VERSION)'

cfn-lint/install: CFN_LINT_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_PYTHON_TOOLS),'cfn-lint==','$(SEMVER_PATTERN)')
cfn-lint/install:
	@ $(MAKE) install/pip/$(@D) PYPI_PKG_NAME='$(@D)==$(CFN_LINT_VERSION)'

yq/install: YQ_VERSION ?= tags/v$(call match_pattern_in_file,$(TARDIGRADE_CI_DOCKERFILE_TOOLS),'mikefarah/yq','$(SEMVER_PATTERN)')
yq/install:
	@ $(MAKE) install/gh-release/$(@D) FILENAME="$(BIN_DIR)/$(@D)" OWNER=mikefarah REPO=$(@D) VERSION=$(YQ_VERSION) QUERY='.name | endswith("$(OS)_$(ARCH)")'

bump2version/install: BUMPVERSION_VERSION ?= $(call match_pattern_in_file,$(TARDIGRADE_CI_PYTHON_TOOLS),'bump2version==','$(SEMVER_PATTERN)')
bump2version/install:
	@ $(MAKE) install/pip/$(@D) PYPI_PKG_NAME='$(@D)==$(BUMPVERSION_VERSION)' PKG_VERSION_CMD="bumpversion -h | grep 'bumpversion: v'"

bumpversion/install: bump2version/install

node/install: NODE_VERSION ?= 10.x
node/install: NODE_SOURCE ?= https://deb.nodesource.com/setup_$(NODE_VERSION)
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

bumpversion/%: BUMPVERSION_ARGS ?=
## Bumps the major, minor, or patch version
bumpversion/major bumpversion/minor bumpversion/patch: | guard/program/bump2version
	@ bumpversion $(BUMPVERSION_ARGS) $(@F)

yaml/%: FIND_YAML ?= find . $(FIND_EXCLUDES) -type f \( -name '*.yml' -o -name "*.yaml" \)
## Lints YAML files
yaml/lint: | guard/program/yamllint
yaml/lint: YAMLLINT_CONFIG ?= .yamllint.yml
yaml/lint:
	@ echo "[$@]: Running yamllint..."
	$(FIND_YAML) | $(XARGS) yamllint -c $(YAMLLINT_CONFIG) --strict {}
	@ echo "[$@]: Project PASSED yamllint test!"

cfn/%: FIND_CFN ?= find . $(FIND_EXCLUDES) -name '*.template.cfn.*' -type f
## Lints CloudFormation files
cfn/lint: | guard/program/cfn-lint
	$(FIND_CFN) | $(XARGS) cfn-lint -t {}

## Runs editorconfig-checker, aka 'ec', against the project
ec/lint: | guard/program/ec guard/program/git
ec/lint: ECLINT_FILES ?= $(shell git ls-files | grep -v ".bats")
ec/lint:
	@ echo "[$@]: Running ec..."
	ec $(ECLINT_FILES)
	@ echo "[$@]: Project PASSED ec lint test!"

python/%: PYTHON_FILES ?= $(shell git ls-files --cached --others --exclude-standard '*.py')
## Checks format and lints Python files
python/lint: PYLINT_RCFILE ?= $(TARDIGRADE_CI_PATH)/.pylintrc
python/lint: | guard/program/pylint guard/python_pkg/pylint-pytest guard/program/black guard/program/pydocstyle guard/program/git
python/lint:
	@ echo "[$@]: Linting Python files..."
	@ echo "[$@]: Pylint rcfile:  $(PYLINT_RCFILE)"
	black --check $(PYTHON_FILES)
	for python_file in $(PYTHON_FILES); do \
		$(PYTHON) -m pylint --rcfile $(PYLINT_RCFILE) \
			--msg-template="{path}:{line} [{symbol}] {msg}" \
			-rn -sn $$python_file; \
	done
	pydocstyle $(PYTHON_FILES)
	@ echo "[$@]: Python files PASSED lint test!"

## Formats Python files
python/format: | guard/program/black guard/program/git
python/format:
	@ echo "[$@]: Formatting Python files..."
	black $(PYTHON_FILES)
	@ echo "[$@]: Successfully formatted Python files!"

# Run pytests, typically for unit tests.
PYTEST_ARGS ?=
pytest/%: | guard/program/pytest
pytest/%:
	@ echo "[$@] Starting Python tests found under the directory \"$*\""
	pytest $* $(PYTEST_ARGS)
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

hcl/%: FIND_HCL := find . $(FIND_EXCLUDES) -type f \( -name "*.hcl" \)

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

sh/%: FIND_SH := find . $(FIND_EXCLUDES) -name '*.sh' -type f
## Lints bash script files
sh/lint: | guard/program/shellcheck
	@ echo "[$@]: Linting shell scripts..."
	$(FIND_SH) | $(XARGS) shellcheck {}
	@ echo "[$@]: Shell scripts PASSED lint test!"

json/%: FIND_JSON := find . $(FIND_EXCLUDES) -name '*.json' -type f
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

docs/%: TFDOCS ?= terraform-docs --hide modules --hide resources --sort-by required markdown table
docs/%: README_FILES ?= find . $(FIND_EXCLUDES) -type f -name README.md
docs/%: README_TMP ?= $(TMP)/README.tmp
docs/%: TFDOCS_START_MARKER ?= <!-- BEGIN TFDOCS -->
docs/%: TFDOCS_END_MARKER ?= <!-- END TFDOCS -->

docs/tmp/%: | guard/program/terraform-docs
	@ sed '/$(TFDOCS_START_MARKER)/,/$(TFDOCS_END_MARKER)/{//!d}' $* | awk '{print $$0} /$(TFDOCS_START_MARKER)/ {system("echo \"$$($(TFDOCS) $$(dirname $*))\"; echo")} /$(TFDOCS_END_MARKER)/ {f=1}' > $(README_TMP)

docs/generate/%:
	@ echo "[$@]: Creating documentation files.."
	@ $(MAKE) docs/tmp/$*
	mv -f $(README_TMP) $*
	@ echo "[$@]: Documentation files creation complete!"

docs/lint/%:
	@ echo "[$@]: Linting documentation files.."
	@ $(MAKE) docs/tmp/$*
	diff $* $(README_TMP)
	rm -f $(README_TMP)
	@ echo "[$@]: Documentation files PASSED lint test!"

## Generates Terraform documentation
docs/generate: | terraform/format
	@ $(README_FILES) | $(XARGS) $(MAKE) docs/generate/{}

## Lints Terraform documentation
docs/lint: | terraform/lint
	@ $(README_FILES) | $(XARGS) $(MAKE) docs/lint/{}

docker/%: IMAGE_NAME ?= $(shell basename $(PWD)):latest

## Builds the tardigrade-ci docker image
docker/build: TARDIGRADE_CI_DOCKERFILE ?= Dockerfile
docker/build: GET_IMAGE_ID ?= docker inspect --type=image -f '{{.Id}}' "$(IMAGE_NAME)" 2> /dev/null || true
docker/build: IMAGE_ID ?= $(shell $(GET_IMAGE_ID))
docker/build: DOCKER_BUILDKIT ?= $(shell [ -z $(TRAVIS) ] && echo "DOCKER_BUILDKIT=1" || echo "DOCKER_BUILDKIT=0";)
docker/build:
	@echo "[$@]: building docker image named: $(IMAGE_NAME)"
	[ -n "$(IMAGE_ID)" ] && echo "[$@]: Image already present: $(IMAGE_ID)" || \
	$(DOCKER_BUILDKIT) docker build -t $(IMAGE_NAME) \
		--build-arg USER_UID=$$(id -u) \
		--build-arg USER_GID=$$(id -g) \
		-f $(TARDIGRADE_CI_DOCKERFILE) .
	@echo "[$@]: Docker image build complete"

# Adds the current Makefile working directory as a bind mount
## Runs the tardigrade-ci docker image
docker/run: DOCKER_RUN_FLAGS ?= --rm
docker/run: AWS_DEFAULT_REGION ?= us-east-1
docker/run: target ?= help
docker/run: entrypoint ?= make
docker/run: | guard/env/TARDIGRADE_CI_PATH guard/env/TARDIGRADE_CI_PROJECT
docker/run: docker/build
	@echo "[$@]: Running docker image"
	docker run $(DOCKER_RUN_FLAGS) \
	-v "$(PWD)/:/workdir/" \
	-v "$(TARDIGRADE_CI_PATH)/:/$(TARDIGRADE_CI_PROJECT)/" \
	-v "$(HOME)/.aws/:/root/.aws/" \
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

TERRAFORM_TEST_DIR ?= tests
terratest/install: | guard/program/go
	@ echo "[$@] Installing terratest"
	cd $(TERRAFORM_TEST_DIR) && go mod init tardigrade-ci/tests
	cd $(TERRAFORM_TEST_DIR) && go build ./...
	cd $(TERRAFORM_TEST_DIR) && go mod tidy
	@ echo "[$@]: Completed successfully!"

terratest/test: | guard/program/go
terratest/test: TIMEOUT ?= 20m
terratest/test:
	@ echo "[$@] Starting Terraform tests"
	cd $(TERRAFORM_TEST_DIR) && go test -count=1 -timeout $(TIMEOUT)
	@ echo "[$@]: Completed successfully!"

TERRAFORM_PYTEST_DIR ?= $(TARDIGRADE_CI_PATH)/tests/terraform_pytest
terraform/pytest: | guard/program/terraform guard/python_pkg/tftest
terraform/pytest: | pytest/$(TERRAFORM_PYTEST_DIR)

.PHONY: mockstack/pytest mockstack/up mockstack/down mockstack/clean
INTEGRATION_TEST_BASE_IMAGE_NAME ?= $(shell basename $(PWD))-integration-test
mockstack/%: MOCKSTACK ?= localstack
mockstack/pytest:
	@ echo "[$@] Running Terraform tests against LocalStack"
	DOCKER_RUN_FLAGS="--network terraform_pytest_default --rm -e MOCKSTACK_HOST=$(MOCKSTACK) -e PYTEST_ARGS=\"$(PYTEST_ARGS)\"" \
		IMAGE_NAME=$(INTEGRATION_TEST_BASE_IMAGE_NAME):latest \
		$(MAKE) docker/run target=terraform/pytest
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

bats/install: BATS_VERSION ?= tags/v$(call match_pattern_in_file,$(TARDIGRADE_CI_DOCKERFILE_TOOLS),'bats/bats','$(SEMVER_PATTERN)')
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
install: bats/install black/install pylint/install pylint-pytest/install pydocstyle/install pytest/install tftest/install
install: ec/install yamllint/install cfn-lint/install yq/install bumpversion/install jq/install
install: docker-compose/install

lint: project/validate terraform/lint sh/lint json/lint docs/lint python/lint ec/lint cfn/lint hcl/lint
