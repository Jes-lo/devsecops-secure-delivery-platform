#!/usr/bin/env bash

set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-secure-delivery-api:trivy-scan}"

TRIVY_IMAGE="aquasec/trivy@sha256:62b1e65e8869bc4b4c6aa4fa2b21595256c7c2f6018a9d9ad61caf87187c1969"

SCAN_DIR="$(mktemp -d)"
TRIVY_CACHE_HOST="$(mktemp -d)"
TRIVY_TMP_HOST="$(mktemp -d)"

cleanup() {
  rm -rf \
    "${SCAN_DIR}" \
    "${TRIVY_CACHE_HOST}" \
    "${TRIVY_TMP_HOST}"
}

trap cleanup EXIT

echo "==> Building application image"

docker build \
  --tag "${IMAGE_NAME}" \
  .

echo
echo "==> Exporting image for isolated scanning"

docker save \
  --output "${SCAN_DIR}/secure-delivery-api.tar" \
  "${IMAGE_NAME}"

run_trivy() {
  docker run --rm \
    --user "$(id -u):$(id -g)" \
    --cap-drop=ALL \
    --security-opt=no-new-privileges:true \
    --env TRIVY_CACHE_DIR=/trivy-cache \
    --env TMPDIR=/trivy-tmp \
    --volume "${SCAN_DIR}:/scan:ro" \
    --volume "${TRIVY_CACHE_HOST}:/trivy-cache:rw" \
    --volume "${TRIVY_TMP_HOST}:/trivy-tmp:rw" \
    "${TRIVY_IMAGE}" \
    "$@"
}

echo
echo "==> Trivy version"

run_trivy version

echo
echo "==> Full HIGH/CRITICAL vulnerability visibility report"

run_trivy image \
  --input /scan/secure-delivery-api.tar \
  --scanners vuln \
  --severity HIGH,CRITICAL \
  --no-progress \
  --format table

echo
echo "==> Enforcing actionable HIGH/CRITICAL vulnerability gate"

run_trivy image \
  --input /scan/secure-delivery-api.tar \
  --scanners vuln \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --exit-code 1 \
  --no-progress \
  --format table

echo
echo "Trivy vulnerability policy passed."
