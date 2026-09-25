# ADR-001: Application and Test Foundation

## Status

Accepted

## Date

2026-09-25

## Context

The primary purpose of this project is to demonstrate a secure software
delivery lifecycle rather than to build a feature-rich application.

The project still requires a realistic application artifact so that CI,
security scanning, container analysis, software composition analysis,
SBOM generation, signing, and release controls can operate against
actual source code and dependencies.

Adding a large application or a large testing framework at this stage
would increase the dependency and maintenance surface without improving
the primary DevSecOps objective.

## Decision

Use a deliberately small Node.js HTTP API as the workload for the secure
delivery pipeline.

The application uses:

- Node.js 24 LTS pinned through `.nvmrc`
- npm with a committed lockfile
- CommonJS modules
- Express for HTTP routing
- the native Node.js test runner
- Supertest for HTTP endpoint testing
- native Node.js test coverage
- explicit coverage thresholds

Application logic and configuration are separated from the process
entrypoint so they can be tested without starting a network listener.

The thin `src/server.js` process entrypoint is excluded from unit-test
coverage and is validated separately with a runtime smoke test.

## Alternatives Considered

### Larger demonstration application

Rejected because application complexity is not the primary objective of
this repository and would add unnecessary code and dependencies.

### Jest or another full testing framework

Deferred because the native Node.js test runner currently provides the
capabilities required by this project with a smaller third-party
dependency surface.

### Third-party coverage framework

Deferred because Node.js provides native test coverage and configurable
coverage thresholds.

## Consequences

### Positive

- Small and understandable application surface
- Fewer third-party dependencies
- Reproducible Node.js environment
- Automated endpoint and configuration tests
- Coverage thresholds can act as CI quality gates
- Runtime bootstrap behavior can be validated independently

### Trade-offs

- Native Node.js test coverage remains experimental in Node.js 24
- The minimal application does not represent a production business system
- Process startup and signal handling are validated through smoke testing
  rather than unit-test coverage

These trade-offs are accepted because the repository is focused on
DevSecOps delivery controls rather than application feature complexity.
