# Qdrant (arm64/Raspberry Pi) Dockerfile
# - Builds Qdrant from source (default: v1.16.2)
# - Includes official entrypoint + web UI static assets
# - Tuned for Raspberry Pi 5 (Cortex-A76) but overridable

ARG QDRANT_VERSION=v1.16.2
ARG RUST_VERSION=1.91.1
ARG DEBIAN_SUITE=bookworm

############################
# Builder
############################
FROM --platform=$BUILDPLATFORM rust:${RUST_VERSION}-slim-${DEBIAN_SUITE} AS builder

ARG QDRANT_VERSION
ARG TARGET_CPU=cortex-a76

# Build deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    curl \
    build-essential \
    cmake \
    pkg-config \
    clang \
    lld \
    protobuf-compiler \
    libprotobuf-dev \
    protobuf-compiler-grpc \
    jq \
    libssl-dev \
    libunwind-dev \
    unzip \
    && rm -rf /var/lib/apt/lists/*

    WORKDIR /qdrant

# Fetch source at a tagged release (drop-in replacement behavior across Pis)
RUN git clone --depth 1 --branch ${QDRANT_VERSION} https://github.com/qdrant/qdrant.git .

# Pull the web UI bundle (used by the official images)
RUN mkdir -p /static && STATIC_DIR=/static ./tools/sync-web-ui.sh

# Build tuning for Pi (memory + perf)
ENV CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1
ENV CARGO_PROFILE_RELEASE_LTO=thin
ENV RUSTFLAGS="-C target-cpu=${TARGET_CPU} -C target-feature=+neon"
ENV PROTOC=/usr/bin/protoc
ENV PROTOC_INCLUDE=/usr/include

# Build qdrant with the same default feature used in the official image
RUN cargo build --profile release --features=stacktrace --bin qdrant \
    && cp target/release/qdrant /qdrant/qdrant

# Optional: SBOM (keep if you want parity with official; harmless if unused)
RUN cargo install cargo-sbom && cargo sbom > /qdrant/qdrant.spdx.json

############################
# Runtime
############################
FROM debian:${DEBIAN_SUITE}-slim AS runtime

ARG USER_ID=0
ARG APP=/qdrant

# Runtime deps (OpenSSL 3 on bookworm, libunwind, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    tzdata \
    libunwind8 \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Create app dirs + optional non-root user (matches official image behavior)
RUN if [ "${USER_ID}" != "0" ]; then \
      groupadd --gid "${USER_ID}" qdrant; \
      useradd --uid "${USER_ID}" --gid "${USER_ID}" -m qdrant; \
    fi \
    && mkdir -p "${APP}/storage" "${APP}/snapshots" "${APP}/config"

# Copy artifacts from builder
COPY --from=builder /qdrant/qdrant              ${APP}/qdrant
COPY --from=builder /qdrant/qdrant.spdx.json    ${APP}/qdrant.spdx.json
COPY --from=builder /qdrant/config              ${APP}/config
COPY --from=builder /qdrant/tools/entrypoint.sh ${APP}/entrypoint.sh
COPY --from=builder /static                     ${APP}/static

WORKDIR ${APP}

# Fix ownership if running non-root
RUN if [ "${USER_ID}" != "0" ]; then \
      chown -R "${USER_ID}:${USER_ID}" "${APP}"; \
    fi

USER ${USER_ID}:${USER_ID}

ENV TZ=Etc/UTC \
    RUN_MODE=production

EXPOSE 6333 6334

CMD ["./entrypoint.sh"]

