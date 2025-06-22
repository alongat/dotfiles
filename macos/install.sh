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

# Setup sudo_local for Touch ID
sudo_template="$(dirname "$0")/sudo_local.template"
if [ -f "$sudo_template" ]; then
    if [ ! -f /etc/pam.d/sudo_local ]; then
        echo "  Setting up Touch ID for sudo..."
        if sudo cp "$sudo_template" /etc/pam.d/sudo_local; then
            echo "  ✅ Touch ID for sudo configured successfully"
        else
            echo "  ❌ Failed to configure Touch ID for sudo"
            exit 1
        fi
    else
        echo "  Touch ID for sudo already configured"
    fi
else
    echo "  ⚠️ sudo_local.template not found, skipping Touch ID setup"
fi

echo "  ✅ macOS configuration completed"

