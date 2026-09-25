# DevSecOps Secure Software Delivery Platform

A greenfield portfolio implementation of a secure software delivery pipeline focused on automated testing, software supply chain security, infrastructure validation, vulnerability scanning, and release integrity.

## Project Goals

This project demonstrates a practical DevSecOps software delivery lifecycle using:

- GitHub Actions
- Node.js
- Automated testing and coverage
- Gitleaks
- Semgrep
- CodeQL
- Docker
- Trivy
- Terraform
- TFLint
- Checkov
- Syft
- Cosign

## Current Status

Application and test foundation complete. CI and security pipeline implementation in progress.

## Engineering Principles

- Security controls are automated where practical.
- CI runs without long-lived cloud credentials.
- Secrets must not be committed to the repository.
- Security findings are reviewed rather than blindly suppressed.
- Infrastructure and application security are validated separately.
- Third-party software remains subject to its respective licenses.
- Repository-specific implementation and documentation are created for this portfolio project.
