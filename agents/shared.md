# Shared Plus3 IT Agent Instructions

## Overview

Plus3 IT repositories use tardigrade-ci for linting, testing, and releases. Run `make help` to list every target, and prefer make targets over running tools directly. Repository-specific instructions follow this shared section.

## Before you finish

1. Run `make lint`.
2. Run the tests described in Repository-specific → Testing.
3. For user-visible changes in a repository with `.bumpversion.cfg` (unless a profile or the Repository-specific section says the repository is not versioned or released): add a `CHANGELOG.md` entry ([Keep a Changelog](http://keepachangelog.com/) format) that links each change to the pull request that implemented it, and commit it with your changes. Then run `make bumpversion/patch` (or `minor` or `major`), which creates its own commit. Both commits go in the same pull request. If that pull request isn't open yet, leave its link for the person who opens it and say so in your final report.
4. In the description of a pull request that bumps the version, include a comparison link to the last release (on GitHub, `https://github.com/<owner>/<repo>/compare/<last-tag>...<branch>`; for a fork's branch, `<owner>:<branch>`).
5. Regenerate any generated docs, for example `make docs/generate` for Terraform module READMEs.
6. In your final report, list everything a person must still do (pushes, pull requests, applies, account or credential setup) and anything you could not verify.

## Tooling

- `make lint`, `make test`, and `make <lang>/format` (for example, `make terraform/format`).
- `make docker/run target=<target>` runs a target inside the pinned tardigrade-ci container.
- The `Dockerfile` line `FROM plus3it/tardigrade-ci:<version>` pins tardigrade-ci, and the Makefile bootstrap clones the same version.

## Releases

On GitHub, merging a version bump to the default branch runs `.github/workflows/release.yml`, which creates a release and tag for the new version; GitHub generates the release notes. On other hosts, see Repository-specific → CI/CD.

## Dependency automation

- **GitHub**: Dependabot (`.github/dependabot.yml`) opens update pull requests, and Mergify (`.mergify.yml`) auto-approves and merges them.
- **Other hosts (for example, GitLab)**: Renovate (`renovate.json`), run from the host's CI.

## Formatting

Follow `.editorconfig`; check with `make ec/lint`.
