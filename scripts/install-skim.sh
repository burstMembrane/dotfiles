#!/bin/bash
set -euo pipefail

echo "Installing skim..."
git clone --depth 1 https://github.com/lotabout/skim.git ~/.skim
~/.skim/install

echo "skim installed successfully"
~/.skim/bin/sk --version
