#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_DIR="${ROOT_DIR}/terraform"

CHECKOV_IMAGE="bridgecrew/checkov@sha256:6d20ebbcde58b2dce6e3151a6771fefa4d468281fe442475455623f5799b9f53"

echo "==> Terraform formatting check"

terraform \
  -chdir="${TERRAFORM_DIR}" \
  fmt \
  -check \
  -recursive

echo
echo "==> Terraform initialization"

terraform \
  -chdir="${TERRAFORM_DIR}" \
  init \
  -backend=false \
  -input=false

echo
echo "==> Terraform validation"

terraform \
  -chdir="${TERRAFORM_DIR}" \
  validate

echo
echo "==> TFLint plugin initialization"

tflint \
  --init \
  --config="${ROOT_DIR}/.tflint.hcl"

echo
echo "==> TFLint"

tflint \
  --chdir="${TERRAFORM_DIR}" \
  --config="${ROOT_DIR}/.tflint.hcl"

echo
echo "==> Checkov"

docker run --rm \
  --user "$(id -u):$(id -g)" \
  --cap-drop=ALL \
  --security-opt=no-new-privileges:true \
  --read-only \
  --tmpfs /tmp:rw,nosuid,nodev,size=512m,mode=1777 \
  --env HOME=/tmp/checkov-home \
  --env XDG_CACHE_HOME=/tmp/checkov-cache \
  --env TMPDIR=/tmp \
  --volume "${TERRAFORM_DIR}:/terraform:ro" \
  "${CHECKOV_IMAGE}" \
  -d /terraform \
  --framework terraform \
  --compact

echo
echo "IaC validation passed."
