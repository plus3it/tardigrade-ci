# Terraform Module Profile

## Layout

Root module files:
- `main.tf` — Module resources and data sources
- `variables.tf` — Input variables
- `outputs.tf` — Output values
- `versions.tf` — The `terraform` block with `required_version` and `required_providers`. Declare these only here, never in `main.tf`. If they are declared elsewhere, or `versions.tf` is missing, move or create them here
- `migrations.tf` — All `moved` blocks, so users can upgrade the module without destroying and recreating resources. Keep them only here. If you find `moved` blocks in another file, move them to `migrations.tf`
- `modules/<name>/` — Submodules (if present), each with its own `versions.tf`; `make docs/generate` also updates their READMEs

Test scenarios in `tests/<scenario>/`:
- Each test scenario directory contains `main.tf` that uses the module
- If a test requires prerequisite resources, those Terraform files go in a `prereq/` subdirectory within the test scenario
- Some modules also have Python tests, Lambda source, and requirements files. Follow the existing pattern.
- Do not add `.tftest.hcl` tests; these modules don't use them.

## Interface changes

When adding or changing a variable, output or required version:
1. Update the README documentation by running `make docs/generate`. This regenerates the content between `<!-- BEGIN TFDOCS -->` and `<!-- END TFDOCS -->` markers. Do not edit the generated tables manually.
2. If the change renames or moves a resource address (for example, adding `count` or `for_each`), add a `moved` block to `migrations.tf` (create it if absent; never put `moved` blocks in other files) so existing users do not destroy and recreate resources.
3. For new or changed inputs, add a test scenario under `tests/` that exercises them.
4. Add an entry to `CHANGELOG.md` following [Keep a Changelog](http://keepachangelog.com/) format, linking the pull request that implements the change.
5. Commit your changes, including the CHANGELOG.md entry.
6. Run the appropriate semantic version bump, which creates its own commit:
    - `make bumpversion/patch` — Bug fixes (1.2.3 → 1.2.4)
    - `make bumpversion/minor` — New features, backward-compatible (1.2.3 → 1.3.0)
    - `make bumpversion/major` — Breaking changes, including variable removals or type changes (1.2.3 → 2.0.0)
7. Both commits go in the same pull request, and its description includes a comparison link to the last release.

## Testing

Tests run in Docker using mockstack. CI uses the plus3it/actions-workflows `test.yml` workflow, which runs:

```bash
make mockstack/up       # Start the mock AWS stack
make mockstack/pytest   # Run tests
make mockstack/clean    # Clean up
```

Run exactly these three commands (Docker is required). The exception is a module whose `.github/workflows/test.yml` sets `mockstacktest-enable: false`. That module doesn't use the mock stack, so follow Repository-specific → Testing. (The same setting in `release.yml` is normal.)

Do not substitute with `make test` or `make docker/run target=test`: they do not start the mock AWS services, and host `make test` uses host Python packages, which can differ from the versions tardigrade-ci pins in its `tests/terraform_pytest/requirements.txt`. If Docker is unavailable, say so in your final report.

Tests use moto by default. Set `USE_LOCALSTACK` (for example, `USE_LOCALSTACK := true` in the Makefile) only if a test needs LocalStack. `ONLY_MOTO` is obsolete and has no effect; if a Makefile still sets it, it can be removed.

Each test scenario in `tests/` must contain:
- `main.tf` — Terraform configuration that uses the module
- `prereq/` subdirectory (optional) — Terraform files to create prerequisite resources before the test runs

New features should include a corresponding test scenario.

## CI/CD

Pull requests trigger workflows for linting and testing. Check the repository's `.github/workflows` directory for the actual workflows in use. Common workflows from plus3it/actions-workflows include:
- `lint.yml` — Runs linters and static analysis checks
- `test.yml` — Runs test scenarios

Releases are created automatically when a PR updating `.bumpversion.cfg` is pushed to the default branch (master or main). The `release.yml` workflow creates a GitHub Release and tag. All workflows use reusable workflows from plus3it/actions-workflows where available.
