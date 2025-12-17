#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

QDRANT_VERSION="${QDRANT_VERSION:-$(cat versions/qdrant.version)}"
IMAGE_REPO="${IMAGE_REPO:-ghcr.io/${GITHUB_REPOSITORY:-local}/qdrant}"
TAG="${TAG:-${QDRANT_VERSION}-rpi}"
TARGET_CPU="${TARGET_CPU:-cortex-a76}"
PLATFORMS="${PLATFORMS:-linux/arm64}"

docker buildx build \
  --push \
  --platform "$PLATFORMS" \
  --build-arg QDRANT_VERSION="$QDRANT_VERSION" \
  --build-arg TARGET_CPU="$TARGET_CPU" \
  -t "${IMAGE_REPO}:${TAG}" \
  -t "${IMAGE_REPO}:latest" \
  .

