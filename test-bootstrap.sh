#!/bin/bash

set -e

# Set the image name and tag
IMAGE_NAME="liamfpower/devcontainer"
TAG="latest"  # you can change this or make it a parameter
FULL_IMAGE_NAME="${IMAGE_NAME}:${TAG}"
echo "Building the Docker image with verbose output..."
docker build --platform linux/amd64 --progress=plain -t ${FULL_IMAGE_NAME} . --load

# Push the image to Docker Hub
echo "Pushing image to Docker Hub..."
docker push ${FULL_IMAGE_NAME}

# run interactive shell
docker run --rm -it ${FULL_IMAGE_NAME} zsh
