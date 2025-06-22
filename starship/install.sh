#!/bin/bash

set -e

echo "› Setting up Starship configuration"

# Check if source config exists
if [ ! -f "$HOME/.dotfiles/starship/starship.toml" ]; then
    echo "  ❌ Source Starship config not found: $HOME/.dotfiles/starship/starship.toml"
    exit 1
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

# Link Starship config if it doesn't exist (and it's not a directory)
if [ ! -e ~/.config/starship.toml ]; then
    echo "  Linking Starship config"
    if ln -s "$HOME/.dotfiles/starship/starship.toml" ~/.config/starship.toml; then
        echo "  ✅ Starship config linked successfully"
    else
        echo "  ❌ Failed to link Starship config"
        exit 1
    fi
else
    echo "  Starship config already exists"
fi

echo "  ✅ Starship configuration setup completed"
