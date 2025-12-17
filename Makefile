SHELL := /bin/bash

QDRANT_VERSION ?= $(shell cat versions/qdrant.version)
IMAGE_REPO ?= ghcr.io/$(shell echo $$GITHUB_REPOSITORY)/qdrant
TAG ?= $(QDRANT_VERSION)-rpi

.PHONY: build release set-version smoke

build:
	IMAGE_REPO=$(IMAGE_REPO) TAG=$(TAG) ./scripts/build.sh

release:
	IMAGE_REPO=$(IMAGE_REPO) TAG=$(TAG) ./scripts/release.sh

set-version:
	@if [ -z "$(V)" ]; then echo "Usage: make set-version V=v1.16.2"; exit 1; fi
	./scripts/set-qdrant-version.sh "$(V)"

smoke:
	./scripts/smoke-test.sh "$(IMAGE_REPO):$(TAG)"

