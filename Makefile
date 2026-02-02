# Copyright (c) 2026 The BFE Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Image settings
IMAGE_NAME ?= service-controller
VERSION ?= $(shell cat VERSION 2>/dev/null || echo "v1.0.0")
NO_CACHE ?= false

# build variables (moved from build/build.sh)
GO ?= go
GIT_COMMIT ?= $(shell git rev-parse HEAD 2>/dev/null || true)
OUTDIR ?= $(shell pwd)/output
BIN_NAME ?= service-controller
BUILD_TARGET ?= ./cmd/service-controller

# buildx / multi-arch
PLATFORMS ?= linux/amd64,linux/arm64
BUILDER_NAME ?= sc-builder

buildx-check:
	@docker buildx version >/dev/null 2>&1 || ( \
		echo "Error: docker buildx is not available."; \
		exit 1; \
	)

buildx-init: buildx-check
	@docker buildx inspect $(BUILDER_NAME) >/dev/null 2>&1 || docker buildx create --name $(BUILDER_NAME) --driver docker-container --use
	@docker buildx use $(BUILDER_NAME)
	@docker buildx inspect --bootstrap >/dev/null 2>&1 || true

docker:
	@echo "Building docker image..."
	@NORM_VERSION=$$(echo "$(VERSION)" | sed 's/^v*/v/'); \
	NO_CACHE_OPT=$$(if [ "$(NO_CACHE)" = "true" ]; then echo "--no-cache"; fi); \
	echo "Version: $$NORM_VERSION"; \
	docker build $$NO_CACHE_OPT -t $(IMAGE_NAME):$$NORM_VERSION -t $(IMAGE_NAME):latest -f Dockerfile .

docker-push:
	@if [ -z "$(REGISTRY)" ]; then \
		echo "Error: REGISTRY is required"; \
		echo "Usage: make docker-push REGISTRY=ghcr.io/your-org"; \
		exit 1; \
	fi
	@echo "Building and pushing multi-arch image via buildx..."
	@echo "Platforms: $(PLATFORMS)"
	@$(MAKE) buildx-init
	@NORM_VERSION=$$(echo "$(VERSION)" | sed 's/^v*/v/'); \
	NO_CACHE_OPT=$$(if [ "$(NO_CACHE)" = "true" ]; then echo "--no-cache"; fi); \
	echo "Build+push prod (multi-arch)"; \
	docker buildx build --platform $(PLATFORMS) $$NO_CACHE_OPT -t $(REGISTRY)/$(IMAGE_NAME):$$NORM_VERSION -t $(REGISTRY)/$(IMAGE_NAME):latest -f Dockerfile --push .; \
	echo "Pushed multi-arch image: $(REGISTRY)/$(IMAGE_NAME):$$NORM_VERSION"

build:
	@echo "Building binary $(BIN_NAME)..."
	@mkdir -p $(OUTDIR);
	@NORM_VERSION=$$(echo "$(VERSION)" | sed 's/^v*/v/'); \
	GIT_COMMIT_VAL=$(GIT_COMMIT); \
	$(GO) build -ldflags "-X main.version=$$NORM_VERSION -X main.commit=$$GIT_COMMIT_VAL" -o $(OUTDIR)/$(BIN_NAME) $(BUILD_TARGET); \
	chmod a+x $(OUTDIR)/*; \
	echo "$$GIT_COMMIT_VAL" > $(OUTDIR)/$(BIN_NAME).commit

.PHONY: docker docker-push buildx-init buildx-check build