#!/bin/bash

set -e

echo "› Setting up WezTerm configuration"

# Check if source config exists
if [ ! -f "$HOME/.dotfiles/wezterm/.wezterm.lua" ]; then
    echo "  ❌ Source WezTerm config not found: $HOME/.dotfiles/wezterm/.wezterm.lua"
    exit 1
fi

# Link WezTerm config if it doesn't exist
if [ ! -e ~/.wezterm.lua ]; then
    echo "  Linking WezTerm config"
    if ln -s "$HOME/.dotfiles/wezterm/.wezterm.lua" ~/.wezterm.lua; then
        echo "  ✅ WezTerm config linked successfully"
    else
        echo "  ❌ Failed to link WezTerm config"
        exit 1
    fi
else
    echo "  WezTerm config already exists"
fi

echo "  ✅ WezTerm configuration setup completed"
