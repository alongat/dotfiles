#!/bin/bash

set -e

echo "🚀 Installing Gemini CLI..."

check_node() {
    if ! command -v node &> /dev/null; then
        echo "❌ Node.js is not installed"
        echo "Please install Node.js version 20 or higher from https://nodejs.org/"
        exit 1
    fi
    
    NODE_VERSION=$(node --version | cut -d 'v' -f 2 | cut -d '.' -f 1)
    if [ "$NODE_VERSION" -lt 20 ]; then
        echo "❌ Node.js version $NODE_VERSION is too old"
        echo "Please upgrade to Node.js version 20 or higher"
        exit 1
    fi
    
    echo "✅ Node.js version $(node --version) detected"
}

install_gemini_cli() {
    echo "📦 Installing Gemini CLI globally..."
    
    # Check if pnpm is available and use it, otherwise use npm
    if command -v pnpm &> /dev/null; then
        echo "Using pnpm for installation..."
        pnpm install -g @google/gemini-cli
    else
        npm install -g @google/gemini-cli
    fi
    
    if command -v gemini &> /dev/null; then
        echo "✅ Gemini CLI installed successfully"
    else
        echo "❌ Installation failed - gemini command not found in PATH"
        echo "You may need to add the global bin directory to your PATH"
        exit 1
    fi
}

main() {
    check_node
    install_gemini_cli
}

main "$@"