#!/usr/bin/env bash

set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-secure-delivery-api:sbom}"
SYFT_IMAGE="anchore/syft@sha256:500e2d872ac019436926e8322b4fc1f39441d94d21f6f4046c6ff29b30e8cb02"

SCAN_DIR="$(mktemp -d)"
OUTPUT_DIR="$(mktemp -d)"
SBOM_FILE="${OUTPUT_DIR}/secure-delivery-api.spdx.json"

cleanup() {
  rm -rf \
    "${SCAN_DIR}" \
    "${OUTPUT_DIR}"
}

trap cleanup EXIT

echo "==> Building application image"

docker build \
  --tag "${IMAGE_NAME}" \
  .

echo
echo "==> Exporting image"

docker save \
  --output "${SCAN_DIR}/secure-delivery-api.tar" \
  "${IMAGE_NAME}"

echo
echo "==> Syft version"

docker run --rm \
  "${SYFT_IMAGE}" \
  version

echo
echo "==> Generating SPDX JSON SBOM"

docker run --rm \
  --user "$(id -u):$(id -g)" \
  --cap-drop=ALL \
  --security-opt=no-new-privileges:true \
  --read-only \
  --tmpfs /tmp:rw,nosuid,nodev,size=1g,mode=1777 \
  --env HOME=/tmp/syft-home \
  --env XDG_CACHE_HOME=/tmp/syft-cache \
  --env TMPDIR=/tmp \
  --volume "${SCAN_DIR}:/scan:ro" \
  --volume "${OUTPUT_DIR}:/output:rw" \
  "${SYFT_IMAGE}" \
  scan \
    "docker-archive:/scan/secure-delivery-api.tar" \
    --output "spdx-json=/output/secure-delivery-api.spdx.json"

echo
echo "==> Validating SBOM file"

test -s "${SBOM_FILE}" || {
  echo "SBOM file is empty or missing"
  exit 1
}

python3 -m json.tool \
  "${SBOM_FILE}" \
  >/dev/null

echo "==> Validating SPDX content"

SBOM_FILE="${SBOM_FILE}" python3 <<'PY'
import json
import os
from pathlib import Path

sbom_path = Path(os.environ["SBOM_FILE"])
data = json.loads(sbom_path.read_text())

if data.get("spdxVersion") != "SPDX-2.3":
    raise SystemExit(
        f"Unexpected SPDX version: {data.get('spdxVersion')}"
    )

packages = data.get("packages", [])
relationships = data.get("relationships", [])

if not packages:
    raise SystemExit("SBOM contains no packages")

if not relationships:
    raise SystemExit("SBOM contains no relationships")

application = [
    package
    for package in packages
    if package.get("name") == "devsecops-secure-delivery-platform"
]

if not application:
    raise SystemExit("Application package was not found in the SBOM")

if not any(
    package.get("versionInfo") == "0.1.0"
    for package in application
):
    raise SystemExit("Expected application version 0.1.0 was not found")

express = [
    package
    for package in packages
    if package.get("name") == "express"
]

if not express:
    raise SystemExit("Express dependency was not found in the SBOM")

print("SPDX version:", data.get("spdxVersion"))
print("Packages:", len(packages))
print("Relationships:", len(relationships))

for package in application:
    print(
        "Application:",
        package.get("name"),
        package.get("versionInfo"),
    )

for package in express:
    print(
        "Express:",
        package.get("versionInfo"),
    )
PY

if [[ -n "${SBOM_OUTPUT_PATH:-}" ]]; then
  echo
  echo "==> Preserving SBOM at ${SBOM_OUTPUT_PATH}"

  mkdir -p "$(dirname "${SBOM_OUTPUT_PATH}")"
  cp "${SBOM_FILE}" "${SBOM_OUTPUT_PATH}"
fi

echo
echo "SBOM generation and validation passed."
