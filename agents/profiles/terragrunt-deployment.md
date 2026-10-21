# Terragrunt Deployment Profile

## Safety rules

- Never run `apply`, `destroy`, `import`, or `state` commands, or commands that create or close cloud accounts or projects (for example, `aws organizations create-account`). Prepare them for a person to run.
- These actions move state and need a human-approved migration plan:
  - renaming or moving a unit path;
  - moving `terragrunt-root.hcl` to a different depth;
  - changing the state `key`/`TfstateKey` expression.
- Never edit generated `backend.tf`, `providers.tf`, `versions.tf`, or `.terraform.lock.hcl` in a unit.

## Validation

Use the repository's make targets for validation where they exist (`make help` lists them), for example `make terraform/validate-roots`. Check for a make target before running raw `terraform validate` or `terragrunt validate` on a root.

## CI/CD

CI/CD is a per-deployment choice, documented in each repository's `## Repository-specific` → CI/CD section. If that section is empty or unclear, ask the user. Current setups vary by deployment and may include GitLab CI, Spacelift, or GitHub Actions. These are examples of what individual deployments use, not supported features of tardigrade itself.

## Plan-only operations

All Terraform and Terragrunt operations you perform must be plan-only. Use `plan`, `validate`, or read-only `init -backend=false`. List the apply commands for a person to run in your final report.
