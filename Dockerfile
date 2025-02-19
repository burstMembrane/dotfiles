# Use a specific version for better reproducibility
FROM ubuntu:latest

# Define build argument for packages
ARG PACKAGES="\
    curl \
    sudo \
    build-essential \
    git \
    wget \
    unzip \
    zsh \
    tmux \
    ripgrep \
    bat \
    vim \
    fd-find \
    fonts-powerline \
    locales \
    less \
    python3 \
    python3-pip \
    python-is-python3 \
    dpkg \
    apt-utils" 

# Combine all ENV statements to reduce layers
ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/usr/local/bin:${PATH}"

# Install essential packages in a single layer
RUN apt-get update && apt-get install -y ${PACKAGES} \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash liam \
    && echo "liam ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers  \
    && sudo mkdir -p /opt \
    && sudo chown -R liam:liam /opt

# Switch to non-root user for security
USER liam
WORKDIR /home/liam

# Save package list to file
RUN echo "${PACKAGES}" | tr ' ' '\n' | grep -v '^$' > /home/liam/.packages_installed

# Copy all files at once to avoid cache invalidation
COPY --chown=liam:liam . /home/liam/dotfiles/
WORKDIR /home/liam/dotfiles

# Make script executable and run bootstrap

RUN chmod +x bootstrap-ubuntu.sh && ./bootstrap-ubuntu.sh
# Set the locale

RUN sudo sed -i '/en_AU.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG=en_AU.UTF-8 LANGUAGE=en_AU:en LC_ALL=en_AU.UTF-8
# Set zsh as default shell
SHELL ["/bin/zsh", "-c"]
# Default command when container starts
CMD ["/bin/zsh"]
