#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:-}"
if [[ -z "$IMAGE" ]]; then
  echo "Usage: $0 <image:tag>" >&2
  exit 1
fi

name="qdrant-smoke-$$"

cleanup() { docker rm -f "$name" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker run -d --name "$name" -p 6333:6333 "$IMAGE" >/dev/null

# Wait up to ~30s
for i in {1..30}; do
  if curl -fsS "http://127.0.0.1:6333/healthz" >/dev/null 2>&1; then
    echo "Smoke test OK: /healthz"
    exit 0
  fi
  sleep 1
done

echo "Smoke test FAILED (no /healthz)" >&2
docker logs "$name" >&2 || true
exit 1

