# ADR-010: Dynamic Application Security Testing

## Status

Accepted

## Date

2026-09-28

## Context

Static analysis, dependency scanning, container scanning, and Infrastructure
as Code scanning do not test the behavior of the running application.

The project therefore requires a dynamic security control that evaluates the
application over HTTP while it is running.

## Decision

Use OWASP ZAP API Scan as the Dynamic Application Security Testing control.

The API surface is described through the project's OpenAPI specification.

During DAST validation:

1. The application container is built.
2. An isolated internal Docker network is created.
3. The application starts as a hardened container.
4. The application must become healthy before scanning.
5. OWASP ZAP imports the OpenAPI specification.
6. ZAP performs passive and active API security testing.
7. The scan must complete with zero failures and zero warnings.
8. HTML, JSON, Markdown, and log evidence can be retained by CI.

## Security Isolation

The target application:

- runs with a read-only root filesystem
- uses a temporary filesystem for `/tmp`
- drops all Linux capabilities
- enables `no-new-privileges`
- is not published to a host port

The DAST environment uses an internal Docker network.

The ZAP container is also executed with:

- all Linux capabilities dropped
- `no-new-privileges`
- a digest-pinned container image

The ZAP automatic add-on update path is disabled during scanning to improve
repeatability and avoid runtime dependency changes.

## Findings

The first dynamic scan identified two missing response headers:

- `X-Content-Type-Options`
- `Cross-Origin-Resource-Policy`

The application was updated to return:

- `X-Content-Type-Options: nosniff`
- `Cross-Origin-Resource-Policy: same-origin`

Automated application tests were added for these controls.

After remediation, the DAST scan completed with:

- zero failures
- zero warnings

## Consequences

### Positive

- the running application is tested, not only its source code
- DAST findings resulted in application security improvements
- scans are reproducible locally and in CI
- the application is not exposed to the public Internet during testing
- scanner execution is isolated from the host network
- security reports can be retained as pipeline evidence

### Trade-offs

- DAST increases pipeline execution time
- OpenAPI must remain synchronized with the API
- additional authenticated testing would be required if protected endpoints
  are introduced in the future
