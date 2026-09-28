# Threat Model

## System

DevSecOps Secure Software Delivery Platform

## Purpose

This threat model identifies security risks across the software delivery
lifecycle implemented by this project.

The model covers:

- source code
- application dependencies
- GitHub pull requests
- GitHub Actions
- container builds
- software supply-chain evidence
- Infrastructure as Code
- dynamic application security testing

## Assets

The primary assets are:

- application source code
- repository history
- dependency manifests and lock files
- CI/CD workflow definitions
- container build definition
- container image
- SBOM
- Sigstore signing evidence
- Terraform configuration
- security scan results
- GitHub workflow identity
- future supply-chain evidence stored in S3

## Trust Boundaries

### Developer workstation → GitHub

Changes originate from a developer environment and are pushed to the GitHub
repository.

Security concerns include:

- accidental secret commits
- malicious or vulnerable code
- unreviewed dependency changes

### GitHub repository → GitHub Actions runner

Repository content is executed inside CI runners.

Security concerns include:

- malicious workflow changes
- excessive workflow permissions
- compromised third-party actions
- dependency or build-script execution

### GitHub Actions → third-party security tools

The pipeline executes security tools and container images.

Security concerns include:

- tool supply-chain compromise
- mutable image tags
- unexpected network access
- excessive container privileges

### Application container → DAST scanner

OWASP ZAP dynamically tests the running application inside an isolated Docker
network.

Security concerns include:

- scanner access beyond the intended target
- target exposure outside the test environment
- runtime vulnerabilities

### Terraform configuration → cloud infrastructure

Terraform describes a minimal S3-based evidence storage design.

The current repository performs static IaC validation but does not automatically
deploy infrastructure.

Security concerns include:

- public bucket exposure
- weak encryption
- uncontrolled object retention
- insecure infrastructure changes

## Threat Analysis

The project uses STRIDE categories as a structured way to evaluate threats.

### Spoofing

Potential threats:

- forged artifact identity
- unauthorized actor impersonating a trusted CI workflow
- misuse of credentials or tokens

Controls:

- GitHub Actions OIDC for keyless signing
- exact workflow identity verification with Cosign
- no long-lived signing key stored in the repository
- no AWS credentials required by current PR validation workflows

Residual considerations:

- repository and GitHub account security remain external trust dependencies

### Tampering

Potential threats:

- unauthorized source-code modification
- dependency manipulation
- workflow modification
- artifact or SBOM modification
- mutable third-party tooling

Controls:

- pull request workflow
- automated security gates
- dependency lock file
- GitHub Actions pinned by commit SHA where configured
- security tool container images pinned by digest
- SBOM signing and verification with Cosign
- Terraform dependency lock file

Residual considerations:

- the container image itself is not currently signed
- branch protection and repository governance remain GitHub-side controls

### Repudiation

Potential threats:

- inability to determine which workflow produced an artifact
- missing evidence of security validation

Controls:

- Git history
- pull requests
- GitHub Actions execution history
- generated SBOM
- Sigstore bundle
- DAST reports
- security scanner output
- ADR documentation

Residual considerations:

- long-term evidence retention is outside the current local validation scope

### Information Disclosure

Potential threats:

- secrets committed to source
- sensitive information exposed through HTTP responses
- public cloud storage
- server implementation information leakage

Controls:

- Gitleaks
- no hard-coded AWS credentials
- Express `X-Powered-By` disabled
- security response headers
- S3 Block Public Access configuration
- BucketOwnerEnforced ownership configuration
- encryption at rest
- DAST validation

Residual considerations:

- the demonstration application intentionally contains no production data

### Denial of Service

Potential threats:

- oversized request bodies
- resource exhaustion
- malicious requests against the application

Controls:

- JSON request size limit
- container resource isolation provided by the execution environment
- application health checks
- isolated DAST execution

Residual considerations:

- production-grade rate limiting and autoscaling are outside the scope of this
  portfolio application

### Elevation of Privilege

Potential threats:

- container privilege escalation
- privileged scanner execution
- excessive GitHub workflow permissions

Controls:

- application runs as a non-root user
- read-only container root filesystem during validation
- Linux capabilities dropped
- `no-new-privileges`
- security scanners use hardened container execution where applicable
- GitHub Actions permissions follow least-privilege configuration
- OIDC permission is limited to the signing job that requires it

Residual considerations:

- the Docker daemon remains a privileged trust boundary on the runner

## Software Supply-Chain Threats

The project treats the software supply chain as a primary security boundary.

Controls include:

- dependency lock files
- npm audit
- Dependabot
- container vulnerability scanning with Trivy
- SBOM generation with Syft
- SBOM signing with Cosign
- verification of the Sigstore identity
- pinned container digests
- pinned GitHub Actions
- restricted package installation behavior in CI

## Application Security Threats

Controls include:

- automated tests
- coverage thresholds
- Semgrep SAST
- OWASP ZAP DAST
- request size limits
- security response headers
- removal of implementation disclosure headers
- production container hardening

## Infrastructure Security Threats

Controls include:

- Terraform
- TFLint
- Checkov
- S3 Block Public Access
- ACL disabling
- versioning
- encryption at rest
- lifecycle controls

The infrastructure is intentionally not automatically deployed by pull request
workflows.

## Accepted Risks and Scope Decisions

The following are intentional scope decisions rather than hidden scanner
exceptions:

- customer-managed KMS encryption is not used for the minimal evidence bucket
- cross-region S3 replication is not configured
- dedicated S3 access logging is not configured
- S3 event notifications are not configured
- the container image is not currently signed
- CodeQL is not used because GitHub code scanning is not enabled for this
  private repository
- production authentication, authorization, rate limiting, and high
  availability are outside the scope of the demonstration API

These decisions should be reevaluated if the project evolves into a real
production service.

## Threat Model Review Triggers

This threat model should be reviewed when:

- a new external service is introduced
- authentication or authorization is added
- application endpoints materially change
- production deployment is introduced
- cloud infrastructure scope increases
- secrets or persistent application data are introduced
- the artifact publishing model changes
