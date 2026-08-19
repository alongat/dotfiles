#!/bin/bash

set -e

echo "› Setting up herdr configuration"

# Check if source config exists
if [ ! -f "$HOME/.dotfiles/herdr/config.toml" ]; then
    echo "  ❌ Source herdr config not found: $HOME/.dotfiles/herdr/config.toml"
    exit 1
fi

# Create ~/.config/herdr directory if it doesn't exist
if [ ! -d ~/.config/herdr ]; then
    echo "  Creating ~/.config/herdr directory"
    if mkdir -p ~/.config/herdr; then
        echo "  ✅ ~/.config/herdr directory created"
    else
        echo "  ❌ Failed to create ~/.config/herdr directory"
        exit 1
    fi
fi

# Link herdr config if it doesn't exist (and it's not a directory)
if [ ! -e ~/.config/herdr/config.toml ]; then
    echo "  Linking herdr config"
    if ln -s "$HOME/.dotfiles/herdr/config.toml" ~/.config/herdr/config.toml; then
        echo "  ✅ herdr config linked successfully"
    else
        echo "  ❌ Failed to link herdr config"
        exit 1
    fi
else
    echo "  herdr config already exists"
fi

echo "  ✅ herdr configuration setup completed"
