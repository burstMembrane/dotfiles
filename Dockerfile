# Use the latest Ubuntu as the base image
FROM ubuntu:latest

# Set noninteractive mode for apt to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Update and install required dependencies
RUN apt update && apt install -y \
    curl \
    git \
    unzip \
    rar \
    zsh \
    tmux \
    fzf \
    ripgrep \
    bat \
    exa \
    build-essential

# Copy the bootstrap script into the container
COPY ./bootstrap-ubuntu.sh /bootstrap.sh

# Make the script executable and run it
RUN chmod +x /bootstrap.sh && /bootstrap.sh

# Switch to zsh for testing
CMD ["/bin/zsh"]
