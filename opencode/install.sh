#!/bin/bash

set -e

echo "› Setting up OpenCode configuration"

# Check if source config exists
if [ ! -f "$HOME/.dotfiles/opencode/opencode.json" ]; then
    echo "  ❌ Source OpenCode config not found: $HOME/.dotfiles/opencode/opencode.json"
    exit 1
fi

# Decrypt AGENTS.md if encrypted version exists and plaintext doesn't
if [ -f "$HOME/.dotfiles/opencode/AGENTS.md.enc" ] && [ ! -f "$HOME/.dotfiles/opencode/AGENTS.md" ]; then
    echo "  Decrypting AGENTS.md..."
    if openssl enc -aes-256-cbc -pbkdf2 -d -in "$HOME/.dotfiles/opencode/AGENTS.md.enc" -out "$HOME/.dotfiles/opencode/AGENTS.md" 2>/dev/null; then
        echo "  ✅ AGENTS.md decrypted successfully"
    else
        echo "  ❌ Failed to decrypt AGENTS.md (wrong password or corrupted file)"
        echo "  Continuing with installation..."
    fi
fi

if [ ! -f "$HOME/.dotfiles/opencode/AGENTS.md" ]; then
    echo "  ❌ Source OpenCode AGENTS.md not found: $HOME/.dotfiles/opencode/AGENTS.md"
    exit 1
fi

# Create ~/.config/opencode directory if it doesn't exist
if [ ! -d ~/.config/opencode ]; then
    echo "  Creating ~/.config/opencode directory"
    mkdir -p ~/.config/opencode
fi

# Link opencode.json if it doesn't exist
if [ ! -e ~/.config/opencode/opencode.json ]; then
    echo "  Linking opencode.json"
    if ln -s "$HOME/.dotfiles/opencode/opencode.json" ~/.config/opencode/opencode.json; then
        echo "  ✅ opencode.json linked successfully"
    else
        echo "  ❌ Failed to link opencode.json"
        exit 1
    fi
else
    echo "  opencode.json already exists"
fi

# Link AGENTS.md if it doesn't exist
if [ ! -e ~/.config/opencode/AGENTS.md ]; then
    echo "  Linking AGENTS.md"
    if ln -s "$HOME/.dotfiles/opencode/AGENTS.md" ~/.config/opencode/AGENTS.md; then
        echo "  ✅ AGENTS.md linked successfully"
    else
        echo "  ❌ Failed to link AGENTS.md"
        exit 1
    fi
else
    echo "  AGENTS.md already exists"
fi

# Link plugin directory if it doesn't exist
if [ ! -e ~/.config/opencode/plugin ]; then
    echo "  Linking plugin directory"
    if ln -s "$HOME/.dotfiles/opencode/plugin" ~/.config/opencode/plugin; then
        echo "  ✅ plugin directory linked successfully"
    else
        echo "  ❌ Failed to link plugin directory"
        exit 1
    fi
else
    echo "  plugin directory already exists"
fi

echo "  ✅ OpenCode configuration setup completed"
