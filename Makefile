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

.PHONY: guard/% %/install %/lint

DEFAULT_HELP_TARGET ?= help/all
HELP_FILTER ?= .*

green = $(shell echo -e '\x1b[32;01m$1\x1b[0m')
yellow = $(shell echo -e '\x1b[33;01m$1\x1b[0m')
red = $(shell echo -e '\x1b[33;31m$1\x1b[0m')

default:: $(DEFAULT_HELP_TARGET)
	@exit 0

## This help screen
help:
	@printf "Available targets:\n\n"
	@$(SELF) make -s help/generate  MAKEFILE_LIST="Makefile" | grep -E "\w($(HELP_FILTER))"

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

GITHUB_ACCESS_TOKEN ?= 4224d33b8569bec8473980bb1bdb982639426a92
# Macro to return the download url for a github release
# For latest release, use version=latest
# To pin a release, use version=tags/<tag>
# $(call parse_github_download_url,owner,repo,version,asset select query)
parse_github_download_url = $(CURL) https://api.github.com/repos/$(1)/$(2)/releases/$(3)?access_token=$(GITHUB_ACCESS_TOKEN) | jq --raw-output  '.assets[] | select($(4)) | .browser_download_url'

# Macro to download a github binary release
# $(call download_github_release,file,owner,repo,version,asset select query)
download_github_release = $(CURL) -o $(1) $(shell $(call parse_github_download_url,$(2),$(3),$(4),$(5)))

# Macro to download a hashicorp archive release
# $(call download_hashicorp_release,file,app,version)
download_hashicorp_release = $(CURL) -o $(1) https://releases.hashicorp.com/$(2)/$(3)/$(2)_$(3)_$(OS)_$(ARCH).zip

guard/env/%:
	@ _="$(or $($*),$(error Make/environment variable '$*' not present))"

guard/program/%:
	@ which $* > /dev/null || $(MAKE) $*/install

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

terraform-docs/install: TFDOCS_VERSION ?= latest
terraform-docs/install: | $(BIN_DIR) guard/program/jq
	@ $(MAKE) install/gh-release/$(@D) FILENAME="$(BIN_DIR)/$(@D)" OWNER=segmentio REPO=$(@D) VERSION=$(TFDOCS_VERSION) QUERY='.name | endswith("$(OS)-$(ARCH)")'

jq/install: JQ_VERSION ?= latest
jq/install: | $(BIN_DIR)
	@ $(MAKE) install/gh-release/$(@D) FILENAME="$(BIN_DIR)/$(@D)" OWNER=stedolan REPO=$(@D) VERSION=$(JQ_VERSION) QUERY='.name | endswith("$(OS)64")'

shellcheck/install: SHELLCHECK_VERSION ?= latest
shellcheck/install: SHELLCHECK_URL ?= https://storage.googleapis.com/shellcheck/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz
shellcheck/install: $(BIN_DIR) guard/program/xz
	$(CURL) $(SHELLCHECK_URL) | tar -xJv
	mv $(@D)-*/$(@D) $(BIN_DIR)
	rm -rf $(@D)-*
	$(@D) --version

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

sh/%: FIND_SH := find . $(FIND_EXCLUDES) -name '*.sh' -type f -print0
## Linst bash script files
sh/lint: | guard/program/shellcheck
	@ echo "[$@]: Linting shell scripts..."
	$(FIND_SH) | $(XARGS) shellcheck {}
	@ echo "[$@]: Shell scripts PASSED lint test!"

json/%: FIND_JSON := find . $(FIND_EXCLUDES) -name '*.json' -type f
## Lints json files
json/lint: | guard/program/jq
	@ echo "[$@]: Linting JSON files..."
	@ $(FIND_JSON) | $(XARGS) bash -c 'jq --indent 4 -S . "{}" > /dev/null 2>&1 || (echo "[{}]: Failed JSON Lint Test"; exit 1)'
	$(FIND_JSON) | $(XARGS) bash -c 'cmp {} <(jq --indent 4 -S . {})'
	@ echo "[$@]: JSON files PASSED lint test!"

## Formats json files
json/format: | guard/program/jq
	@ echo "[$@]: Formatting JSON files..."
	@ $(FIND_JSON) | $(XARGS) bash -c 'jq --indent 4 -S . "{}" > /dev/null 2>&1 || (echo "[{}]: JSON format failed"; exit 1)'
	$(FIND_JSON) | $(XARGS) bash -c 'echo "$$(jq --indent 4 -S . "{}")" > "{}"'
	@ echo "[$@]: Successfully formatted JSON files!"

tfdocs-awk/install: $(BIN_DIR)
tfdocs-awk/install: ARCHIVE := https://github.com/plus3it/tfdocs-awk/archive/0.0.2.tar.gz
tfdocs-awk/install:
	@ $(CURL) $(ARCHIVE) | tar -C $(BIN_DIR) --strip-components=1 --wildcards '*.sh' --wildcards '*.awk' -xzvf - \
	> /dev/null 2>&1 || (echo "[$@]: Failed to install tfdocs-awk"; exit 1)

## Generates terraform documentation
docs/generate: | tfdocs-awk/install guard/program/terraform-docs
	@ echo "[$@]: Creating documentation files.."
	@ bash -eu -o pipefail autodocs.sh -g
	@ echo "[$@]: Documentation generated!"

## Lints terraform documentation
docs/lint: | tfdocs-awk/install guard/program/terraform-docs
	@ echo "[$@] Linting documentation files.."
	@ bash -eu -o pipefail autodocs.sh -l
	@ echo "[$@] documentation linting complete!"

TERRAFORM_TEST_DIR ?= tests/terraform
terratest/install: | guard/program/go
	@ echo "[$@] Installing terratest"
	cd $(TERRAFORM_TEST_DIR) && go mod init tardigarde-ci/tests
	cd $(TERRAFORM_TEST_DIR) && go build ./...
	cd $(TERRAFORM_TEST_DIR) && go mod tidy
	@ echo "[$@]: Completed successfully!"

terratest/test: | guard/program/go
	@ echo "[$@] Starting Terraform tests"
	cd $(TERRAFORM_TEST_DIR) && go test -count=1 -timeout 20m
	@ echo "[$@]: Completed successfully!"

test: terratest/test

BATS_RELEASE ?= 1.1.0
bats/install: $(BIN_DIR)
bats/install: ARCHIVE := https://github.com/bats-core/bats-core/archive/v$(BATS_RELEASE).tar.gz
bats/install:
	$(CURL) $(ARCHIVE) | tar -C $(BIN_DIR) -xzvf - > /dev/null 2>&1 || (echo "[$@]: Download failed"; exit 1)
	$(BIN_DIR)/bats-core-$(BATS_RELEASE)/install.sh ~
	bats --version
	@ echo "[$@]: Completed successfully!"

bats/test: | bats/install guard/program/bats
	@ echo "[$@]: Starting make target unit tests"
	bash -c 'cd tests/make && bats -r *.bats'
	@ echo "[$@]: Completed successfully!"

install: terraform/install shellcheck/install tfdocs-awk/install
