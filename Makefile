# Shell settings
SHELL := /bin/bash
.SHELLFLAGS := -ec
VERSION_FILE := version.txt
IMAGE_NAME := dicom-loadbalancer


# Colors for terminal output
YELLOW := \033[1;33m
GREEN := \033[1;32m
RED := \033[1;31m
NC := \033[0m # No Color

# Help text
.PHONY: help
help:
	@echo -e "$(YELLOW)DICOM Router Makefile$(NC)"
	@echo -e "$(YELLOW)=====================$(NC)"
	@echo -e "$(GREEN)Available targets:$(NC)"
	@echo -e "  $(YELLOW)build$(NC)          - Build DICOM router container image"
	@echo -e "  $(YELLOW)run$(NC)            - Run the DICOM router container"
	@echo -e "  $(YELLOW)run-bash$(NC)       - Run the container with bash shell"
	@echo -e "  $(YELLOW)bump-version$(NC)   - Bump the minor version number"
	@echo -e "  $(YELLOW)show-version$(NC)   - Display current version"

.PHONY: build
build:
	@echo "Start building..."
	podman build --build-arg dcmtk_version=$$(cat $(VERSION_FILE)) -t $(IMAGE_NAME):$$(cat $(VERSION_FILE)) .
	podman tag $(IMAGE_NAME):$$(cat $(VERSION_FILE)) $(IMAGE_NAME):latest

.PHONY: run run-bash
run:
	@echo "Start running..."
	podman run -it -p 11211:11211 -p 8404:8404 -v ${PWD}/dicom-samples:/data --rm --name $(IMAGE_NAME) $(IMAGE_NAME):latest

run-bash:
	@echo "Start running..."
	podman run -it -p 11211:11211 -p 8404:8404 -v ${PWD}/dicom-samples:/data --entrypoint=/bin/bash --rm --name $(IMAGE_NAME) $(IMAGE_NAME):latest

.PHONY: bump-version show-version

show-version:
	@echo -e "$(YELLOW)Current version: $$(cat $(VERSION_FILE))"

bump-version:
	@old=$$(cat $(VERSION_FILE)); \
	IFS=.; set -- $$old; \
	major=$$1; minor=$$2; \
	new_minor=$$((minor + 1)); \
	new="$$major.$$new_minor"; \
	echo "$$new" > $(VERSION_FILE); \
	git commit -m "Bump version to $$new" $(VERSION_FILE); \
	git tag -a "v$$new" -m "Version $$new"; \
	echo "Bumped version: $$old → $$new"