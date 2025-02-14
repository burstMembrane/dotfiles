#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error
set -o pipefail  # Fail a pipeline if any command fails


# we usually start off as root so we need to make a liam user
user=$(whoami)

if [ "$user" == "liam" ]; then
    echo "Already a liam user"
    exit 1
else
    apt install -y sudo
    sudo useradd -m -s /bin/bash liam
    sudo passwd liam
    sudo usermod -aG sudo liam
    su - liam
fi


echo "Updating package lists..."
sudo apt update && sudo apt upgrade -y

echo "Installing dependencies..."
sudo apt install -y build-essential curl git unzip rar zsh tmux fzf ripgrep bat exa

# Install latest Neovim
# if nvim is not installed
if ! command -v nvim &> /dev/null
then
  echo "Installing Neovim..."
  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
  sudo rm -rf /opt/nvim
  sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
  rm nvim-linux64.tar.gz
  export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
  echo export PATH='$PATH:/opt/nvim-linux-x86_64/bin' >> ~/.bashrc | tee -a ~/.zshrc
  # test with nvim --version
  nvim --version
fi
# Install uv for python package management
echo "Installing uv..."

if ! command -v uv &> /dev/null
then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi


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
#
if command -v stow &> /dev/null
then
  echo "Stow already installed"
else
  echo "Installing GNU Stow..."
  curl -O http://ftp.gnu.org/gnu/stow/stow-2.4.1.tar.gz
  tar -xzf stow-2.4.1.tar.gz
  cd stow-2.4.1


  ./configure
  make
  sudo make install
  cd "$initial_dir"  # Return to the initial directory
fi


# Run the install script from the initial directory
if [[ -x "$initial_dir/install" ]]; then
    echo "Running install script..."
    "$initial_dir/install"
    # ensure we adopt for zsh to override the default zshrc
    stow zsh --dotfiles --adopt
else
    echo "Install script not found or not executable in $initial_dir"
fi

echo "All tools installed successfully! Restart your terminal for changes to take effect."
