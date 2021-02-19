ARCH ?= amd64
OS ?= $(shell uname -s | tr '[:upper:]' '[:lower:'])
CURL ?= curl --fail -sSL
XARGS ?= xargs -I {}
BIN_DIR ?= ${HOME}/bin
TMP ?= /tmp
FIND_EXCLUDES ?= -not \( -name .terraform -prune \) -not \( -name .terragrunt-cache -prune \)

PATH := $(BIN_DIR):${PATH}

MAKEFLAGS += --no-print-directory
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c

PYTHON ?= python3

.PHONY: guard/% %/install %/lint

DEFAULT_HELP_TARGET ?= help
HELP_FILTER ?= .*

TARDIGRADE_CI_PATH ?= $(PWD)
TARDIGRADE_CI_PROJECT ?= tardigrade-ci

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

# Macro to download a hashicorp archive release
# $(call download_hashicorp_release,file,app,version)
download_hashicorp_release = $(CURL) -o $(1) https://releases.hashicorp.com/$(2)/$(3)/$(2)_$(3)_$(OS)_$(ARCH).zip

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
	$(CURL) $(GITHUB_AUTHORIZATION) $(shell $(call parse_github_download_url,$(OWNER),$(REPO),$(VERSION),$(QUERY)))

zip/install:
	@ echo "[$@]: Installing $(@D)..."
	apt-get install zip -y
	@ echo "[$@]: Completed successfully!"

terraform/install: TERRAFORM_VERSION_LATEST := $(CURL) https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r -M '.current_version' | sed 's/^v//'
terraform/install: TERRAFORM_VERSION ?= $(shell $(TERRAFORM_VERSION_LATEST))
terraform/install: | $(BIN_DIR) guard/program/jq
	@ echo "[$@]: Installing $(@D)..."
	$(call download_hashicorp_release,$(@D).zip,$(@D),$(TERRAFORM_VERSION))
	unzip $(@D).zip && rm -f $(@D).zip && chmod +x $(@D)
	mv $(@D) "$(BIN_DIR)"
	$(@D) --version
	@ echo "[$@]: Completed successfully!"

terraform-docs/install: TFDOCS_VERSION ?= tags/v0.10.1
terraform-docs/install: | $(BIN_DIR) guard/program/jq
	@ $(MAKE) install/gh-release/$(@D) FILENAME="$(BIN_DIR)/$(@D)" OWNER=segmentio REPO=$(@D) VERSION=$(TFDOCS_VERSION) QUERY='.name | endswith("$(OS)-$(ARCH)")'

jq/install: JQ_VERSION ?= latest
jq/install: | $(BIN_DIR)
	@ $(MAKE) install/gh-release/$(@D) FILENAME="$(BIN_DIR)/$(@D)" OWNER=stedolan REPO=$(@D) VERSION=$(JQ_VERSION) QUERY='.name | endswith("$(OS)64")'

shellcheck/install: SHELLCHECK_VERSION ?= latest
shellcheck/install: $(BIN_DIR) guard/program/xz
	$(MAKE) -s stream/gh-release/$(@D) OWNER=koalaman REPO=shellcheck VERSION=$(SHELLCHECK_VERSION) QUERY='.name | endswith("$(OS).x86_64.tar.xz")' | tar -xJv
	mv $(@D)-*/$(@D) $(BIN_DIR)
	rm -rf $(@D)-*
	$(@D) --version

# For editorconfig-checker, the tar file consists of a single file,
# ./bin/ec-linux-amd64.
ec/install: EC_BASE_NAME := ec-$(OS)-$(ARCH)
ec/install: EC_VERSION ?= latest
ec/install:
	@ echo "[$@]: Installing $(@D)..."
	$(MAKE) -s stream/gh-release/$(@D) OWNER=editorconfig-checker REPO=editorconfig-checker VERSION=$(EC_VERSION) QUERY='.name | endswith("$(EC_BASE_NAME).tar.gz")' | tar -C "$(BIN_DIR)" --strip-components=1 -xzvf -
	ln -sf "$(BIN_DIR)/$(EC_BASE_NAME)" "$(BIN_DIR)/$(@D)"
	$(@D) --version
	@ echo "[$@]: Completed successfully!"

install/pip/%: PKG_VERSION_CMD ?= $* --version
install/pip/%: | guard/env/PYPI_PKG_NAME
	@ echo "[$@]: Installing $*..."
	$(PYTHON) -m pip install --user $(PYPI_PKG_NAME)
	ln -sf ~/.local/bin/$* $(BIN_DIR)/$*
	$(PKG_VERSION_CMD)
	@ echo "[$@]: Completed successfully!"

install/pip_pkg_with_no_cli/%: | guard/env/PYPI_PKG_NAME
	@ echo "[$@]: Installing $*..."
	$(PYTHON) -m pip install --user $(PYPI_PKG_NAME)

black/install:
	@ $(MAKE) install/pip/$(@D) PYPI_PKG_NAME=$(@D)

pylint/install:
	@ $(MAKE) install/pip/$(@D) PYPI_PKG_NAME=$(@D)

pylint-pytest/install:
	@ $(MAKE) install/pip_pkg_with_no_cli/$(@D) PYPI_PKG_NAME=$(@D)

pydocstyle/install:
	@ $(MAKE) install/pip/$(@D) PYPI_PKG_NAME=$(@D)

yamllint/install:
	@ $(MAKE) install/pip/$(@D) PYPI_PKG_NAME=$(@D)

cfn-lint/install:
	@ $(MAKE) install/pip/$(@D) PYPI_PKG_NAME=$(@D)

yq/install:
	@ $(MAKE) install/pip/$(@D) PYPI_PKG_NAME=$(@D)

bump2version/install:
	@ $(MAKE) install/pip/$(@D) PYPI_PKG_NAME=$(@D) PKG_VERSION_CMD="bumpversion -h | grep 'bumpversion: v'"

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

docs/%: TFDOCS ?= terraform-docs --sort-by-required markdown table
docs/%: README_FILES ?= find . $(FIND_EXCLUDES) -type f -name README.md
docs/%: README_TMP ?= $(TMP)/README.tmp
docs/%: TFDOCS_START_MARKER ?= <!-- BEGIN TFDOCS -->
docs/%: TFDOCS_END_MARKER ?= <!-- END TFDOCS -->

docs/tmp/%: | guard/program/terraform-docs
	@ sed '/$(TFDOCS_START_MARKER)/,/$(TFDOCS_END_MARKER)/{//!d}' $* | awk '{print $$0} /$(TFDOCS_START_MARKER)/ {system("$(TFDOCS) $$(dirname $*)")} /$(TFDOCS_END_MARKER)/ {f=1}' > $(README_TMP)

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
docker/build: GET_IMAGE_ID ?= docker inspect --type=image -f '{{.Id}}' "$(IMAGE_NAME)" 2> /dev/null || true
docker/build: IMAGE_ID ?= $(shell $(GET_IMAGE_ID))
docker/build: DOCKER_BUILDKIT ?= $(shell [ -z $(TRAVIS) ] && echo "DOCKER_BUILDKIT=1" || echo "DOCKER_BUILDKIT=0";)
docker/build:
	@echo "[$@]: building docker image named: $(IMAGE_NAME)"
	[ -n "$(IMAGE_ID)" ] && echo "[$@]: Image already present: $(IMAGE_ID)" || \
	$(DOCKER_BUILDKIT) docker build -t $(IMAGE_NAME) -f Dockerfile .
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
	cd $(TERRAFORM_TEST_DIR) && go mod init tardigarde-ci/tests
	cd $(TERRAFORM_TEST_DIR) && go build ./...
	cd $(TERRAFORM_TEST_DIR) && go mod tidy
	@ echo "[$@]: Completed successfully!"

terratest/test: | guard/program/go
terratest/test: TIMEOUT ?= 20m
terratest/test:
	@ echo "[$@] Starting Terraform tests"
	cd $(TERRAFORM_TEST_DIR) && go test -count=1 -timeout $(TIMEOUT)
	@ echo "[$@]: Completed successfully!"

## Runs terraform tests in the tests directory
test: terratest/test

bats/install: BATS_VERSION ?= latest
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

install: terraform/install shellcheck/install terraform-docs/install bats/install black/install pylint/install pylint-pytest/install pydocstyle/install ec/install yamllint/install cfn-lint/install yq/install bumpversion/install

lint: project/validate terraform/lint sh/lint json/lint docs/lint python/lint ec/lint cfn/lint hcl/lint
