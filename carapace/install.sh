#!/bin/bash

set -e

echo "› Installing Carapace"

# Check if Carapace is already installed
if command -v carapace >/dev/null 2>&1; then
    echo "  Carapace is already installed"
    carapace --version
else
    # Install Carapace via Homebrew
    echo "  Installing Carapace via Homebrew..."
    if brew install carapace; then
        echo "  ✅ Carapace installed successfully"
    else
        echo "  ❌ Carapace installation failed"
        exit 1
    fi
fi

# Check what shell is being used
if [ -n "$ZSH_VERSION" ] || [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_TYPE="zsh"
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ] || [[ "$SHELL" == *"bash"* ]]; then
    SHELL_TYPE="bash"
    SHELL_CONFIG="$HOME/.bashrc"
else
    echo "  ❌ Unsupported shell. Carapace supports bash and zsh."
    exit 1
fi

echo "  Detected shell: $SHELL_TYPE"

# Check if carapace is already sourced in shell config
CARAPACE_LINE="source <(carapace _carapace)"
if [ -f "$SHELL_CONFIG" ] && grep -q "carapace _carapace" "$SHELL_CONFIG"; then
    echo "  Carapace is already configured in $SHELL_CONFIG"
else
    echo "  Adding Carapace to $SHELL_CONFIG"
    if [ ! -f "$SHELL_CONFIG" ]; then
        touch "$SHELL_CONFIG"
    fi
    
    echo "" >> "$SHELL_CONFIG"
    echo "# Carapace autocompletion" >> "$SHELL_CONFIG"
    echo "$CARAPACE_LINE" >> "$SHELL_CONFIG"
    echo "  ✅ Carapace configuration added to $SHELL_CONFIG"
fi

echo "  ✅ Carapace installation and configuration completed"
echo "  💡 Restart your shell or run 'source $SHELL_CONFIG' to enable completions"