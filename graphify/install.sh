#!/bin/bash

set -e

echo "› Installing Graphify (knowledge graph for AI agents)"

if command -v graphify &>/dev/null; then
    echo "  graphify already installed at $(which graphify)"
    echo "  ✅ Graphify installation skipped (already present)"
    exit 0
fi

if command -v uv &>/dev/null; then
    echo "  Installing graphifyy via uv..."
    uv tool install graphifyy
    echo "  ✅ Graphify installed successfully"
elif command -v pipx &>/dev/null; then
    echo "  Installing graphifyy via pipx..."
    pipx install graphifyy
    echo "  ✅ Graphify installed successfully"
else
    echo "  ❌ Neither uv nor pipx found. Install uv with: make packages PACKAGE_GROUPS=development"
    exit 1
fi
