#!/usr/bin/env bash

set -euo pipefail

PORT="${PORT:-3100}"
LOG_FILE="$(mktemp)"
SERVER_PID=""

cleanup() {
  if [[ -n "${SERVER_PID}" ]] && kill -0 "${SERVER_PID}" 2>/dev/null; then
    kill -TERM "${SERVER_PID}" 2>/dev/null || true
    wait "${SERVER_PID}" 2>/dev/null || true
  fi

  rm -f "${LOG_FILE}"
}

trap cleanup EXIT

NODE_ENV=smoke PORT="${PORT}" node src/server.js >"${LOG_FILE}" 2>&1 &
SERVER_PID=$!

for _ in {1..20}; do
  if curl --fail --silent \
    "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1; then
    break
  fi

  sleep 0.25
done

HEALTH_RESPONSE="$(
  curl --fail --silent --show-error \
    "http://127.0.0.1:${PORT}/health"
)"

VERSION_RESPONSE="$(
  curl --fail --silent --show-error \
    "http://127.0.0.1:${PORT}/version"
)"

STATUS_RESPONSE="$(
  curl --fail --silent --show-error \
    "http://127.0.0.1:${PORT}/api/status"
)"

HEADERS="$(
  curl --silent --show-error \
    --dump-header - \
    --output /dev/null \
    "http://127.0.0.1:${PORT}/health"
)"

[[ "${HEALTH_RESPONSE}" == '{"status":"ok"}' ]] || {
  echo "Unexpected /health response"
  exit 1
}

[[ "${VERSION_RESPONSE}" == '{"name":"devsecops-secure-delivery-platform","version":"0.1.0"}' ]] || {
  echo "Unexpected /version response"
  exit 1
}

[[ "${STATUS_RESPONSE}" == '{"service":"secure-delivery-api","environment":"smoke","status":"operational"}' ]] || {
  echo "Unexpected /api/status response"
  exit 1
}

if grep -qi '^x-powered-by:' <<<"${HEADERS}"; then
  echo "Unexpected X-Powered-By header detected"
  exit 1
fi

kill -TERM "${SERVER_PID}"
wait "${SERVER_PID}"
SERVER_PID=""

grep -q 'SIGTERM received, shutting down' "${LOG_FILE}" || {
  echo "Graceful shutdown was not confirmed"
  exit 1
}

echo "Smoke test passed."
