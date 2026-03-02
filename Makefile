.PHONY: build run

NAME=codium
TARGET=release
TAG=latest

build:
	@podman build --ssh default --file Containerfile --tag localhost/$(NAME):$(TAG)
	@podman image tree localhost/$(NAME):$(TAG)

run:
	@podman run --rm -it -p 3000:3000 localhost/$(NAME):$(TAG)