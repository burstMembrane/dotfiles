#!/bin/bash

# Allow KSH_VERSION to be unbound for zsh installation
# set -eo pipefail
add_to_path() {
    echo "Adding to PATH: $1"
    local new_path path_entry
    new_path=$(realpath -m "$1")  # Ensure absolute path
    if [ ! -d "$new_path" ]; then
        echo "Path does not exist: $new_path"
        return
    fi

    # Check if PATH already contains new_path
    if [[ ":$PATH:" == *":$new_path:"* ]]; then
        echo "Path already in PATH: $new_path"
        return
    fi

    # Create the new PATH entry
    path_entry="export PATH=\"$new_path:\$PATH\""

    # Add to dotfiles zshrc if not already present
    if [[ -n "$DOTFILES_ZSHRC" && -f "$DOTFILES_ZSHRC" ]]; then
        if ! grep -Fxq "$path_entry" "$DOTFILES_ZSHRC"; then
            echo "$path_entry" >> "$DOTFILES_ZSHRC"
            echo "Added to DOTFILES_ZSHRC: $new_path"
        fi
    fi

    # Update current session
    export PATH="$new_path:$PATH"

    # Update other shell config files if they exist
    for rcfile in "$HOME/.bashrc" "$HOME/.profile" "$HOME/.zshrc"; do
        if [[ -f "$rcfile" ]] && ! grep -Fxq "$path_entry" "$rcfile"; then
            echo "$path_entry" >> "$rcfile"
            echo "Added to $rcfile: $new_path"
        fi
    done
}

add_to_shell() {
    local entry="$1"

    echo "Adding to shell: $entry"
    
    if [ -f "$DOTFILES_ZSHRC" ] && ! grep -F -q "$entry" "$DOTFILES_ZSHRC"; then
        echo -e "\n# Added by bootstrap script\n$entry" >> "$DOTFILES_ZSHRC"
        echo "Added to shell config: $entry"
    fi
}


DOTFILES_ZSHRC="$HOME/dotfiles/zsh/dot-zshrc"
add_to_dotfiles_zshrc() {
    local entry="$1"
    entry=$(eval echo "$entry")
    if ! grep -q "$entry" "$DOTFILES_ZSHRC"; then
        echo "$entry" >> "$DOTFILES_ZSHRC"
        echo "Added to zshrc: $entry"
    fi
}

if ! command -v sudo &>/dev/null; then
    apt-get update
    apt-get install -y sudo
fi

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

log() { echo -e "\033[1;34m$1\033[0m"; }
log_success() { echo -e "\033[1;32m$1\033[0m"; }
log_warning() { echo -e "\033[1;33m$1\033[0m"; }
log_error() { echo -e "\033[1;31m$1\033[0m"; }

log "Installing system packages..."
packages=$(yq '.system.packages[]' bootstrap.yaml | tr '\n' ' ')

if [ ! -f /home/liam/.packages_installed ] || ! diff <(echo "$packages" | tr ' ' '\n' | sort) <(sort /home/liam/.packages_installed) >/dev/null; then
    # show the different packages 
    echo "The following packages will be installed:"
    echo "$packages"
    sudo apt-get update
    sudo apt-get install -y $packages
    # Save the list of packages to the file
    echo "$packages" | tr ' ' '\n' > /home/liam/.packages_installed
fi

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

    # Add tool-specific paths
    yq_result=$(yq ".tools.$tool.add_to_path" bootstrap.yaml)
    if [ "$yq_result" != "null" ]; then
        yq ".tools.$tool.add_to_path[]" bootstrap.yaml | while read -r path_entry; do
            if [ ! -z "$path_entry" ]; then
                # Expand any variables in the path
                path_entry=$(eval echo "$path_entry")
                log "Adding $path_entry to PATH..."
                
                # Add to current session
                add_to_path "$path_entry"
                
                # Add to zshrc
                add_to_dotfiles_zshrc "export PATH=\"$path_entry:\$PATH\""
                
                # Verify the path exists
                if [ -d "$path_entry" ]; then
                    log_success "Path $path_entry exists"
                    ls -la "$path_entry"  # Debug: show directory contents
                else
                    log_error "Path $path_entry does not exist!"
                fi
            fi
        done
    fi
    if [ "$(yq ".tools.$tool.add_to_shell" bootstrap.yaml)" != "null" ]; then
        yq ".tools.$tool.add_to_shell[]" bootstrap.yaml | while read -r entry; do
            if [ ! -z "$entry" ]; then
                add_to_shell "$entry"
            fi
        done
    fi
    # Run post-install commands
    if [ "$(yq ".tools.$tool.post_install" bootstrap.yaml)" != "null" ]; then
        yq ".tools.$tool.post_install[]" bootstrap.yaml | while read -r cmd; do
            if [ ! -z "$cmd" ]; then
                log "Running post-install command for $tool: $cmd"
                cmd=$(eval echo "$cmd")
                eval "$cmd"
            fi
        done
    fi

    # Run cleanup commands
    if [ "$(yq ".tools.$tool.cleanup" bootstrap.yaml)" != "null" ]; then
        yq ".tools.$tool.cleanup[]" bootstrap.yaml | while read -r cmd; do
            if [ ! -z "$cmd" ]; then
                log "Running cleanup command for $tool: $cmd"
                cmd=$(eval echo "$cmd")
                eval "$cmd"
            fi
        done
    fi
done





# add to paths
add_to_path "$HOME/.local/bin"
add_to_dotfiles_zshrc "export PATH=\"\$PATH:$HOME/.local/bin\""

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

# Verify locale changes
echo "Final locale settings:"
locale

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
    ./install
fi
# sync nvim plugins
nvim --headless "+Lazy! sync" +qa
if [ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
    log "Installing tmux plugins..."
    $HOME/.tmux/plugins/tpm/bin/install_plugins
fi

log "Bootstrap script completed successfully!"
