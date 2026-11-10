# Terraform Module Profile

## Layout

Root module files:
- `main.tf` — Module resources, data sources, and locals. Move data sources to `data.tf` or locals to `locals.tf` only when `main.tf` grows large; both are optional. Modules do not configure providers, so there is no `providers.tf`
- `variables.tf` — Input variables
- `outputs.tf` — Output values
- `versions.tf` — The `terraform` block with `required_version` and `required_providers`. Declare these only here, never in `main.tf`. If they are declared elsewhere, or `versions.tf` is missing, move or create them here. Set a `>=` floor for each, with no upper cap; the floor is the lowest version that supports the features the module uses. Find a provider floor by checking the provider docs at tagged versions for the argument you use. `optional()` with defaults needs Terraform 1.3 and write-only arguments need 1.11. If you can't verify a floor, say so in your report
- `migrations.tf` — All `moved` blocks, so users can upgrade the module without destroying and recreating resources. Keep them only here. If you find `moved` blocks in another file, move them to `migrations.tf`
- `modules/<name>/` — Submodules (if present), each with its own `versions.tf`; `make docs/generate` also updates their READMEs

Test scenarios in `tests/<scenario>/`:
- Each test scenario directory contains `main.tf` that uses the module
- If a test requires prerequisite resources, those Terraform files go in a `prereq/` subdirectory within the test scenario
- Some modules also have Python tests, Lambda source, and requirements files. Follow the existing pattern.
- Do not add `.tftest.hcl` tests; these modules don't use them.

## Inputs

Each module has one subject, such as a budget or an AWS Config recorder, and creates one of it. Callers use `for_each` on the module to create several. Public Terraform style guides prefer many flat variables; this section takes precedence over them.

1. **One variable.** A new module takes a single input variable: an `object` with `optional()` attributes, named for the subject (`budget`, `config`, `vpc_ipam`). Callers build the object, `merge` in their own defaults, and pass it. The one exception is secrets (item 8). Existing modules that already do this keep doing it. Don't convert a multi-variable module unless asked, because it is a breaking change.
2. **Cross-cutting inputs, like `tags`, `region` and `create`, are attributes of the object**, never separate variables.
3. **Attributes.** A required attribute has a plain type. An optional attribute is `optional(type)`, where `null` means unset, or `optional(type, default)` for a real default. Give nested objects, lists and maps a `{}` or `[]` default so the module never reads an attribute of `null`. The module body reads `var.<name>.<attribute>` and never sets its own defaults.
4. **Types.** Don't use `any`, `map(any)` or `list(any)`. The one exception is `optional(any)` that passes through to another module or resource whose attributes are documented; say so in the README and link to where they are documented.
5. **Variable block order:** `description`, `type`, `default`, `nullable`, `sensitive`, then any `validation` blocks. The `description` is one line ("Object of inputs for X").
6. **Validation** only for constraints the provider doesn't catch at plan time. Set `nullable = false` when `null` must not replace a default.
7. **Multiples.** If an input takes several items, give it a plural name. Use a map keyed by a stable name, or a list of objects that each have a `name`, and key `for_each` on it: `{ for item in var.items : item.name => item }`. Never address items by list position.
8. **Secrets.** Put secret values in a second input variable, `<subject>_secrets`, with `sensitive = true`, so the main object stays readable in plan output. Make it an object with `optional()` attributes like the main one. Pass its attributes to the resource's write-only arguments (the provider docs mark them; the AWS provider names them `*_wo`), so they stay out of plan and state. If the resource has a `*_wo_version` argument, add it to the same object; callers increment it to send a changed secret. Write-only arguments need `required_version >= 1.11` and a provider version that has them. `sensitive = true` only hides the value in plan output; without a write-only argument the secret is stored in state, so say so in the README.

Caller pattern, to show in READMEs:

```hcl
locals {
  budget_defaults = { time_unit = "MONTHLY" }
}

module "budget" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-budget.git?ref=1.0.0"

  budget = merge(local.budget_defaults, { name = "team-a", limit_amount = "100" })
}
```

## Resources and outputs

- Use `for_each` with stable, plan-time-known keys for multiple resources. Don't derive keys from another resource's computed attributes. Use `count` only to create a resource conditionally, as `count = var.<name>.<attribute> == null ? 0 : 1`.
- Create optional nested blocks with `dynamic` and `for_each = x != null ? [x] : []`.
- Name a resource `this` when the module creates it once. Give any other resource a descriptive name without the resource type. Names are lowercase with underscores.
- In a resource, put `count` or `for_each` first, then a blank line, then arguments, nested blocks, `depends_on`, and `lifecycle` last.
- Don't use `ignore_changes = all`, and don't hard-code account IDs or ARNs.
- A `module` block for a remote module uses the full `git::https://` source with a `ref` that pins a release tag, for example `source = "git::https://github.com/plus3it/terraform-aws-tardigrade-config.git?ref=4.2.1"`. Don't use registry sources or the `github.com/...` shorthand: the full form is the easiest to override with git `insteadOf` configs. Submodules in the same repository use a relative path (`./modules/<name>`).
- Add or change outputs only when the task calls for it. Every output has a `description`. Output each resource as a whole object, one output per resource, named for it (`bucket`, `detector`), so callers pick the attributes they need. For `for_each` resources the value is the keyed map. For a conditional resource, use `one(aws_x.this[*])`. Set `sensitive = true` on an output whose object contains secret values.

## Interface changes

When adding or changing a variable, output or required version:
1. Update the README documentation by running `make docs/generate`. This regenerates the content between `<!-- BEGIN TFDOCS -->` and `<!-- END TFDOCS -->` markers. Do not edit the generated tables manually.
2. If the change renames or moves a resource address (for example, adding `count` or `for_each`), add a `moved` block to `migrations.tf` (create it if absent; never put `moved` blocks in other files) so existing users do not destroy and recreate resources. When switching from `count` to `for_each`, add one `moved` block for each old index to its new key. Check the plan shows moves, not replacements.
3. For new or changed inputs, add a test scenario under `tests/` that exercises them. Keep one scenario that passes only the required attributes, so the optional defaults are exercised.
4. Add an entry to `CHANGELOG.md` following [Keep a Changelog](http://keepachangelog.com/) format, linking the pull request that implements the change.
5. Commit your changes, including the CHANGELOG.md entry.
6. Run the appropriate semantic version bump, which creates its own commit:
    - `make bumpversion/patch` — Bug fixes (1.2.3 → 1.2.4)
    - `make bumpversion/minor` — New features, backward-compatible (1.2.3 → 1.3.0)
    - `make bumpversion/major` — Breaking changes (1.2.3 → 2.0.0): removing or renaming a variable, attribute or output; changing a type; making an optional attribute required; changing a default; changing an output's shape; adding a required provider configuration (`configuration_aliases`); or any change that makes existing callers plan a replacement or destroy. Adding an optional attribute or an output, without changing existing behavior, is minor
7. Both commits go in the same pull request, and its description includes a comparison link to the last release.

## Testing

Tests run in Docker using mockstack. CI uses the plus3it/actions-workflows `test.yml` workflow, which runs:

```bash
make mockstack/up       # Start the mock AWS stack
make mockstack/pytest   # Run tests
make mockstack/clean    # Clean up
```

Run exactly these three commands (Docker is required). The mock stack uses a fixed container name and network, so never run two at once, including from parallel worktrees. The exception is a module whose `.github/workflows/test.yml` sets `mockstacktest-enable: false`. That module doesn't use the mock stack, so follow Repository-specific → Testing. (The same setting in `release.yml` is normal.)

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
