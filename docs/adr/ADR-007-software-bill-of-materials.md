# ADR-007: Software Bill of Materials Generation

## Status

Accepted

## Date

2026-09-25

## Context

The project produces a deployable container artifact containing operating
system packages, the Node.js runtime, application dependencies, and the
application itself.

Vulnerability scanning identifies known security findings but does not by
itself provide a portable inventory of the software components contained in
the artifact.

A Software Bill of Materials (SBOM) is therefore generated from the built
container image.

## Decision

Use Syft to generate an SPDX 2.3 JSON SBOM from the exported container
artifact.

The implementation:

- pins the Syft scanner image by SHA-256 digest
- scans the exported Docker image rather than receiving Docker daemon access
- mounts the image archive read-only
- runs Syft as a non-root user
- drops all Linux capabilities
- enables no-new-privileges
- uses a read-only scanner root filesystem
- provides only an ephemeral writable `/tmp`
- writes the generated SBOM to a dedicated output mount
- validates that the generated file is non-empty
- validates that the result is valid JSON
- validates the SPDX version
- validates that packages and relationships are present
- validates that the application package is represented
- validates that a known application dependency is represented

SPDX 2.3 JSON is the canonical SBOM format for this project.

## Artifact Handling

The SBOM is generated from the actual built container artifact rather than
from the source tree alone.

Normal CI validation does not commit a generated SBOM to the repository.

The generation script supports an explicit output path so a future release
workflow can preserve the SBOM as a release artifact.

This avoids maintaining a static SBOM in source control that could become
stale when the container contents change.

## Initial Baseline

During initial validation on 2026-09-25, Syft 1.52.0 successfully generated
an SPDX 2.3 JSON document from the application container.

The generated document contained the application package and its runtime
dependencies, including Express.

The exact number of packages and relationships is treated as point-in-time
evidence rather than a permanent expectation because dependency and base
image contents may change.

## Alternatives Considered

### Generate the SBOM from the source repository

Rejected as the primary method because the deployable container contains
components inherited from the base image that are not represented by the
application source tree alone.

### Give Syft access to `/var/run/docker.sock`

Rejected because Docker daemon access is unnecessary for SBOM generation.

The image is exported to a Docker archive and passed to Syft read-only.

### Commit the generated SBOM to the repository

Not used for normal CI validation because the file represents a specific
built artifact and may become stale after dependency or base-image changes.

A future release workflow may preserve an SBOM associated with a specific
release artifact.

### Generate multiple SBOM formats

Deferred.

SPDX 2.3 JSON provides the canonical machine-readable format for the current
project. Additional formats can be introduced when an integration or consumer
requires them.

## Consequences

### Positive

- Deployable artifact contents are inventoried
- Operating-system and application components are represented
- The SBOM is generated from the actual container artifact
- Scanner execution does not require Docker daemon access
- SBOM structure and expected application content are automatically validated
- Release workflows can reuse the same generation process

### Trade-offs

- SBOM generation adds build and CI execution time
- Package inventory changes when dependencies or the base image change
- Generated release SBOMs must remain associated with the exact artifact from
  which they were produced
