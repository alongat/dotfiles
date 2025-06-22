#!/bin/bash

set -e

echo "› Installing Homebrew"

# Check if Homebrew is already installed
if command -v brew >/dev/null 2>&1; then
    echo "  Homebrew is already installed"
    brew --version
    exit 0
fi

# Install Homebrew
echo "  Downloading and installing Homebrew..."
if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    echo "  ✅ Homebrew installed successfully"
else
    echo "  ❌ Homebrew installation failed"
    exit 1
fi

# Verify installation
if command -v brew >/dev/null 2>&1; then
    echo "  ✅ Homebrew verification successful"
    brew --version
else
    echo "  ❌ Homebrew installation verification failed"
    exit 1
fi
