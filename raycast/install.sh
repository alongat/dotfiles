#!/bin/bash

set -e

echo ": Setting up Raycast configuration"

# Check if Raycast is installed
if ! command -v raycast >/dev/null 2>&1 && [ ! -d "/Applications/Raycast.app" ]; then
    echo "    Raycast is not installed. Install it via Homebrew cask or App Store."
    echo "  Run: brew install --cask raycast"
    exit 0
fi

echo "  Raycast is installed"

# Note: Raycast configurations are typically managed through the app itself
# This script serves as a placeholder for any future Raycast setup automation

echo "  =¡ Configure Raycast manually through the app settings"
echo "   Raycast setup completed"