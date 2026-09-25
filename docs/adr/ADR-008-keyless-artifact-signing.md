# ADR-008: Keyless Supply-Chain Artifact Signing

## Status

Accepted

## Date

2026-09-25

## Context

The project generates an SPDX Software Bill of Materials from the deployable
container artifact.

The SBOM provides an inventory of the artifact contents, but an unsigned SBOM
does not provide cryptographic evidence of the workflow identity that produced
or approved it.

A signing mechanism is therefore required.

## Decision

Use Cosign identity-based keyless signing with GitHub Actions OIDC.

The implementation:

- pins the Cosign container image by SHA-256 digest
- verifies the pinned Cosign image against the Sigstore release identity
- does not create or store a long-lived private signing key
- obtains a short-lived signing identity through GitHub Actions OIDC
- signs the generated SPDX SBOM using `cosign sign-blob`
- stores signing evidence in a Sigstore bundle
- verifies the bundle against an exact expected GitHub workflow identity
- verifies the GitHub Actions OIDC issuer
- runs Cosign as a non-root user
- drops all Linux capabilities
- enables no-new-privileges
- uses a read-only scanner filesystem
- provides only ephemeral writable temporary storage

## Signing Scope

Keyless signing is performed only for trusted `main` executions.

Pull request artifacts are not treated as trusted release artifacts and are
not signed with the trusted main-branch workflow identity.

## Signed Artifact

The current implementation signs the generated SPDX 2.3 JSON SBOM.

The SBOM itself is generated from the built container artifact.

The project does not currently publish the application container to an OCI
registry.

Because normal Cosign container-image signing is registry-oriented, OCI image
signing is deferred until a registry-backed release workflow is introduced.

The project must not claim that the container image itself is signed until
that registry-backed signing control exists.

## Identity Verification

Verification requires both:

- the exact GitHub Actions workflow identity
- the GitHub Actions OIDC issuer

Broad identity regular expressions are not used.

## Key Management

No repository signing private key is generated.

No long-lived private signing key is stored in GitHub Secrets.

Signing credentials are short-lived and derived from the GitHub Actions OIDC
identity for the execution.

## Alternatives Considered

### Long-lived Cosign key pair

Rejected for the current implementation.

A long-lived private key would introduce a secret that requires storage,
rotation, access control, and incident-response procedures.

### Sign pull request artifacts

Rejected.

A pull request represents proposed code rather than the trusted main branch.
Signing it with the trusted release identity would weaken the meaning of the
signature.

### Sign the OCI container image immediately

Deferred.

The project does not currently publish the image to an OCI registry. Image
signing will be added when a registry-backed release artifact exists.

### Disable certificate identity restrictions

Rejected.

Verification must establish both cryptographic validity and the expected
signer identity.

## Consequences

### Positive

- No persistent signing private key is required
- Signing identity is bound to GitHub Actions
- SBOM integrity can be cryptographically verified
- Signer identity is verified explicitly
- Sigstore bundles provide portable verification evidence
- The signing process can later be extended to OCI image signing

### Trade-offs

- Signing depends on GitHub OIDC and Sigstore services
- Signing metadata is associated with Sigstore transparency infrastructure
- The current signature protects the SBOM, not the OCI image itself
- OCI image signing requires a later registry-backed release workflow
