.PHONY: build run

NAMESPACE=workspace-codium-codium
TARGET=release
TAG=latest

build:
	@podman build --file Containerfile --tag localhost/$(NAMESPACE):$(TAG)
	@podman image tree localhost/$(NAMESPACE):$(TAG)

run:
	@podman run --rm -it -p 3000:3000 localhost/$(NAMESPACE):$(TAG)