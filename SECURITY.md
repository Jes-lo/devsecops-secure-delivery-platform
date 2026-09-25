# Security Policy

## Scope

This repository is a portfolio and demonstration environment for secure software delivery practices.

## Secrets

The repository must not contain:

- passwords
- API tokens
- cloud access keys
- private SSH keys
- private certificates
- production credentials
- real customer data
- employer confidential information

Local secrets must be provided through ignored environment files or ephemeral CI mechanisms.

## Security Findings

Security findings produced by automated tooling are reviewed individually.

Suppressions or exceptions must include a documented technical justification.

## Reporting

If a credential or sensitive value is accidentally exposed, it should be revoked or rotated before repository cleanup is considered sufficient.
