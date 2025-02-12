#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error
set -o pipefail  # Fail a pipeline if any command fails

echo "Updating package lists..."
sudo apt update && sudo apt upgrade -y

echo "Installing dependencies..."
sudo apt install -y build-essential curl git unzip rar zsh tmux fzf ripgrep bat exa

# Install latest Neovim
echo "Installing Neovim..."
NVIM_VERSION=$(curl -sL https://api.github.com/repos/neovim/neovim/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
curl -LO https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux64.tar.gz
sudo tar -C /usr/local -xzf nvim-linux64.tar.gz
rm nvim-linux64.tar.gz

# Install uv for Neovim package management
echo "Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install and configure Zsh with Oh-My-Zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Installing Oh-My-Zsh..."
    sudo apt install -y zsh
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash
    chsh -s $(which zsh)
fi

# Install Tmux Plugin Manager (TPM)
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    echo "Installing Tmux Plugin Manager (TPM)..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

echo "All tools installed successfully! Restart your terminal for changes to take effect."
