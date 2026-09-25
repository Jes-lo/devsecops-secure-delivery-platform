#!/usr/bin/env bash

set -euo pipefail

COSIGN_IMAGE="ghcr.io/sigstore/cosign/cosign@sha256:9e5c2f2edc34351160407ca3416c61855bdf9403c3c5936e0f0be7fc261611b8"

SBOM_FILE="${1:-}"
BUNDLE_FILE="${2:-}"
EXPECTED_IDENTITY="${3:-}"

OIDC_ISSUER="https://token.actions.githubusercontent.com"

if [[ -z "${SBOM_FILE}" ]]; then
  echo "Usage: $0 <sbom-file> <bundle-file> <expected-identity>"
  exit 1
fi

if [[ -z "${BUNDLE_FILE}" ]]; then
  echo "Bundle file is required"
  exit 1
fi

if [[ -z "${EXPECTED_IDENTITY}" ]]; then
  echo "Expected certificate identity is required"
  exit 1
fi

if [[ ! -s "${SBOM_FILE}" ]]; then
  echo "SBOM file is missing or empty: ${SBOM_FILE}"
  exit 1
fi

if [[ -z "${ACTIONS_ID_TOKEN_REQUEST_URL:-}" ]] ||
   [[ -z "${ACTIONS_ID_TOKEN_REQUEST_TOKEN:-}" ]]; then
  echo "GitHub Actions OIDC environment is unavailable"
  exit 1
fi

ARTIFACT_DIR="$(
  cd "$(dirname "${SBOM_FILE}")"
  pwd
)"

SBOM_BASENAME="$(basename "${SBOM_FILE}")"
BUNDLE_BASENAME="$(basename "${BUNDLE_FILE}")"

run_cosign_rw() {
  docker run --rm \
    --user "$(id -u):$(id -g)" \
    --cap-drop=ALL \
    --security-opt=no-new-privileges:true \
    --read-only \
    --tmpfs /tmp:rw,nosuid,nodev,size=256m,mode=1777 \
    --env HOME=/tmp/cosign-home \
    --env TMPDIR=/tmp \
    --env ACTIONS_ID_TOKEN_REQUEST_URL \
    --env ACTIONS_ID_TOKEN_REQUEST_TOKEN \
    --volume "${ARTIFACT_DIR}:/artifacts:rw" \
    "${COSIGN_IMAGE}" \
    "$@"
}

run_cosign_ro() {
  docker run --rm \
    --user "$(id -u):$(id -g)" \
    --cap-drop=ALL \
    --security-opt=no-new-privileges:true \
    --read-only \
    --tmpfs /tmp:rw,nosuid,nodev,size=256m,mode=1777 \
    --env HOME=/tmp/cosign-home \
    --env TMPDIR=/tmp \
    --volume "${ARTIFACT_DIR}:/artifacts:ro" \
    "${COSIGN_IMAGE}" \
    "$@"
}

echo "==> Signing SBOM with GitHub Actions OIDC identity"

run_cosign_rw \
  sign-blob \
  "/artifacts/${SBOM_BASENAME}" \
  --bundle "/artifacts/${BUNDLE_BASENAME}" \
  --yes

test -s "${BUNDLE_FILE}" || {
  echo "Signature bundle is missing or empty"
  exit 1
}

echo
echo "==> Verifying signed SBOM"

run_cosign_ro \
  verify-blob \
  "/artifacts/${SBOM_BASENAME}" \
  --bundle "/artifacts/${BUNDLE_BASENAME}" \
  --certificate-identity "${EXPECTED_IDENTITY}" \
  --certificate-oidc-issuer "${OIDC_ISSUER}"

echo
echo "SBOM keyless signature verification passed."
