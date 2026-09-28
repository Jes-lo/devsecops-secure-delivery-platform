#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

APP_IMAGE="secure-delivery-api:dast"
ZAP_IMAGE="ghcr.io/zaproxy/zaproxy@sha256:781a2bdaea47324e7bab583e2263f21d257b0aee61ed51521a5be45f5f5081ef"

NETWORK_NAME="devsecops-zap-$$"
TARGET_CONTAINER="secure-delivery-api-dast-$$"

WORK_DIR="$(mktemp -d)"

# The ZAP container runs with its own UID. A directory created by mktemp is
# normally accessible only to the host user, so use sticky temporary-directory
# permissions to allow ZAP to create reports without changing the OpenAPI file.
chmod 1777 "${WORK_DIR}"

SCAN_LOG="${WORK_DIR}/zap-api-scan.log"

REPORT_DIR="${ZAP_REPORT_DIR:-}"

cleanup() {
  docker rm -f "${TARGET_CONTAINER}" >/dev/null 2>&1 || true
  docker network rm "${NETWORK_NAME}" >/dev/null 2>&1 || true
  rm -rf "${WORK_DIR}"
}

trap cleanup EXIT

echo "==> Building application container"

docker build \
  --tag "${APP_IMAGE}" \
  "${ROOT_DIR}"

echo
echo "==> Creating isolated DAST network"

docker network create \
  --internal \
  "${NETWORK_NAME}" \
  >/dev/null

echo
echo "==> Starting hardened application container"

docker run -d \
  --name "${TARGET_CONTAINER}" \
  --network "${NETWORK_NAME}" \
  --network-alias secure-delivery-api-dast \
  --read-only \
  --tmpfs /tmp:rw,nosuid,nodev,size=64m,mode=1777 \
  --cap-drop=ALL \
  --security-opt=no-new-privileges:true \
  "${APP_IMAGE}" \
  >/dev/null

echo
echo "==> Waiting for application health"

APPLICATION_HEALTHY=false

for _ in {1..30}; do
  STATUS="$(
    docker inspect \
      --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
      "${TARGET_CONTAINER}" \
      2>/dev/null || true
  )"

  if [[ "${STATUS}" == "healthy" ]]; then
    APPLICATION_HEALTHY=true
    break
  fi

  sleep 1
done

if [[ "${APPLICATION_HEALTHY}" != "true" ]]; then
  echo "ERROR: Application did not become healthy."
  docker logs "${TARGET_CONTAINER}" || true
  exit 1
fi

echo "Application is healthy."

cp \
  "${ROOT_DIR}/docs/security/openapi.yaml" \
  "${WORK_DIR}/openapi.yaml"

echo
echo "==> Running OWASP ZAP API scan"

set +e

docker run --rm \
  --network "${NETWORK_NAME}" \
  --cap-drop=ALL \
  --security-opt=no-new-privileges:true \
  --volume "${WORK_DIR}:/zap/wrk:rw" \
  "${ZAP_IMAGE}" \
  zap-api-scan.py \
    -t /zap/wrk/openapi.yaml \
    -f openapi \
    -r zap-report.html \
    -J zap-report.json \
    -w zap-report.md \
    -T 3 \
    -z "-silent" \
    -d \
  > "${SCAN_LOG}" 2>&1

ZAP_EXIT=$?

set -e

echo
echo "===== ZAP SUMMARY ====="

grep -E \
  'Number of Imported URLs:|Total of |FAIL-NEW:|WARN-NEW:' \
  "${SCAN_LOG}" \
  || true

if [[ -n "${REPORT_DIR}" ]]; then
  mkdir -p "${REPORT_DIR}"

  cp \
    "${SCAN_LOG}" \
    "${REPORT_DIR}/zap-api-scan.log"

  for report in zap-report.html zap-report.json zap-report.md; do
    if [[ -f "${WORK_DIR}/${report}" ]]; then
      cp \
        "${WORK_DIR}/${report}" \
        "${REPORT_DIR}/${report}"
    fi
  done
fi

if [[ "${ZAP_EXIT}" -ne 0 ]]; then
  echo
  echo "ERROR: OWASP ZAP returned exit code ${ZAP_EXIT}."
  echo
  tail -n 80 "${SCAN_LOG}"
  exit "${ZAP_EXIT}"
fi

for report in zap-report.html zap-report.json zap-report.md; do
  if [[ ! -s "${WORK_DIR}/${report}" ]]; then
    echo "ERROR: Expected ZAP report was not generated: ${report}"
    exit 1
  fi
done

if ! grep -Eq \
  'FAIL-NEW:[[:space:]]+0.*WARN-NEW:[[:space:]]+0' \
  "${SCAN_LOG}"; then
  echo "ERROR: ZAP did not produce the expected zero-finding summary."
  exit 1
fi

echo
echo "DAST validation passed."
