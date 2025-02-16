#!/bin/bash

set -e          # Exit immediately if a command exits with a non-zero status
set -u          # Treat unset variables as an error
set -o pipefail # Fail a pipeline if any command fails

# Define color variables
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
NC="\e[0m" # No color
export DBIAN_FRONTEND=noninteractive
# We usually start off as root, so we need to make a 'liam' user
user=$(whoami)
initial_dir=$(pwd)

if [ "$user" == "liam" ]; then
  echo -e "${GREEN}Already using the 'liam' user.${NC}"
else
  echo -e "${YELLOW}Creating 'liam' user...${NC}"

  # Check if sudo exists
  if ! command -v sudo &>/dev/null; then
    echo -e "${YELLOW}Installing sudo...${NC}"
    apt-get update && apt-get -y -o Dpkg::Options::="--force-confold" install sudo
  else
    echo -e "${GREEN}Sudo is already installed.${NC}"
  fi

  sudo useradd -m -s /bin/bash liam

  # if we're interactive, we can set the password
  # otherwise, we'll need to set it manually
  if [ -t 0 ]; then
    sudo passwd liam
    sudo usermod -aG sudo liam
    sudo chown -R liam:liam /home/liam
    su - liam
  fi
fi

echo -e "${BLUE}Updating package lists...${NC}"
sudo apt-get update && sudo apt upgrade -y

echo -e "${BLUE}Installing dependencies...${NC}"
sudo apt-get install -y build-essential curl ca-certificates git unzip rar zsh tmux ripgrep bat vim fd-find fonts-powerline locales less

sudo locale-gen en_AU.UTF-8
# Link bat

if [[ ! -d "$HOME/.local/bin" ]]; then
  mkdir -p ~/.local/bin
fi

if [[ ! -x "$HOME/.local/bin/bat" ]]; then
  ln -s /usr/bin/batcat ~/.local/bin/bat
fi
# Install latest Neovim
if ! command -v nvim &>/dev/null; then
  echo -e "${YELLOW}Installing Neovim...${NC}"
  sudo apt-get install -y software-properties-common
  echo -e "${YELLOW}Adding Neovim PPA...${NC}"
  sudo add-apt-repository ppa:neovim-ppa/unstable -y
  echo -e "${BLUE}Updating package lists...${NC}"
  sudo apt-get update
  echo -e "${YELLOW}Installing Neovim...${NC}"
  sudo apt-get install -y neovim
  nvim --version
else
  echo -e "${GREEN}Neovim is already installed.${NC}"
fi

# Install uv for Python package management
echo -e "${BLUE}Installing uv...${NC}"
if ! command -v uv &>/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
else
  echo -e "${GREEN}uv is already installed.${NC}"
fi

# Install fzf
if [[ ! -d "$HOME/.fzf" ]]; then
  echo -e "${YELLOW}Installing fzf...${NC}"
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install
else
  echo -e "${GREEN}fzf is already installed.${NC}"
fi

# Install and configure Zsh with Oh-My-Zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo -e "${YELLOW}Installing Oh-My-Zsh...${NC}"
  sudo apt-get install -y zsh
  curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash
  chsh -s $(which zsh)
else
  echo -e "${GREEN}Oh-My-Zsh is already installed.${NC}"
fi

# Install Zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom/plugins}"

for plugin in zsh-syntax-highlighting zsh-autosuggestions; do
  if [[ ! -d "$ZSH_CUSTOM/$plugin" ]]; then
    echo -e "${YELLOW}Installing ${plugin}...${NC}"
    git clone "https://github.com/zsh-users/$plugin.git" "$ZSH_CUSTOM/$plugin"
  else
    echo -e "${GREEN}${plugin} is already installed.${NC}"
  fi
done

if [[ ! -d "$ZSH_CUSTOM/zsh-vi-mode" ]]; then
  echo -e "${YELLOW}Installing zsh-vi-mode...${NC}"
  git clone "https://github.com/jeffreytse/zsh-vi-mode.git" "$ZSH_CUSTOM/zsh-vi-mode"
else
  echo -e "${GREEN}zsh-vi-mode is already installed.${NC}"
fi

# Install Tmux Plugin Manager (TPM)
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  echo -e "${YELLOW}Installing Tmux Plugin Manager (TPM)...${NC}"
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
  echo -e "${GREEN}Tmux Plugin Manager is already installed.${NC}"
fi

# Install vim-code-dark theme
if [[ ! -d "$HOME/.vim/pack/themes/start/vim-code-dark" ]]; then
  echo -e "${YELLOW}Installing vim-code-dark theme...${NC}"
  mkdir -p ~/.vim/pack/themes/start
  cd ~/.vim/pack/themes/start
  git clone https://github.com/tomasiser/vim-code-dark
  cd "$initial_dir"
else
  echo -e "${GREEN}vim-code-dark theme is already installed.${NC}"
fi

# Install GNU Stow
if command -v stow &>/dev/null; then
  echo -e "${GREEN}GNU Stow is already installed.${NC}"
else
  echo -e "${YELLOW}Installing GNU Stow...${NC}"
  curl -O http://ftp.gnu.org/gnu/stow/stow-2.4.1.tar.gz
  tar -xzf stow-2.4.1.tar.gz
  cd stow-2.4.1
  ./configure
  make
  sudo make install
  cd "$initial_dir"
  # cleanup
  rm -rf stow-2.4.1 stow-2.4.1.tar.gz
fi

# Run the install script if present
if [[ -x "$initial_dir/install" ]]; then
  echo -e "${BLUE}Running install script...${NC}"
  "$initial_dir/install"
  mv $HOME/.zshrc $HOME/.zshrc.old
  stow zsh --dotfiles --adopt
else
  echo -e "${RED}Install script not found or not executable in $initial_dir.${NC}"
fi

# Install Tmux plugins
echo -e "${BLUE}Installing Tmux plugins...${NC}"
~/.tmux/plugins/tpm/bin/install_plugins

# Export Neovim binary path after setup
echo export PATH='$PATH:/opt/nvim-linux-x86_64/bin' >> ~/.zshrc

echo -e "${GREEN}All tools installed successfully! Restart your terminal for changes to take effect.${NC}"
