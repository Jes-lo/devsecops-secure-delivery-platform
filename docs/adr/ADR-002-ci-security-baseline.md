# ADR-002: CI Security Baseline

## Status

Accepted

## Date

2026-09-25

## Context

The project requires a CI foundation before additional DevSecOps security
controls are introduced.

The workflow should validate application behavior while minimizing CI
permissions, credential exposure, dependency installation risk, and
unnecessary supply-chain trust.

## Decision

GitHub Actions is used as the CI platform.

The initial CI workflow:

- runs for pull requests targeting `main`
- runs after changes are pushed to `main`
- supports manual execution
- uses an explicitly pinned Ubuntu runner version
- uses the Node.js version defined by `.nvmrc`
- installs dependencies reproducibly with `npm ci`
- disables dependency lifecycle scripts during installation
- executes the project's existing test, coverage, audit, and smoke gates
- grants the GitHub token read-only repository content access
- does not persist checkout credentials
- does not use cloud credentials
- does not use repository secrets
- does not enable dependency caching initially
- pins GitHub Actions dependencies to full commit SHAs

## Alternatives Considered

### Mutable major-version action references

References such as `actions/checkout@v7` are easier to maintain but allow
the resolved action implementation to change without a repository change.

Full commit SHA pinning was selected to make the executed action version
explicit and reviewable.

### npm dependency caching

Caching can improve workflow performance, but the repository is currently
small and dependency installation is fast.

Caching is deferred so that the initial CI trust model remains simple.

### Running dependency lifecycle scripts

Some ecosystems require installation scripts.

The current application dependencies do not require them for the validated
workflow, so `npm ci --ignore-scripts` is used to reduce installation-time
execution risk.

### Cloud-backed CI integration

Deferred because the current CI validation does not require cloud resources
or credentials.

## Consequences

### Positive

- Reproducible dependency installation
- Minimal GitHub token permissions
- No cloud credential exposure
- Reduced dependency installation execution surface
- Reviewable GitHub Actions dependencies
- Local and CI validation use the same `npm run verify` command

### Trade-offs

- Disabling dependency scripts may require review if future dependencies
  legitimately need installation-time scripts
- SHA-pinned actions require deliberate maintenance when upgrading
- Disabling caching increases installation time slightly
- CI validation is intentionally limited to the application foundation at
  this stage

These trade-offs are accepted as part of the project's initial secure CI
baseline.
