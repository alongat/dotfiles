#!/bin/bash

set -e

echo "› Installing Linkerd CLI"

# Check if Linkerd is already installed
if command -v linkerd >/dev/null 2>&1; then
    echo "  Linkerd CLI is already installed"
    linkerd version --client
    exit 0
fi

# Install Linkerd CLI
echo "  Downloading and installing Linkerd CLI..."
if curl -sL https://run.linkerd.io/install | sh; then
    echo "  ✅ Linkerd CLI installed successfully"
else
    echo "  ❌ Linkerd CLI installation failed"
    exit 1
fi

# Add to PATH if needed
if [ -f "$HOME/.linkerd2/bin/linkerd" ] && [[ ":$PATH:" != *":$HOME/.linkerd2/bin:"* ]]; then
    echo "  Adding Linkerd to PATH in current session"
    export PATH="$HOME/.linkerd2/bin:$PATH"
fi

# Verify installation
if command -v linkerd >/dev/null 2>&1; then
    echo "  ✅ Linkerd CLI verification successful"
    linkerd version --client
else
    echo "  ❌ Linkerd CLI installation verification failed"
    echo "  You may need to add ~/.linkerd2/bin to your PATH"
    exit 1
fi
