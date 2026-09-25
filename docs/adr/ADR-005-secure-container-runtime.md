# ADR-005: Secure Container Build and Runtime

## Status

Accepted

## Date

2026-09-25

## Context

The secure delivery platform requires a real deployable artifact before
container vulnerability scanning, SBOM generation, and artifact signing can
be introduced.

The application container should minimize unnecessary dependencies and
runtime privileges while remaining reproducible and testable.

## Decision

Package the application as a multi-stage Docker image.

The container implementation:

- uses Node.js 24.21.0 on Debian Bookworm Slim
- pins the Node.js base image by SHA-256 digest
- installs dependencies reproducibly with `npm ci`
- installs production dependencies only
- removes npm, npx, Corepack, and Yarn from the final runtime image
- disables dependency lifecycle scripts during the build
- copies only runtime application files into the final image
- runs as the built-in non-root `node` user
- defines an application healthcheck
- uses exec-form `CMD`
- defines `SIGTERM` as the stop signal

Runtime validation additionally requires:

- a read-only root filesystem
- a temporary writable `/tmp` filesystem
- all Linux capabilities dropped
- `no-new-privileges`
- successful application endpoint checks
- successful Docker healthcheck
- graceful SIGTERM shutdown

The hardened runtime options are enforced during container validation rather
than embedded entirely in the Dockerfile because several controls are runtime
policy decisions.

## Alternatives Considered

### Run the application as root

Rejected because the application does not require root privileges.

### Install development dependencies in the runtime image

Rejected because test tooling is unnecessary in the deployable artifact and
would increase image size and attack surface.

### Use a mutable base-image tag only

Rejected because the resolved base image could change without a repository
change.

The base image is pinned by digest while retaining the human-readable Node.js
version and distribution tag.

### Install curl for the healthcheck

Rejected because Node.js can perform the health request directly, avoiding an
additional runtime package.

### Use a writable root filesystem

Not required by the current application.

Validation therefore proves that the service operates correctly with a
read-only root filesystem and a limited writable temporary filesystem.

## Consequences

### Positive

- Non-root application execution
- Reproducible base-image identity
- Reduced runtime dependency surface
- Production-only Node.js dependencies
- Runtime compatible with capability dropping
- Runtime compatible with read-only root filesystems
- Automated container health and shutdown validation

### Trade-offs

- Base-image digest upgrades require deliberate repository changes
- Runtime policies must also be configured by the eventual deployment platform
- Read-only execution may require explicit writable mounts if future features
  need persistent or temporary filesystem writes

Container security requirements will be validated automatically before merge.
