#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error
set -o pipefail  # Fail a pipeline if any command fails

# Store the initial directory
initial_dir=$(pwd)

echo "Updating package lists..."
sudo apt update && sudo apt upgrade -y

echo "Installing dependencies..."
sudo apt install -y build-essential curl git unzip rar zsh tmux fzf ripgrep bat exa vim fd-find

# Install latest Neovim
echo "Installing Neovim..."
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
rm nvim-linux-x86_64.tar.gz

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

# Install vim-code-dark theme
if [[ ! -d "$HOME/.vim/pack/themes/start/vim-code-dark" ]]; then
    echo "Installing vim-code-dark theme..."
    mkdir -p ~/.vim/pack/themes/start
    cd ~/.vim/pack/themes/start
    git clone https://github.com/tomasiser/vim-code-dark
    cd "$initial_dir"  # Return to the initial directory
fi

# Install GNU Stow
echo "Installing GNU Stow..."
curl -O http://ftp.gnu.org/gnu/stow/stow-2.4.1.tar.gz
tar -xzf stow-2.4.1.tar.gz
cd stow-2.4.1
./configure
make
sudo make install
cd "$initial_dir"  # Return to the initial directory

# Run the install script from the initial directory
if [[ -x "$initial_dir/install" ]]; then
    echo "Running install script..."
    "$initial_dir/install"
else
    echo "Install script not found or not executable in $initial_dir"
fi

echo "All tools installed successfully! Restart your terminal for changes to take effect."
