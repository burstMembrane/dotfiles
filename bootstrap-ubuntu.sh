#!/bin/bash

set -euo pipefail
# echo commands
set -x
# Define color variables
declare -r GREEN="\e[32m" YELLOW="\e[33m" RED="\e[31m" BLUE="\e[34m" NC="\e[0m"

# Helper functions
log() { echo -e "${2:-$BLUE}$1${NC}"; }
log_success() { log "$1" "$GREEN"; }
log_warning() { log "$1" "$YELLOW"; }
log_error() { log "$1" "$RED"; }

add_to_path() {
    [[ ":$PATH:" != *":$1:"* ]] && export PATH="$1:$PATH"
}

add_to_zshrc() {
    grep -q "$1" "$HOME/.zshrc" || echo "$1" >> "$HOME/.zshrc"
}

install_if_missing() {
    local cmd=$1
    local msg=${2:-$1}
    if ! command -v "$cmd" &>/dev/null; then
        log_warning "Installing $msg..."
        shift 2
        "$@"
    else
        log_success "$msg is already installed."
    fi
}


# Check if running in Docker
if ! grep -qE '(docker|lxc)' /proc/1/cgroup; then
  if [ "$(whoami)" != "liam" ]; then
        log_warning "Creating 'liam' user..."
        
        # Install sudo if missing
        if ! command -v sudo &>/dev/null; then
            log_warning "Installing sudo..."
            apt-get update
            apt-get -y -o Dpkg::Options::="--force-confold" install sudo
        else
            log_success "sudo is already installed."
        fi

        sudo useradd -m -s /bin/bash liam
        if [ -t 0 ]; then
            sudo passwd liam
            sudo usermod -aG sudo liam
            sudo chown -R liam:liam /home/liam
            su - liam
        fi
    else
        log_success "Already using the 'liam' user."
    fi
fi
# Environment setup
export DEBIAN_FRONTEND=noninteractive
readonly ARCH=$(uname -m)
readonly initial_dir=$(pwd)
readonly user=$(whoami)
readonly HOME=/home/liam
# System updates and base packages
log "Updating package lists..."
sudo apt-get update && sudo apt upgrade -y

log "Installing dependencies..."
sudo apt-get install -y build-essential git wget unzip zsh tmux ripgrep bat curl vim \
    fd-find fonts-powerline locales less

sudo locale-gen en_AU.UTF-8

# Create local bin directory and symlinks
mkdir -p ~/.local/bin
[ ! -x "$HOME/.local/bin/bat" ] && ln -s /usr/bin/batcat ~/.local/bin/bat

# Install tools
if ! command -v cryptr &>/dev/null; then
    log_warning "Installing cryptr..."
    git clone https://github.com/nodesocket/cryptr.git && \
    ln -s "$PWD/cryptr/cryptr.bash" /usr/local/bin/cryptr
else
    log_success "cryptr is already installed."
fi

# Install Neovim
if ! command -v nvim &>/dev/null; then
    log_warning "Installing Neovim..."
    curl -LO "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$ARCH.tar.gz" && \
    sudo tar -C /opt -xzf "nvim-linux-$ARCH.tar.gz" && \
    add_to_path "/opt/nvim-linux-$ARCH/bin" && \
    nvim --version
else
    log_success "Neovim is already installed."
fi

# Install uv (skip in Docker)
if ! grep -qE '(docker|lxc)' /proc/1/cgroup; then
    if ! command -v uv &>/dev/null; then
        log_warning "Installing uv..."
        curl -fsSL https://astral.sh/uv/install.sh | sh
    else
        log_success "uv is already installed."
    fi
fi

# Install fzf
[ ! -d "$HOME/.fzf" ] && {
    log_warning "Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install
} || log_success "fzf is already installed."

# Install Oh-My-Zsh and plugins
[ ! -d "$HOME/.oh-my-zsh" ] && {
    log_warning "Installing Oh-My-Zsh..."
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash
    chsh -s $(which zsh)
} || log_success "Oh-My-Zsh is already installed."

# Install Zsh plugins
readonly ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom/plugins}"
for plugin in zsh-syntax-highlighting zsh-autosuggestions zsh-vi-mode; do
    [ ! -d "$ZSH_CUSTOM/$plugin" ] && {
        log_warning "Installing ${plugin}..."
        git clone "https://github.com/${plugin#zsh-vi-mode:jeffreytse/}/$plugin.git" "$ZSH_CUSTOM/$plugin"
    } || log_success "${plugin} is already installed."
done

# Install TPM
[ ! -d "$HOME/.tmux/plugins/tpm" ] && {
    log_warning "Installing Tmux Plugin Manager..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
} || log_success "Tmux Plugin Manager is already installed."

# Install vim-code-dark theme
[ ! -d "$HOME/.vim/pack/themes/start/vim-code-dark" ] && {
    log_warning "Installing vim-code-dark theme..."
    mkdir -p ~/.vim/pack/themes/start
    (cd ~/.vim/pack/themes/start && git clone https://github.com/tomasiser/vim-code-dark)
} || log_success "vim-code-dark theme is already installed."

# Install GNU Stow
if ! command -v stow &>/dev/null; then
    log_warning "Installing GNU Stow..."
    curl -fsSL http://ftp.gnu.org/gnu/stow/stow-2.4.1.tar.gz -o stow-2.4.1.tar.gz && \
    tar -xzf stow-2.4.1.tar.gz && \
    cd stow-2.4.1 && \
    ./configure && \
    make && \
    sudo make install && \
    cd "$initial_dir" && \
    rm -rf stow-2.4.1 stow-2.4.1.tar.gz
else
    log_success "GNU Stow is already installed."
fi

# goback to $HOME/dotfiles
cd $HOME/dotfiles
initial_dir=$PWD

# Run install script if present
if [ -x "$initial_dir/install" ]; then
    log "Running install script..."
    "$initial_dir/install"
    mv "$HOME/.zshrc" "$HOME/.zshrc.old"
    stow zsh --dotfiles --adopt
else
    log_error "Install script not found or not executable in $initial_dir."
fi

# Install Tmux plugins
log "Installing Tmux plugins..."
$HOME/.tmux/plugins/tpm/bin/install_plugins

# Final setup
add_to_zshrc "export PATH=$PATH:$HOME/.local/bin"
add_to_zshrc "export PATH=$PATH:$HOME/.local/bin/nvim-linux-$ARCH/bin"  

for tool in nvim uv stow tmux fzf sudo fd-find bat curl vim ripgrep locales less; do
    if ! command -v "$tool" &>/dev/null; then
        log_error "$tool is not installed."
    fi
done

log_success "All tools installed successfully! Restart your terminal for changes to take effect."
