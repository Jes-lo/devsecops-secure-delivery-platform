# ADR-011: Dependency Security Automation

## Status

Accepted

## Date

2026-09-28

## Context

The project depends on components from multiple software supply-chain
ecosystems.

These include:

- npm packages
- Docker base images
- GitHub Actions
- Terraform providers

Existing security controls can identify vulnerable components, but dependency
maintenance should also be continuous rather than relying only on manual
checks.

## Decision

Use GitHub Dependabot to monitor supported dependencies and propose updates
through pull requests.

Dependabot version updates are configured for:

- npm
- Docker
- GitHub Actions
- Terraform

Checks run weekly.

Dependabot vulnerability alerts and security updates are also enabled.

## Security Model

Dependabot is not allowed to bypass the existing software delivery controls.

A dependency update remains subject to the same validation pipeline as other
changes, including applicable:

- application tests and coverage
- dependency audit
- secret scanning
- static application security testing
- container runtime validation
- container vulnerability scanning
- SBOM generation
- artifact trust validation
- Infrastructure as Code validation
- Dynamic Application Security Testing

Dependency discovery is automated.

Dependency acceptance is not.

## Update Strategy

Automatic merge is intentionally not enabled.

Each update is evaluated through the existing pull request workflow before it
can be merged.

Major updates may require additional compatibility or security review.

## Consequences

### Positive

- dependency maintenance becomes continuous
- vulnerable dependencies can trigger remediation workflows
- multiple supply-chain ecosystems are monitored
- dependency changes are validated through the existing DevSecOps pipeline
- update discovery does not bypass human review

### Trade-offs

- automated monitoring can create additional pull requests
- some updates may require manual compatibility work
- security tooling does not eliminate the need to review dependency changes
