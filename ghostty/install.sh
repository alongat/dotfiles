#!/bin/bash

set -e

echo "› Setting up Ghostty configuration"

# Check if source config exists
if [ ! -f "$HOME/.dotfiles/ghostty/config" ]; then
    echo "  ❌ Source Ghostty config not found: $HOME/.dotfiles/ghostty/config"
    exit 1
fi

# Create .config/ghostty directory if it doesn't exist
if [ ! -d ~/.config/ghostty ]; then
    echo "  Creating ~/.config/ghostty directory"
    mkdir -p ~/.config/ghostty
fi

# Link Ghostty config if it doesn't exist
if [ ! -e ~/.config/ghostty/config ]; then
    echo "  Linking Ghostty config"
    if ln -s "$HOME/.dotfiles/ghostty/config" ~/.config/ghostty/config; then
        echo "  ✅ Ghostty config linked successfully"
    else
        echo "  ❌ Failed to link Ghostty config"
        exit 1
    fi
else
    echo "  Ghostty config already exists"
fi

echo "  ✅ Ghostty configuration setup completed"