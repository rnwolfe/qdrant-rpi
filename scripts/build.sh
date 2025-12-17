#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

QDRANT_VERSION="${QDRANT_VERSION:-$(cat versions/qdrant.version)}"
IMAGE_REPO="${IMAGE_REPO:-ghcr.io/${GITHUB_REPOSITORY:-local}/qdrant}"
TAG="${TAG:-${QDRANT_VERSION}-rpi}"
TARGET_CPU="${TARGET_CPU:-cortex-a76}"

USE_BUILDX="${USE_BUILDX:-1}"
PLATFORMS="${PLATFORMS:-linux/arm64}"

echo "QDRANT_VERSION=$QDRANT_VERSION"
echo "IMAGE_REPO=$IMAGE_REPO"
echo "TAG=$TAG"
echo "PLATFORMS=$PLATFORMS"

if [[ "$USE_BUILDX" == "1" ]]; then
  docker buildx build \
    --platform "$PLATFORMS" \
    --build-arg QDRANT_VERSION="$QDRANT_VERSION" \
    --build-arg TARGET_CPU="$TARGET_CPU" \
    -t "${IMAGE_REPO}:${TAG}" \
    -t "${IMAGE_REPO}:latest" \
    .
else
  docker build \
    --build-arg QDRANT_VERSION="$QDRANT_VERSION" \
    --build-arg TARGET_CPU="$TARGET_CPU" \
    -t "${IMAGE_REPO}:${TAG}" \
    -t "${IMAGE_REPO}:latest" \
    .
fi

