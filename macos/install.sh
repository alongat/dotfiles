#!/bin/bash

set -e

echo "› Setting up macOS configuration"

# Check if running on macOS
if [ "$(uname)" != "Darwin" ]; then
    echo "  Skipping macOS setup (not running on macOS)"
    exit 0
fi

echo "  Running macOS software update..."
if sudo softwareupdate -i -a; then
    echo "  ✅ Software update completed"
else
    echo "  ⚠️ Software update failed or no updates available"
fi

# Run defaults script
defaults_script="$(dirname "$0")/defaults.sh"
if [ -f "$defaults_script" ]; then
    echo "  Running macOS defaults configuration..."
    if "$defaults_script"; then
        echo "  ✅ macOS defaults configured successfully"
    else
        echo "  ❌ Failed to configure macOS defaults"
        exit 1
    fi
else
    echo "  ⚠️ defaults.sh not found, skipping"
fi

# Setup Dock
dock_script="$(dirname "$0")/dock.sh"
if [ -f "$dock_script" ]; then
    echo "  Running Dock configuration..."
    if "$dock_script"; then
        echo "  ✅ Dock configured successfully"
    else
        echo "  ⚠️ Dock configuration failed (non-fatal)"
    fi
fi

echo "  ✅ macOS configuration completed"

