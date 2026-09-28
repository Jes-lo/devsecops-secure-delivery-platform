# ADR-009: Infrastructure as Code Security Validation

## Status

Accepted

## Date

2026-09-28

## Context

The project includes a minimal AWS infrastructure definition used to support
software supply-chain evidence.

Infrastructure as Code introduces its own classes of quality, security, and
configuration risks that are not fully covered by application SAST or
container vulnerability scanning.

The Terraform configuration therefore requires dedicated validation before
changes can be merged.

## Decision

Use a layered IaC validation process consisting of:

- Terraform formatting validation
- Terraform initialization without a remote backend
- Terraform configuration validation
- TFLint with the Terraform and AWS rulesets
- Checkov security policy scanning

The same validation logic is implemented in `scripts/iac-validate.sh` and
executed locally and in GitHub Actions.

## Infrastructure Scope

The infrastructure is intentionally small.

It consists of a private Amazon S3 bucket used for supply-chain evidence and
the controls required to secure and manage that bucket.

The configuration includes:

- S3 bucket
- S3 Block Public Access
- BucketOwnerEnforced ownership controls
- versioning
- SSE-S3 encryption
- lifecycle configuration

No compute, NAT Gateway, load balancer, database, or customer-managed KMS key
is required for this infrastructure.

## Security Decisions

The bucket:

- blocks public ACLs
- blocks public policies
- ignores public ACLs
- restricts public buckets
- disables ACL-based ownership
- enables versioning
- enables encryption at rest
- expires noncurrent object versions
- aborts incomplete multipart uploads

## Checkov Policy

Security scanner findings are not suppressed globally.

Exceptions are declared on the specific S3 resource with justification.

The following controls are intentionally not implemented in the current
non-production portfolio environment:

- customer-managed KMS encryption
- cross-region replication
- dedicated S3 access logging
- event notifications

These controls were evaluated but would introduce additional infrastructure,
operational complexity, or cost without supporting the current purpose of the
minimal evidence bucket.

The existing SSE-S3 configuration still provides encryption at rest.

## CI Enforcement

GitHub Actions runs the IaC validation process for pull requests and pushes to
`main`.

The CI job:

- uses read-only repository permissions
- pins GitHub Actions by commit SHA
- pins Terraform and TFLint versions
- uses the digest-pinned Checkov container defined by the validation script
- requires all non-suppressed Checkov controls to pass

No AWS credentials are required for this validation gate.

The workflow does not execute `terraform plan` or `terraform apply`.

## Consequences

### Positive

- IaC quality and security checks are enforced before merge
- local and CI validation use the same script
- no AWS credentials are exposed to pull request validation
- infrastructure remains deliberately small
- accepted risks are explicit and reviewable

### Trade-offs

- four Checkov policies are accepted for the current environment
- stronger production controls would require additional infrastructure
- deployment and runtime verification are separate controls
