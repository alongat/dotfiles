#!/bin/bash

set -e

echo "› Installing Claude Code"

# Check if Claude Code is already installed
if command -v claude &> /dev/null; then
    echo "  Claude Code is already installed"
    claude --version
    exit 0
fi

# Check if npm is available
if ! command -v npm &> /dev/null; then
    echo "  ❌ npm is not installed. Please install Node.js first."
    exit 1
fi

# Install Claude Code using npm
echo "  Installing Claude Code via npm..."
npm install -g @anthropic-ai/claude-code

# Verify installation
if command -v claude &> /dev/null; then
    echo "  ✅ Claude Code installed successfully"
    claude --version
else
    echo "  ❌ Claude Code installation failed"
    exit 1
fi

echo "  💡 Run 'claude auth login' to authenticate with your Anthropic account"