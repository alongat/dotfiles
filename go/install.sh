#!/bin/bash

set -e

echo "› Installing Go packages"

# Go packages to install
readonly PACKAGES=(
	golang.org/x/tools/gopls@latest
	github.com/bufbuild/buf-language-server/cmd/bufls@latest
	github.com/go-delve/delve/cmd/dlv@latest
)

# Check if Go is installed
if ! command -v go >/dev/null 2>&1; then
    echo "  ❌ Go is not installed. Please install Go first."
    exit 1
fi

echo "  Go version: $(go version)"

# Install packages
install_count=0
failed_count=0

for pkg in "${PACKAGES[@]}"; do
    echo "  Installing $pkg"
    if go install "$pkg"; then
        echo "    ✅ Successfully installed $pkg"
        install_count=$((install_count + 1))
    else
        echo "    ❌ Failed to install $pkg"
        failed_count=$((failed_count + 1))
    fi
done

echo "› Go packages installation completed: $install_count succeeded, $failed_count failed"

if [ $failed_count -gt 0 ]; then
    echo "  Some packages failed to install. Check the output above for details."
    exit 1
fi
