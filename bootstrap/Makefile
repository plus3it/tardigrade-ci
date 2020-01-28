BIN_DIR ?= ${HOME}/bin
TMP ?= /tmp

PATH := $(BIN_DIR):${PATH}
SHELL = /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c
export SELF ?= $(MAKE)

IMAGE_NAME := $(shell basename $(PROJECT_ROOT)):latest

DEFAULT_HELP_TARGET ?= help
HELP_FILTER ?= .*

green = $(shell echo -e '\x1b[32;01m$1\x1b[0m')
yellow = $(shell echo -e '\x1b[33;01m$1\x1b[0m')
red = $(shell echo -e '\x1b[33;31m$1\x1b[0m')

default:: $(DEFAULT_HELP_TARGET)
	@exit 0

## This help screen
help:
	@printf "Available targets:\n\n"
	@$(SELF) -s help/generate  MAKEFILE_LIST="$(TARDIGRADE_CI_PATH)/bootstrap/Makefile" | grep -E "\w($(HELP_FILTER))"

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

## Builds the tardigrade-ci docker image
docker/build: GET_IMAGE_ID := docker inspect --type=image -f '{{.Id}}' "$(IMAGE_NAME)" 2> /dev/null || true
docker/build: IMAGE_ID ?= $(shell $(GET_IMAGE_ID))
docker/build: DOCKER_BUILDKIT ?= $(shell [ -z $(TRAVIS) ] && echo "DOCKER_BUILDKIT=1" || echo "DOCKER_BUILDKIT=0";)
docker/build:
	@echo "[$@]: building docker image"
	[ -z $(IMAGE_ID) ] && $(DOCKER_BUILDKIT) docker build -t $(IMAGE_NAME) -f $(PROJECT_ROOT)Dockerfile . || echo "Image present"
	@echo "[$@]: Docker image build complete"

# Adds the current Makefile working directory as a bind mount
## Runs the tardigrade-ci docker image
docker/run: DOCKER_RUN_FLAGS ?= --rm
docker/run: AWS_DEFAULT_REGION ?= us-east-1
docker/run: target ?= help
docker/run: docker/build
	@echo "[$@]: Running docker image"
	docker run $(DOCKER_RUN_FLAGS) \
	-v "$(PROJECT_ROOT):/ci-harness/$(PROJECT_NAME)" \
	-v "$(HOME)/.aws:/.aws" \
	-e TERRAFORM_TEST_DIR=$(PROJECT_NAME)/tests \
	-e AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION) \
	-e AWS_PROFILE=$(AWS_PROFILE) \
	-e AWS_SHARED_CREDENTIALS_FILE=/.aws/credentials \
	-e INCLUDE=/ci-harness/$(PROJECT_NAME)/Makefile \
	$(IMAGE_NAME) $(target)

## Cleans local docker environment
docker/clean:
	@echo "[$@]: Cleaning docker environment"
	docker image prune -a -f
	@echo "[$@]: cleanup successful"
