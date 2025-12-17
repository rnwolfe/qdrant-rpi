#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 vX.Y.Z" >&2
  exit 1
fi

ver="$1"
if [[ ! "$ver" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must look like v1.16.2" >&2
  exit 1
fi

mkdir -p versions
echo "$ver" > versions/qdrant.version
echo "Set Qdrant version to $(cat versions/qdrant.version)"

