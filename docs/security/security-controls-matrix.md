# Security Controls Matrix

| Security Concern | Control | Tool / Implementation | Enforcement / Evidence |
|---|---|---|---|
| Application correctness | Automated tests | Node.js test runner | CI Application validation |
| Regression risk | Coverage thresholds | Node.js test coverage | CI Application validation |
| Dependency vulnerabilities | Dependency audit | npm audit | CI Application validation |
| Secret exposure | Secret scanning | Gitleaks | Secret Scanning gate |
| Static code vulnerabilities | SAST | Semgrep | SAST gate |
| Dependency maintenance | Automated update discovery | GitHub Dependabot | Dependabot pull requests |
| Known dependency vulnerabilities | Vulnerability alerts | GitHub Dependabot | Repository security alerts |
| Container build integrity | Reproducible base image | Digest-pinned Node image | Dockerfile |
| Container privilege escalation | Non-root runtime | USER node | Container validation |
| Container filesystem modification | Read-only runtime | Docker runtime controls | Container validation |
| Linux privilege escalation | Drop capabilities | `--cap-drop=ALL` | Container validation / DAST |
| Process privilege escalation | No new privileges | `no-new-privileges` | Container validation / DAST |
| Container vulnerabilities | Image vulnerability scan | Trivy | Container Vulnerability Scanning gate |
| Software inventory | SBOM | Syft / SPDX | SBOM gate |
| SBOM tampering | Keyless signing | Cosign / Sigstore | Artifact Signing workflow |
| Signing identity spoofing | Identity verification | Cosign identity + issuer checks | Artifact Signing workflow |
| IaC syntax / validity | Terraform validation | Terraform | IaC Security gate |
| IaC quality | IaC linting | TFLint | IaC Security gate |
| Cloud misconfiguration | IaC security scanning | Checkov | IaC Security gate |
| S3 public exposure | Block Public Access | Terraform | Checkov + IaC configuration |
| S3 ACL exposure | BucketOwnerEnforced | Terraform | Checkov + IaC configuration |
| Data at rest | S3 encryption | SSE-S3 AES256 | Checkov + IaC configuration |
| Object recovery | S3 versioning | Terraform | Checkov + IaC configuration |
| Storage growth | Lifecycle controls | Terraform | Checkov + IaC configuration |
| Runtime web vulnerabilities | DAST | OWASP ZAP API Scan | DAST gate |
| MIME sniffing | HTTP security header | X-Content-Type-Options | Tests + DAST |
| Cross-origin resource exposure | HTTP security header | Cross-Origin-Resource-Policy | Tests + DAST |
| Framework disclosure | Disable Express header | X-Powered-By disabled | Tests + DAST |
| Excessive request body | Request limit | Express JSON 32 KB limit | Application configuration |
| CI privilege exposure | Least privilege permissions | GitHub Actions permissions | Workflow configuration |
| Third-party action tampering | Immutable action references | Commit-SHA pinning | Workflow configuration |
| Scanner image tampering | Immutable container references | SHA256 digest pinning | Security scripts |
| DAST network exposure | Isolated test network | Internal Docker network | DAST script |
| DAST target host exposure | No published application port | Docker network-only access | DAST script |
| Security decision traceability | Architecture Decision Records | ADR-001 through ADR-011 | Repository documentation |
