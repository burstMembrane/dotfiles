#!/bin/bash
set -euo pipefail

echo "Installing fzf..."
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all --no-update-rc

echo "fzf installed successfully"
~/.fzf/bin/fzf --version
