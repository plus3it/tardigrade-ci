# Salt Formula Profile

## Layout

Salt formulas typically have:
- `<formula-name>/` — Main formula directory with states, maps, and defaults
- `_modules/` — Custom Salt execution modules (if present)
- `_states/` — Custom Salt state modules (if present)
- `pillar.example` — Example pillar data showing required and optional keys
- `tests/` — Test pillar data and configurations
- `README.md` — Documentation
- `README_PillarContents.md` or similar — Detailed pillar documentation (if present)

## Testing

- `.github/workflows/test.yml` calls the reusable `test-salt-linux.yml` workflow from plus3it/actions-workflows (and `test-salt-windows.yml` for formulas that support Windows). It applies the formula with `salt-call --local` in containers, using the test pillar data in `tests/pillar/`.
- When you add or change states or pillar keys, update the test pillar data in `tests/pillar/` and `pillar.example` to match.
- `.github/workflows/integration.yml`, when present, runs integration tests on demand (`workflow_dispatch`); a person starts it.

## CI/CD

Pull requests run `lint.yml` and `test.yml`. Check the repository's `.github/workflows/` for the exact workflows and their inputs before describing them.

## Documentation

Salt formulas should document:
- Purpose and security controls applied
- Required and optional pillar keys in `pillar.example`
- Any custom modules or states
- Platform support (OS versions)
