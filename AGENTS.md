# Agent Instructions for tardigrade-ci

## Overview

tardigrade-ci is a shared tooling project that provides a Docker image and Makefile targets
to standardize development workflows. Consumer projects include salt formulas, Terraform
modules, and tardigrade deployment repos. This file documents how to develop tardigrade-ci
itself. Changes here affect every consumer, so keep them generic and backward compatible.

## Before you finish

Before reporting your work as complete:

1. Run `make lint` to catch formatting and style issues
2. If you modified Makefile targets, run `make bats/test` to verify the changes
3. For user-visible changes:
    - Add an entry to `CHANGELOG.md` following [Keep a Changelog](http://keepachangelog.com/) format
    - Commit your changes, including the CHANGELOG.md entry
    - Run `make bumpversion/patch` (or `minor` or `major`), which creates its own commit
    - Both commits go in the same pull request
4. In your final report, list what a person must do: push the branch, open a pull request, and anything you could not verify

## Tool Version Pinning

Tool versions are pinned in multiple locations. The Makefile extracts versions using the
`match_pattern_in_file` macro (greps a pattern from a file).

### Dockerfile.tools

Container-based tools (terraform, packer, shellcheck, yq, moto, localstack, ec, terraform-docs,
rclone, bats) are pinned as `FROM` statements. Dependabot updates these via the `docker`
package ecosystem. The Makefile reads versions from this file.

### mise.toml

Tools installed from GitHub releases (jq, terragrunt, uv) are pinned here. The Makefile
reads versions from this file. `.github/dependabot.yml` has no ecosystem configured for
`mise.toml`, so these pins are not updated automatically; bump them by hand.

### requirements.txt

Python packages (black, bump2version, cfn-lint, pydocstyle, pylint, yamllint) are pinned here.
Dependabot updates these via the `pip` package ecosystem. Keep alphabetical with blank lines
between entries.

### .github/workflows/dependabot_hack.yml

This workflow file is never executed (triggers on `never-trigger-this-dependabot-hack-workflow`).
Listing a GitHub project as an action step in it lets Dependabot (`github-actions` ecosystem)
open PRs when that project releases. Tool pins moved from this file to `mise.toml`, and it
currently lists no tools; the Makefile reads versions from `mise.toml`.

This approach is a last resort: GitHub prevents Mergify from auto-merging PRs that modify
`.github/workflows`, so these updates require manual merge. Only add tools here if there's
no other option for pinning the version.

## Make Targets

### Documentation Convention

Each target is documented with a `## ` comment on the line immediately before the target
definition. `make help` extracts these comments.

### Naming Conventions

- `<tool>/install` — install a tool
- `<lang>/lint` — lint files
- `<lang>/format` — format files
- `guard/program/<tool>` — ensure a program is installed
- `guard/python_pkg/<package>` — ensure a Python package is installed
- `guard/env/<VAR>` — ensure an environment variable is set

Guard targets enforce prerequisites. A target declares guards as order-only dependencies:

```make
terraform/install: | $(BIN_DIR) guard/program/jq
```

## Bootstrap Mechanism

Consumer repos include `bootstrap/Makefile.bootstrap` to access tardigrade-ci targets. The
bootstrap Makefile detects the tardigrade-ci version from the consumer's Dockerfile (greps
`FROM plus3it/tardigrade-ci:<version>`), clones tardigrade-ci at that version, and includes
its Makefile. The consumer's include line downloads `bootstrap/Makefile.bootstrap` from the
`master` branch into a gitignored `.tardigrade-ci` file only when that file is missing (a fresh
clone, a CI run, or after `make clean`), so changes to the bootstrap file reach consumers then,
regardless of their pinned version. Changes to the Makefile reach consumers when they bump the
pinned version; the bootstrap re-clones tardigrade-ci when the local clone does not match it.

## Testing

### BATS Unit Tests

BATS tests in `tests/make/*.bats` verify make targets. Run via CI:

```bash
make bats/test
```

CI runs BATS tests on every PR (see `.github/workflows/build.yml`).

### Integration Tests

`make test` (aliased to `terraform/pytest`) runs integration tests for terraform module
testing support. Tests use moto by default; set `USE_LOCALSTACK` to use LocalStack instead.
`ONLY_MOTO` is obsolete and has no effect. See INTEGRATION_TESTING.md for details:

- `make mockstack/pytest` — run pytest in a Docker container with mock AWS
- `make terraform/pytest` — run pytest (requires mock stack already running)
- `make mockstack/up` / `mockstack/down` — manage the mock stack

See TESTING.md for manual bootstrap testing procedures.

## Release Process

### Versioning

Version is managed by `bump2version` (`.bumpversion.cfg`). To bump the version:

```bash
make bumpversion/patch  # or minor, major
```

### Release Flow

1. Create a PR with CHANGELOG.md updates and run `make bumpversion/patch` (or minor/major)
2. Merge the PR to master
3. `.github/workflows/release.yml` triggers on push to master when `.bumpversion.cfg` changes
4. The release workflow uses `plus3it/actions-workflows/.github/workflows/release.yml`, which
  creates a GitHub Release and tag if `current_version` differs from the latest tag
5. `.github/workflows/build.yml` triggers on push to master and on `release: released`. Pushes
  to master publish the `latest` tag. Releases publish semver tags to Docker Hub
  (`plus3it/tardigrade-ci`) and GHCR (`ghcr.io/plus3it/tardigrade-ci`)

Consumers pin the image version in their Dockerfile (`FROM plus3it/tardigrade-ci:<version>`).
The bootstrap Makefile reads this version and clones the matching release.

## Repository Automation

### Dependabot

`.github/dependabot.yml` configures weekly PRs for:
- `pip` packages in `/` and `/tests/terraform_pytest`
- `docker` images in `Dockerfile.tools` and Python version pins
- `github-actions` workflows

### Mergify

`.mergify.yml` auto-approves and merges Dependabot PRs (requires 1 approval). No other
auto-merge rules are configured.

## Formatting

`.editorconfig` defines formatting rules. Run `make ec/lint` to check compliance. For
language-specific linting, see `make help`.

## Docker Image

The image (`Dockerfile`) is based on Debian (version pinned in Dockerfile) and includes all
pinned tools, Python runtimes managed by uv, and the Go toolchain. Build via `make docker/build`.

Consumers run targets via `make docker/run target=<target>`. This mounts the current directory
at `/workdir/`, the tardigrade-ci checkout at `/<project>/`, and `~/.aws/` (read-only).

## Adding a New Tool

1. Pin the version in `Dockerfile.tools` (container images) or `mise.toml` (GitHub releases)
2. Add a `<tool>/install` target in the Makefile using `match_pattern_in_file`
3. Add `guard/program/<tool>` dependencies to any target that needs the tool

## Adding a New Make Target

1. Write the target following naming conventions
2. Add a `## ` comment on the line before the target for `make help`
3. Declare prerequisites using `guard/` targets with `|` for order-only dependencies
4. Test in both the Docker image and via local include
5. Add a BATS test in `tests/make/` for core functionality
