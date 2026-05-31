#!/bin/bash
set -e

echo "› Setting up oMLX"

# ── 1. Install macOS menu bar app from GitHub Releases DMG ───────────────────

if [ -d "/Applications/oMLX.app" ]; then
    echo "  oMLX.app already installed (app manages its own updates)"
else
    # Detect macOS major version to pick the right DMG variant
    MACOS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)

    if [ "$MACOS_MAJOR" -ge 26 ]; then
        DMG_SUFFIX="macos26-tahoe"
    elif [ "$MACOS_MAJOR" -eq 15 ]; then
        DMG_SUFFIX="macos15-sequoia"
    else
        echo "  ❌ Unsupported macOS version: $(sw_vers -productVersion). Requires macOS 15 (Sequoia) or later."
        exit 1
    fi

    echo "  Detected macOS $MACOS_MAJOR — using $DMG_SUFFIX DMG variant"

    # Fetch latest release info from GitHub API
    echo "  Fetching latest oMLX release info..."
    RELEASE_JSON=$(curl -sf "https://api.github.com/repos/jundot/omlx/releases/latest")

    RELEASE_TAG=$(echo "$RELEASE_JSON" | jq -r '.tag_name')
    DMG_URL=$(echo "$RELEASE_JSON" | jq -r --arg suffix "$DMG_SUFFIX" \
        '.assets[] | select(.name | contains($suffix)) | .browser_download_url')

    if [ -z "$DMG_URL" ]; then
        echo "  ❌ Could not find DMG asset matching '$DMG_SUFFIX' in release $RELEASE_TAG"
        exit 1
    fi

    DMG_NAME=$(basename "$DMG_URL")
    TMPDIR_OMLX=$(mktemp -d)
    DMG_PATH="$TMPDIR_OMLX/$DMG_NAME"

    echo "  Downloading $DMG_NAME ($RELEASE_TAG)..."
    curl -L --progress-bar -o "$DMG_PATH" "$DMG_URL"

    echo "  Mounting DMG..."
    MOUNT_POINT=$(hdiutil attach "$DMG_PATH" -nobrowse -noautoopen | grep "Apple_HFS\|APFS" | awk '{print $NF}')

    if [ -z "$MOUNT_POINT" ]; then
        echo "  ❌ Failed to mount DMG"
        rm -rf "$TMPDIR_OMLX"
        exit 1
    fi

    echo "  Copying oMLX.app to /Applications..."
    cp -R "$MOUNT_POINT/oMLX.app" /Applications/

    echo "  Unmounting DMG..."
    hdiutil detach "$MOUNT_POINT" -quiet

    rm -rf "$TMPDIR_OMLX"

    if [ -d "/Applications/oMLX.app" ]; then
        echo "  ✅ oMLX.app installed successfully ($RELEASE_TAG)"
    else
        echo "  ❌ oMLX.app installation failed"
        exit 1
    fi
fi

echo "  ✅ oMLX setup completed"
