#!/bin/bash

set -e

echo "› Installing Zellij"

# Check if Zellij is already installed
if command -v zellij >/dev/null 2>&1; then
    echo "  Zellij is already installed"
    zellij --version
else
    # Install Zellij via Homebrew
    echo "  Installing Zellij via Homebrew..."
    if brew install zellij; then
        echo "  ✅ Zellij installed successfully"
    else
        echo "  ❌ Zellij installation failed"
        exit 1
    fi
fi

# Create ~/.config directory if it doesn't exist
if [ ! -d ~/.config ]; then
    echo "  Creating ~/.config directory"
    if mkdir -p ~/.config; then
        echo "  ✅ ~/.config directory created"
    else
        echo "  ❌ Failed to create ~/.config directory"
        exit 1
    fi
fi

# Create zellij config directory
if [ ! -d ~/.config/zellij ]; then
    echo "  Creating ~/.config/zellij directory"
    if mkdir -p ~/.config/zellij; then
        echo "  ✅ ~/.config/zellij directory created"
    else
        echo "  ❌ Failed to create ~/.config/zellij directory"
        exit 1
    fi
fi

# Check if source config exists
if [ ! -f "$HOME/.dotfiles/zellij/config.kdl" ]; then
    echo "  ❌ Source Zellij config not found: $HOME/.dotfiles/zellij/config.kdl"
    exit 1
fi

# Link Zellij config if it doesn't exist
if [ ! -e ~/.config/zellij/config.kdl ]; then
    echo "  Linking Zellij config"
    if ln -s "$HOME/.dotfiles/zellij/config.kdl" ~/.config/zellij/config.kdl; then
        echo "  ✅ Zellij config linked successfully"
    else
        echo "  ❌ Failed to link Zellij config"
        exit 1
    fi
else
    echo "  Zellij config already exists"
fi

echo "  ✅ Zellij installation and configuration completed"