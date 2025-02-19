#!/bin/bash

# Allow KSH_VERSION to be unbound for zsh installation
set -eo pipefail

add_to_path() {
    export PATH="$1:$PATH"
}
add_to_zshrc() {
    grep -q "$1" "$HOME/.zshrc" || echo "$1" >> "$HOME/.zshrc"
}



# Install sudo if not present
if ! command -v sudo &>/dev/null; then
    apt-get update
    apt-get install -y sudo
fi

# Install yq if not present
if ! command -v yq &>/dev/null; then
    mkdir -p "$HOME/.local/bin"
    ARCH=$(uname -m)
    # Convert architecture name for yq download
    case "${ARCH}" in
        aarch64) ARCH="arm64" ;;
        x86_64)  ARCH="amd64" ;;
    esac
    curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${ARCH}" -o "$HOME/.local/bin/yq"
    chmod +x "$HOME/.local/bin/yq"
    export PATH="$HOME/.local/bin:$PATH"
fi

# Helper functions
log() { echo -e "\033[1;34m$1\033[0m"; }
log_success() { echo -e "\033[1;32m$1\033[0m"; }
log_warning() { echo -e "\033[1;33m$1\033[0m"; }
log_error() { echo -e "\033[1;31m$1\033[0m"; }

# Install system packages
log "Installing system packages..."
packages=$(yq '.system.packages[]' bootstrap.yaml | tr '\n' ' ')

if [ ! -f /home/liam/.packages_installed ]; then
    sudo apt-get update
    sudo apt-get install -y $packages
    touch /home/liam/.packages_installed
fi

# Set locale
locale=$(yq '.locale' bootstrap.yaml)
sudo locale-gen "$locale"

# Create paths
while IFS= read -r path; do
    path=$(eval echo "$path")
    mkdir -p "$path"
done < <(yq '.paths[]' bootstrap.yaml)

# Create symlinks
yq '.symlinks[]' bootstrap.yaml | while read -r line; do
    source=$(yq '.source' <(echo "$line"))
    target=$(yq '.target' <(echo "$line"))
    target=$(eval echo "$target")
    ln -sf "$source" "$target"
done

# Install tools
yq '.tools | keys[]' bootstrap.yaml | while read -r tool; do
    log "Processing $tool..."
    
    # Check if tool should be skipped in Docker
    if [[ -f /.dockerenv ]] && yq ".tools.$tool.skip_in_docker" bootstrap.yaml | grep -q "true"; then
        log_warning "Skipping $tool in Docker environment"
        continue
    fi

    # Check if tool is already installed
    if check_cmd=$(yq ".tools.$tool.check_command" bootstrap.yaml) && [ "$check_cmd" != "null" ]; then
        if command -v "$check_cmd" &>/dev/null; then
            log_success "$tool is already installed"
            continue
        fi
    fi

    if check_path=$(yq ".tools.$tool.check_path" bootstrap.yaml) && [ "$check_path" != "null" ]; then
        check_path=$(eval echo "$check_path")
        if [ -e "$check_path" ]; then
            log_success "$tool is already installed"
            continue
        fi
    fi

    # Install tool
    log_warning "Installing $tool..."
    yq ".tools.$tool.install[]" bootstrap.yaml | while read -r cmd; do
        cmd=$(eval echo "$cmd")
        eval "$cmd"
    done

    # Run post-install commands
    if yq ".tools.$tool.post_install" bootstrap.yaml | grep -q "\[\]"; then
        yq ".tools.$tool.post_install[]" bootstrap.yaml | while read -r cmd; do
            cmd=$(eval echo "$cmd")
            eval "$cmd"
        done
    fi

    # Run cleanup commands
    if yq ".tools.$tool.cleanup" bootstrap.yaml | grep -q "\[\]"; then
        yq ".tools.$tool.cleanup[]" bootstrap.yaml | while read -r cmd; do
            cmd=$(eval echo "$cmd")
            eval "$cmd"
        done
    fi
done

# Handle zsh plugins separately
# Check for zsh plugins
log "Checking for ZSH plugins..."
if [ ! -f bootstrap.yaml ]; then
    log_error "bootstrap.yaml not found!"
    exit 1
fi

# Debug output
plugins_check=$(yq '.tools.zsh_plugins.plugins' bootstrap.yaml)
log "Found plugins configuration: $plugins_check"

if [ -n "$plugins_check" ] && [ "$plugins_check" != "null" ]; then
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom/plugins}"
    log "Using ZSH_CUSTOM directory: $ZSH_CUSTOM"
    mkdir -p "$ZSH_CUSTOM"
    
    yq '.tools.zsh_plugins.plugins[]' bootstrap.yaml | while read -r plugin_info; do
        
        name=$(yq '.name' <(echo "$plugin_info"))
        repo=$(yq '.repo' <(echo "$plugin_info"))
        
        log "Processing plugin: $name from $repo"
        
        if [ ! -d "$ZSH_CUSTOM/$name" ]; then
            log_warning "Installing $name..."
            git clone "https://github.com/$repo" "$ZSH_CUSTOM/$name"
            if [ $? -eq 0 ]; then
                log_success "Successfully cloned $name"
                # Add plugin to .zshrc if not already present
                if [ -f "$HOME/.zshrc" ]; then
                    if ! grep -q "$name" "$HOME/.zshrc"; then
                        if grep -q "plugins=(" "$HOME/.zshrc"; then
                            sed -i "s/plugins=(/plugins=($name /" "$HOME/.zshrc"
                            log_success "Added $name to .zshrc plugins"
                        else
                            echo "plugins=($name)" >> "$HOME/.zshrc"
                            log_success "Created new plugins line in .zshrc"
                        fi
                    fi
                else
                    log_warning ".zshrc not found, creating it..."
                    echo "plugins=($name)" > "$HOME/.zshrc"
                fi
            else
                log_error "Failed to clone $name"
            fi
        else
            log_success "$name is already installed"
        fi
    done
else
    log_warning "No ZSH plugins configuration found in bootstrap.yaml"
fi

# add to paths
add_to_path "$HOME/.local/bin"
add_to_path "$HOME/.local/bin/nvim-linux-$ARCH/bin"
add_to_zshrc "export PATH=$PATH:$HOME/.local/bin"
add_to_zshrc "export PATH=$PATH:$HOME/.local/bin/nvim-linux-$ARCH/bin"


# Check current locale
echo "Checking current locale settings..."
locale

# Set locale variables in ~/.zshrc if not already set
ZSHRC="$HOME/.zshrc"
LOCALE_STRING="export LANG=en_AU.UTF-8\nexport LC_ALL=en_US.UTF-8"

if ! grep -q "export LANG=en_AU.UTF-8" "$ZSHRC"; then
    echo "Adding locale settings to $ZSHRC..."
    echo -e "\n# Locale settings for Agnoster theme\n$LOCALE_STRING" >> "$ZSHRC"
else
    echo "Locale settings already present in $ZSHRC."
fi

# Apply locale settings to current shell session
export LANG=en_AU.UTF-8
export LC_ALL=en_AU.UTF-8

# Generate locale (for Linux)
if command -v locale-gen &> /dev/null; then
    echo "Generating locale..."
    sudo locale-gen en_AU.UTF-8
fi

# Apply locale changes (Debian/Ubuntu)
if command -v dpkg-reconfigure &> /dev/null; then
    echo "Reconfiguring locales..."
    sudo dpkg-reconfigure --frontend=noninteractive locales
fi

# Apply locale changes (Arch Linux)
if command -v localectl &> /dev/null; then
    echo "Setting locale with localectl..."
    sudo localectl set-locale LANG=en_AU.UTF-8
fi



# Verify locale changes
echo "Final locale settings:"
locale

echo "Locale setup complete. Restart your terminal if needed."
# generate locale and set $LANG to 
# LANG=en_AU.UTF-8
# LANGUAGE=en_AU:en
# LC_CTYPE="en_AU.UTF-8"
# LC_NUMERIC="en_AU.UTF-8"
# LC_TIME="en_AU.UTF-8"
# LC_COLLATE="en_AU.UTF-8"
# LC_MONETARY="en_AU.UTF-8"
# LC_MESSAGES="en_AU.UTF-8"
# LC_PAPER="en_AU.UTF-8"
# LC_NAME="en_AU.UTF-8"
# LC_ADDRESS="en_AU.UTF-8"
# LC_TELEPHONE="en_AU.UTF-8"
# LC_MEASUREMENT="en_AU.UTF-8"
# LC_IDENTIFICATION="en_AU.UTF-8"
# LC_ALL=
#

export LANG=en_AU.UTF-8
export LANGUAGE=en_AU.UTF-8
export LC_CTYPE=en_AU.UTF-8
export LC_NUMERIC=en_AU.UTF-8
export LC_TIME=en_AU.UTF-8
export LC_COLLATE=en_AU.UTF-8
export LC_MONETARY=en_AU.UTF-8
export LC_MESSAGES=en_AU.UTF-8
export LC_PAPER=en_AU.UTF-8
export LC_NAME=en_AU.UTF-8
export LC_ADDRESS=en_AU.UTF-8
export LC_TELEPHONE=en_AU.UTF-8
export LC_MEASUREMENT=en_AU.UTF-8
export LC_IDENTIFICATION=en_AU.UTF-8
export LC_ALL=en_AU.UTF-8

dotfiles_dir="$HOME/dotfiles"
cd "$dotfiles_dir"
# run the install script to install dotfiles
if [ -f "install" ]; then
    log "Running install script..."
    sudo chmod +x "install"
    mv "$HOME/.zshrc" "$HOME/.zshrc.old"
    echo "export PATH=\$PATH:$HOME/.local/bin/nvim-linux-$ARCH/bin" >> "$dotfiles_dir/zsh/dot-zshrc"
    ./install
fi


# add neovim to path
#
#
# Ensure .zshrc exists and has correct ownership
# Append the export path using tee



