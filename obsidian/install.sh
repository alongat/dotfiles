#!/bin/bash

set -e

ICLOUD_VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/obsidian-second-brain"
VAULT_LINK="$HOME/.obsidian-vault"

echo "› Setting up Obsidian vault symlink"

if [ ! -d "$ICLOUD_VAULT" ]; then
    echo "  ⚠️  Obsidian vault not found in iCloud: $ICLOUD_VAULT"
    echo "     Skipping ~/.obsidian-vault symlink creation"
    exit 0
fi

if [ -L "$VAULT_LINK" ]; then
    echo "  ~/.obsidian-vault already linked"
elif [ -e "$VAULT_LINK" ]; then
    echo "  ❌ ~/.obsidian-vault exists but is not a symlink — please remove it manually"
    exit 1
else
    ln -s "$ICLOUD_VAULT" "$VAULT_LINK"
    echo "  ✅ ~/.obsidian-vault linked to iCloud vault"
fi
