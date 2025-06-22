#!/bin/bash

set -e

echo "› Setting up Zsh as default shell"

# Check if zsh is installed
if ! command -v zsh >/dev/null 2>&1; then
    echo "  ❌ Zsh is not installed. Please install it first."
    exit 1
fi

# Check current shell
current_shell=$(echo $SHELL)
echo "  Current shell: $current_shell"

# Change shell to zsh if not already set
if [ "$SHELL" != "/bin/zsh" ] && [ "$SHELL" != "/usr/local/bin/zsh" ] && [ "$SHELL" != "/opt/homebrew/bin/zsh" ]; then
    echo "  Changing default shell to zsh..."
    
    # Check if zsh is in /etc/shells
    zsh_path=$(which zsh)
    if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
        echo "  ❌ Zsh ($zsh_path) is not in /etc/shells. You may need to add it manually."
        echo "  Run: echo '$zsh_path' | sudo tee -a /etc/shells"
        exit 1
    fi
    
    if chsh -s "$zsh_path"; then
        echo "  ✅ Default shell changed to zsh successfully"
        echo "  Please restart your terminal or run: exec zsh"
    else
        echo "  ❌ Failed to change default shell to zsh"
        exit 1
    fi
else
    echo "  Zsh is already the default shell"
fi

echo "  ✅ Zsh setup completed"
