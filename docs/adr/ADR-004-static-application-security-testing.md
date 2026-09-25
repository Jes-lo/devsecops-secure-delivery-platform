# ADR-004: Static Application Security Testing

## Status

Accepted

## Date

2026-09-25

## Context

The secure delivery pipeline requires static analysis capable of detecting
security-relevant source code patterns before changes are merged.

Secret scanning and dependency vulnerability auditing address different
risk classes and do not replace application source code analysis.

## Decision

Use Semgrep Community Edition as an independent SAST security gate.

The initial SAST workflow:

- runs on pull requests targeting `main`
- runs after changes are pushed to `main`
- supports manual execution
- executes checkout on the standard GitHub-hosted runner
- runs Semgrep Community Edition inside a dedicated container
- uses a non-root scanner container
- mounts the repository read-only inside the scanner
- pins the scanner container image by digest
- grants only read access to repository contents
- does not use cloud credentials
- does not require repository secrets
- scans the repository using the Express.js community ruleset
- fails the pipeline when blocking findings are detected

The initial ruleset is intentionally focused on the application's current
Node.js and Express.js technology stack.

Findings must be reviewed individually before suppression.

## Alternatives Considered

### Rely only on dependency scanning

Rejected because dependency scanning identifies vulnerable third-party
components but does not analyze insecure patterns in repository source code.

### Use a broad multi-language ruleset immediately

Deferred because the current application is small and uses Node.js with
Express.

A technology-specific ruleset provides a clearer initial signal and reduces
unnecessary findings from unrelated languages and frameworks.

### Use a mutable scanner image tag

Rejected because a mutable tag could resolve to different scanner contents
without a repository change.

The scanner image is therefore pinned by digest.

### Run the entire GitHub Actions job inside the Semgrep container

Rejected because the non-root scanner user cannot write to GitHub Actions
runner file-command directories mounted under `/__w/_temp`.

Instead, checkout and workflow orchestration run on the GitHub-hosted runner,
while only the SAST scanner executes inside the non-root container.

### Semgrep AppSec Platform

Deferred because the current project can demonstrate SAST using Semgrep
Community Edition without requiring an external account, token, or hosted
project integration.

## Consequences

### Positive

- SAST becomes an independent CI security gate
- No application execution is required for source analysis
- No Semgrep account or repository secret is required
- Scanner execution is reproducible at the container-image level
- The initial rule scope matches the current application stack

### Trade-offs

- Community rules may produce false positives
- Registry-hosted rulesets may evolve independently of this repository
- Community Edition does not provide all capabilities of commercial or
  advanced analysis engines
- Ruleset expansion will require deliberate review as the project grows

Security findings will not be suppressed solely to make CI pass.
