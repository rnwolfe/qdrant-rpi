# Qdrant Raspberry Pi Image (arm64)

This repository builds **Qdrant from source for Raspberry Pi (arm64)** and publishes a
drop-in compatible Docker image suitable for Raspberry Pi 4/5.  
It is optimized for **Raspberry Pi 5 (Cortex-A76, 16 GiB RAM)** and tracks official Qdrant
releases (e.g. `v1.16.2`).

The resulting image:

- Runs on **linux/arm64**
- Includes the **official Qdrant entrypoint and Web UI**
- Exposes the standard ports **6333 / 6334**
- Can be used as a direct replacement for `qdrant/qdrant` on Raspberry Pi

## Repository layout

```plain
qdrant-rpi-image/
  Dockerfile
  .dockerignore
  Makefile
  README.md
  versions/
    qdrant.version
  scripts/
    set-qdrant-version.sh
    build.sh
    release.sh
    smoke-test.sh
  .github/
    workflows/
      ci.yml
      release.yml
      bump-qdrant.yml
```

## Supported platforms

- **linux/arm64**
- Tested on:
  - Raspberry Pi 5 (16 GiB)
  - Raspberry Pi OS 64-bit
  - Ubuntu Server 22.04+ (arm64)

## Quick start

### 1. Set the Qdrant version

```bash
make set-version V=v1.16.2
````

This updates:

```plain
versions/qdrant.version
```

### 2. Build locally

```bash
make build IMAGE_REPO=local/qdrant
```

Optional environment overrides:

```bash
TARGET_CPU=cortex-a76 make build
```

### 3. Smoke test

```bash
make smoke IMAGE_REPO=local/qdrant
```

This:

- Starts the container
- Waits for `/healthz`
- Fails if Qdrant does not become ready

### 4. Run Qdrant

```bash
docker run -d \
  --name qdrant \
  -p 6333:6333 \
  -p 6334:6334 \
  -v qdrant_storage:/qdrant/storage \
  local/qdrant:$(cat versions/qdrant.version)-rpi
```

Health check:

```bash
curl http://localhost:6333/healthz
```

## Image tags

Published images follow this format:

```plain
<registry>/<repo>/qdrant:<qdrant-version>-rpi
<registry>/<repo>/qdrant:latest
```

Example:

```plain
ghcr.io/your-org/qdrant-rpi/qdrant:v1.16.2-rpi
```

## CI behavior

### Continuous Integration (`ci.yml`)

Runs on:

- Pull requests
- Pushes to `main`

CI performs:

- ARM64 build using Docker Buildx
- Local image load
- Container smoke test

No images are pushed.

### Release publishing (`release.yml`)

Triggered by:

- Manual workflow dispatch
- Git tag matching `repo-v*`

Publishes:

- `linux/arm64` image
- Tags:

  - `<version>-rpi`
  - `latest`

Registry:

- GitHub Container Registry (GHCR)

### Version bump automation (`bump-qdrant.yml`)

Manual workflow that:

1. Updates `versions/qdrant.version`
2. Commits the change
3. Opens a pull request

Input example:

```bash
v1.16.3
```

## Running as non-root (optional)

To run Qdrant as a non-root user inside the container:

```bash
docker build \
  --build-arg USER_ID=1000 \
  -t qdrant-nonroot .
```

The container will:

- Create a matching UID/GID
- Chown `/qdrant`
- Run safely without root privileges

## Why build from source?

- Official Qdrant images are **x86_64-focused**
- ARM images often lag or omit optimizations
- Raspberry Pi benefits from:

  - NEON instructions
  - Cortex-A76 tuning
  - Reduced memory pressure during build

This repo keeps **full parity with official behavior**, while remaining Pi-native.

## License

- Qdrant: Apache 2.0
- This repository: Apache 2.0

## Maintainer notes

This repository intentionally:

- Avoids GPU features
- Avoids cross-compiling complexity unless needed
- Prioritizes **predictable, reproducible Pi builds**

If we want:

- Multi-arch images (amd64 + arm64)
- Auto-tracking of upstream Qdrant tags
- Smaller runtime images (distroless)

Those can be added cleanly without breaking this baseline.
