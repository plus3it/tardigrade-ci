# Salt Formula Profile

## Layout

Salt formulas typically have:
- `<formula-name>/` — Main formula directory with states (`init.sls` and others) and `map.jinja`; some formulas have more subdirectories and helper templates
- `_modules/` — Custom Salt execution modules (if present)
- `_states/` — Custom Salt state modules (if present)
- `pillar.example` — Example pillar data showing required and optional keys (some formulas name it `pillar.example.yml`)
- `tests/pillar/<name>/` — Test pillar data (`top.sls` plus the pillar files); some formulas have several test pillars, and some have no test data yet
- `README.md` — Documentation
- Other `README*.md` files or `docs/` — Detailed documentation, for example `README_PillarContents.md` (if present)

## Testing

- `.github/workflows/test.yml` calls the reusable `test-salt-linux.yml` workflow from plus3it/actions-workflows (and `test-salt-windows.yml` for formulas that support Windows; Windows-only formulas call only that one). Each job applies a state with `salt-call --local`, using a test pillar directory such as `tests/pillar/<name>`. Linux jobs run in AlmaLinux containers; Windows jobs run on Windows runners.
- The state names, OS versions, and pillar directories are matrix values in `test.yml`. When you add a state or a test pillar, add it to the matrix too.
- When you add or change states or pillar keys, update the test pillar data in `tests/pillar/` and `pillar.example` to match.
- Some formulas add their own jobs to `test.yml`, such as Kitchen verification or PowerShell linting. Read `test.yml` and mirror the existing jobs.
- `.github/workflows/integration.yml`, when present, runs terrafirm integration tests. It starts on demand (`workflow_dispatch`) or when a pull request review body contains `/build`; a person starts it.

## CI/CD

Pull requests run `lint.yml` and `test.yml`. The `Makefile` includes the tardigrade-ci bootstrap, so `make lint` works. Check the repository's `.github/workflows/` for the exact workflows and their inputs before describing them.

## Releases

Salt formulas are not versioned or released. Do not add a `CHANGELOG.md` entry and do not run `make bumpversion/*`, and skip step 3 of "Before you finish", even when the repository has `.bumpversion.cfg` or `CHANGELOG.md` (they are leftovers).

A merged change reaches watchmaker when watchmaker's Dependabot `gitsubmodule` entry updates the formula's commit SHA there. To see which formulas watchmaker includes, check `.gitmodules` in plus3it/watchmaker. A formula that watchmaker does not include is not versioned or released either.

## Documentation

Salt formulas should document:
- Purpose and security controls applied
- Required and optional pillar keys in `pillar.example`
- Any custom modules or states
- Platform support (OS versions)
