#!/bin/bash

set -e
export DOCKER=true
echo "Building the Docker image with verbose output..."
docker buildx build --progress=plain -t ubuntu-bootstrap-yaml -f Dockerfile.bootstrap . --load
# run interactive shell
docker run --rm -it ubuntu-bootstrap-yaml zsh
# echo "Running the container..."
# docker run --rm ubuntu-bootstrap-yaml zsh -c "
#     echo 'Checking installed tools...';
#     command -v nvim && echo 'Neovim installed' || echo 'Neovim missing';
#     command -v uv && echo 'uv installed' || echo 'uv missing';
#     command -v fzf && echo 'fzf installed' || echo 'fzf missing';
#     command -v tmux && echo 'tmux installed' || echo 'tmux missing';
#     command -v bat && echo 'bat installed' || echo 'bat missing';
#     command -v exa && echo 'exa installed' || echo 'exa missing';
#     command -v rg && echo 'ripgrep installed' || echo 'ripgrep missing';
#     command -v unzip && echo 'unzip installed' || echo 'unzip missing';
#     command -v rar && echo 'rar installed' || echo 'rar missing';
#     command -v zsh && echo 'zsh installed' || echo 'zsh missing';
#     [ -d \"$HOME/.oh-my-zsh\" ] && echo 'Oh-My-Zsh installed' || echo 'Oh-My-Zsh missing';
#     [ -d \"$HOME/.tmux/plugins/tpm\" ] && echo 'TPM installed' || echo 'TPM missing';
#     echo 'All checks complete.';
# "
