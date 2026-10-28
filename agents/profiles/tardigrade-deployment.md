# Tardigrade Deployment Profile

## Safety rules

- Never run `apply`, `destroy`, `import`, or `state` commands, or commands that create or close cloud accounts or projects (for example, `aws organizations create-account`). Prepare them for a person to run.
- These actions move state and need a human-approved migration plan:
  - renaming or moving a unit path;
  - moving `terragrunt-root.hcl` to a different depth;
  - changing the state `key`/`TfstateKey` expression.
- Never edit generated `backend.tf`, `providers.tf`, `versions.tf`, or `.terraform.lock.hcl` in a unit.

## Procedures

A deployment can pin the version of the tardigrade template whose layout it matches, with a `uses: plus3it/tardigrade@<tag>` line in `.github/workflows/dependabot_hack.yml` (a deployment that hosts the template elsewhere writes that host's project path instead of `plus3it/tardigrade`). When it does, `make agents/sync` also writes the template's procedures to `.agents/plus3it/tardigrade/`. Read the matching file before changing that part of the repository:

- `stacks.md`: add a stack (a new scope, such as an account) or a unit (a root deployed to a region), input precedence, and the safety rules for stacks
- `roots.md`: add a root, its template, and its dependency globs
- `modules.md`: add a local module, or use an external one
- `vendor.md`: vendor external modules, public or private
- `templates.md`: the conventions for the starter templates used to onboard a stack

If `.agents/plus3it/tardigrade/` doesn't exist, the deployment has no pin, and only the general rules in this file apply.

## Validation

Use the repository's make targets for validation where they exist (`make help` lists them), for example `make terraform/validate-roots`. Check for a make target before running raw `terraform validate` or `terragrunt validate` on a root.

## CI/CD

CI/CD is a per-deployment choice, documented in each repository's `## Repository-specific` → CI/CD section. If that section is empty or unclear, ask the user. Current setups vary by deployment and may include GitLab CI, Spacelift, or GitHub Actions. These are examples of what individual deployments use, not supported features of tardigrade itself.

## Plan-only operations

All Terraform and Terragrunt operations you perform must be plan-only. Use `plan`, `validate`, or read-only `init -backend=false`. List the apply commands for a person to run in your final report.
