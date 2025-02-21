#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

USERNAME="liam"

# Create user with home directory if they don't exist
if ! id "$USERNAME" &>/dev/null; then
    useradd -m -s /bin/bash "$USERNAME"
    echo "User $USERNAME created."
else
    echo "User $USERNAME already exists."
fi

# Set correct permissions for home directory
chmod 700 /home/$USERNAME
chown -R $USERNAME:$USERNAME /home/$USERNAME
echo "Permissions set for /home/$USERNAME"

# Switch to the new user
su - "$USERNAME"
