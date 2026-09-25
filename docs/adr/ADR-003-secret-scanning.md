# ADR-003: Secret Scanning

## Status

Accepted

## Date

2026-09-25

## Context

Credentials and secrets committed to source control can remain exposed in
Git history even after they are removed from the current version of a file.

The delivery pipeline therefore requires an automated control that detects
potential secrets before changes are merged.

## Decision

Use Gitleaks as an independent CI security gate.

The secret-scanning workflow:

- runs on pull requests targeting `main`
- runs after changes are pushed to `main`
- supports manual execution
- checks out full Git history
- does not persist checkout credentials
- grants read access to repository contents
- grants read access to pull request metadata required for PR scanning
- disables automated PR comments to avoid write permissions
- pins the Gitleaks GitHub Action to a full commit SHA
- treats detected secrets as pipeline failures

Secret findings will be reviewed individually.

Real credentials must never be added intentionally for testing.

## Alternatives Considered

### Rely only on `.gitignore`

Rejected because `.gitignore` does not protect secrets already committed
to Git history and cannot identify credentials embedded in tracked files.

### Manual secret review

Rejected as the primary control because manual review is inconsistent and
does not provide an automated merge gate.

### Custom secret patterns only

Deferred. Gitleaks' maintained rule set provides a useful baseline.
Repository-specific rules may be added later if justified by real project
requirements.

## Consequences

### Positive

- Automated detection of common secret patterns
- Historical commits can be inspected
- Secret scanning becomes an independent CI result
- No cloud credentials are required

### Trade-offs

- False positives are possible
- Full-history checkout increases scan scope and execution time
- Future suppressions require documented review and justification

Suppressions must not be added solely to make the pipeline pass.
