#!/usr/bin/env bash

set -euo pipefail

IMAGE_NAME="secure-delivery-api:test"
CONTAINER_NAME="secure-delivery-api-test-$$"
LOG_FILE="$(mktemp)"
HOST_PORT=""

cleanup() {
  if docker container inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
    docker rm --force "${CONTAINER_NAME}" >/dev/null 2>&1 || true
  fi

  rm -f "${LOG_FILE}"
}

trap cleanup EXIT

echo "==> Building container image"

docker build \
  --tag "${IMAGE_NAME}" \
  .

echo "==> Validating image configuration"

IMAGE_USER="$(
  docker image inspect "${IMAGE_NAME}" \
    --format '{{.Config.User}}'
)"

if [[ "${IMAGE_USER}" != "node" ]]; then
  echo "Expected image user 'node', got '${IMAGE_USER}'"
  exit 1
fi

IMAGE_CMD="$(
  docker image inspect "${IMAGE_NAME}" \
    --format '{{json .Config.Cmd}}'
)"

if [[ "${IMAGE_CMD}" != '["node","src/server.js"]' ]]; then
  echo "Unexpected container command: ${IMAGE_CMD}"
  exit 1
fi

echo "==> Validating effective runtime user"

RUNTIME_ID="$(
  docker run --rm \
    --entrypoint id \
    "${IMAGE_NAME}"
)"

echo "${RUNTIME_ID}"

if grep -q 'uid=0(root)' <<<"${RUNTIME_ID}"; then
  echo "Container must not run as root"
  exit 1
fi

if ! grep -q 'uid=1000(node)' <<<"${RUNTIME_ID}"; then
  echo "Expected Node.js non-root user was not found"
  exit 1
fi

echo "==> Validating production-only dependencies"

docker run --rm \
  --entrypoint node \
  "${IMAGE_NAME}" \
  -e "
    require.resolve('express');

    try {
      require.resolve('supertest');
      console.error('Development dependency supertest is present');
      process.exit(1);
    } catch (error) {
      if (error.code !== 'MODULE_NOT_FOUND') {
        throw error;
      }
    }
  "

echo "==> Validating runtime package managers are absent"

docker run --rm \
  --entrypoint sh \
  "${IMAGE_NAME}" \
  -c '
    set -eu

    for command_name in npm npx corepack yarn yarnpkg; do
      if command -v "$command_name" >/dev/null 2>&1; then
        echo "Unexpected runtime command found: $command_name"
        exit 1
      fi
    done
  '

echo "==> Starting hardened container"

docker run -d \
  --name "${CONTAINER_NAME}" \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=16m \
  --cap-drop=ALL \
  --security-opt=no-new-privileges:true \
  --publish 127.0.0.1::3000 \
  --env NODE_ENV=container-test \
  "${IMAGE_NAME}" >/dev/null

PORT_MAPPING="$(
  docker port "${CONTAINER_NAME}" 3000/tcp
)"

HOST_PORT="${PORT_MAPPING##*:}"

if [[ ! "${HOST_PORT}" =~ ^[0-9]+$ ]]; then
  echo "Could not determine published container port"
  exit 1
fi

BASE_URL="http://127.0.0.1:${HOST_PORT}"

echo "==> Waiting for application health"

for _ in {1..20}; do
  if curl --fail --silent \
    "${BASE_URL}/health" >/dev/null 2>&1; then
    break
  fi

  sleep 0.5
done

HEALTH_RESPONSE="$(
  curl --fail --silent --show-error \
    "${BASE_URL}/health"
)"

VERSION_RESPONSE="$(
  curl --fail --silent --show-error \
    "${BASE_URL}/version"
)"

STATUS_RESPONSE="$(
  curl --fail --silent --show-error \
    "${BASE_URL}/api/status"
)"

[[ "${HEALTH_RESPONSE}" == '{"status":"ok"}' ]] || {
  echo "Unexpected /health response"
  exit 1
}

[[ "${VERSION_RESPONSE}" == '{"name":"devsecops-secure-delivery-platform","version":"0.1.0"}' ]] || {
  echo "Unexpected /version response"
  exit 1
}

[[ "${STATUS_RESPONSE}" == '{"service":"secure-delivery-api","environment":"container-test","status":"operational"}' ]] || {
  echo "Unexpected /api/status response"
  exit 1
}

echo "==> Waiting for Docker healthcheck"

HEALTH_STATUS=""

for _ in {1..15}; do
  HEALTH_STATUS="$(
    docker inspect "${CONTAINER_NAME}" \
      --format '{{.State.Health.Status}}'
  )"

  if [[ "${HEALTH_STATUS}" == "healthy" ]]; then
    break
  fi

  sleep 5
done

if [[ "${HEALTH_STATUS}" != "healthy" ]]; then
  echo "Container did not become healthy"
  docker logs "${CONTAINER_NAME}"
  exit 1
fi

echo "==> Validating runtime hardening"

READ_ONLY="$(
  docker inspect "${CONTAINER_NAME}" \
    --format '{{.HostConfig.ReadonlyRootfs}}'
)"

CAP_DROP="$(
  docker inspect "${CONTAINER_NAME}" \
    --format '{{json .HostConfig.CapDrop}}'
)"

SECURITY_OPT="$(
  docker inspect "${CONTAINER_NAME}" \
    --format '{{json .HostConfig.SecurityOpt}}'
)"

[[ "${READ_ONLY}" == "true" ]] || {
  echo "Root filesystem is not read-only"
  exit 1
}

[[ "${CAP_DROP}" == '["ALL"]' ]] || {
  echo "Expected all Linux capabilities to be dropped"
  exit 1
}

if ! grep -q 'no-new-privileges:true' <<<"${SECURITY_OPT}"; then
  echo "no-new-privileges is not enabled"
  exit 1
fi

echo "==> Validating graceful shutdown"

docker stop \
  --timeout 5 \
  "${CONTAINER_NAME}" >/dev/null

docker logs "${CONTAINER_NAME}" >"${LOG_FILE}" 2>&1

grep -q 'SIGTERM received, shutting down' "${LOG_FILE}" || {
  echo "Graceful shutdown was not confirmed"
  cat "${LOG_FILE}"
  exit 1
}

docker rm "${CONTAINER_NAME}" >/dev/null

echo "Container validation passed."
