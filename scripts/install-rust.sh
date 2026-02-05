#!/bin/bash
set -euo pipefail

echo "Installing Rust..."
curl -fsSL https://sh.rustup.rs | sh -s -- -y

echo "Rust installed successfully"
"$HOME/.cargo/bin/rustc" --version
