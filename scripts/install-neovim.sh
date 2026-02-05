#!/bin/bash
set -euo pipefail

INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
    NVIM_FILE="nvim-linux-arm64"
else
    NVIM_FILE="nvim-linux-x86_64"
fi

URL="https://github.com/neovim/neovim/releases/latest/download/${NVIM_FILE}.tar.gz"

echo "Downloading neovim from: $URL"
curl -fLO "$URL"

tar -C "$INSTALL_DIR" -xzf "${NVIM_FILE}.tar.gz"
mv "$INSTALL_DIR/${NVIM_FILE}" "$INSTALL_DIR/nvim-dir"
ln -sf "$INSTALL_DIR/nvim-dir/bin/nvim" "$INSTALL_DIR/nvim"

rm -f "${NVIM_FILE}.tar.gz"

echo "Neovim installed successfully"
nvim --version
