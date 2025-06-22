#!/bin/bash

set -e

echo "› Setting up SSH configuration"

# Check if source config exists
if [ ! -f "$HOME/.dotfiles/ssh/config" ]; then
    echo "  ❌ Source SSH config not found: $HOME/.dotfiles/ssh/config"
    exit 1
fi

# Create ~/.ssh directory if it doesn't exist
if [ ! -d ~/.ssh ]; then
    echo "  Creating ~/.ssh directory"
    mkdir -p ~/.ssh || { echo "  ❌ Failed to create ~/.ssh directory"; exit 1; }
    chmod 700 ~/.ssh
fi

# Link SSH config if it doesn't exist
if [ ! -e ~/.ssh/config ]; then
    echo "  Linking SSH config"
    if ln -s "$HOME/.dotfiles/ssh/config" ~/.ssh/config; then
        echo "  ✅ SSH config linked successfully"
    else
        echo "  ❌ Failed to link SSH config"
        exit 1
    fi
else
    echo "  SSH config already exists"
fi

# Set proper permissions
chmod 600 ~/.ssh/config 2>/dev/null || true
echo "  ✅ SSH configuration setup completed"
