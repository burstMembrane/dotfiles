#!/bin/bash

set -e
echo "Building the Docker image with verbose output..."
docker build --progress=plain -t ubuntu-bootstrap-yaml . --load
# run interactive shell
docker run --rm -it ubuntu-bootstrap-yaml zsh
