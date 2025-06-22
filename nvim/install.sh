#!/bin/bash

set -e

echo "› Setting up Neovim configuration"

# Check if source config exists
if [ ! -d "$HOME/.dotfiles/nvim/dotconfig" ]; then
    echo "  ❌ Source Neovim config not found: $HOME/.dotfiles/nvim/dotconfig"
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

# Link Neovim config if it doesn't exist
if [ ! -e ~/.config/nvim ]; then
    echo "  Linking Neovim config"
    if ln -s "$HOME/.dotfiles/nvim/dotconfig" ~/.config/nvim; then
        echo "  ✅ Neovim config linked successfully"
    else
        echo "  ❌ Failed to link Neovim config"
        exit 1
    fi
else
    echo "  Neovim config already exists"
fi

echo "  ✅ Neovim configuration setup completed"
