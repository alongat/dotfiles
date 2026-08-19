#!/bin/bash
set -e

echo "› Installing plannotator CLI"

if command -v plannotator &>/dev/null; then
    echo "  plannotator already installed at $(which plannotator)"
    echo "  ✅ Installation skipped"
    exit 0
fi

if ! command -v git &>/dev/null; then
    echo "  ❌ git not found — please install git before running this script"
    exit 1
fi

echo "  Running installer..."
curl -fsSL https://plannotator.ai/install.sh | bash -s -- --non-interactive
echo "  ✅ Installation complete"
