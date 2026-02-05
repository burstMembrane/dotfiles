#!/bin/bash
set -euo pipefail

echo "Installing GNU Stow..."
cd /tmp
curl -fsSL http://ftp.gnu.org/gnu/stow/stow-2.4.1.tar.gz -o stow-2.4.1.tar.gz
tar -xzf stow-2.4.1.tar.gz
cd stow-2.4.1
./configure
make
sudo make install

echo "Cleaning up..."
rm -rf /tmp/stow-2.4.1 /tmp/stow-2.4.1.tar.gz

echo "GNU Stow installed successfully"
stow --version
