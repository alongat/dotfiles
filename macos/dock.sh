#!/bin/bash

set -e

echo "  Setting up Dock..."

if ! command -v dockutil &>/dev/null; then
  echo "  Installing dockutil..."
  brew install dockutil
fi

# Remove all Apple default apps (Launchpad, TV, Music, Podcasts, News, FaceTime, Maps, etc.)
dockutil --remove all --no-restart

# Visual defaults
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock orientation -string bottom

# Add apps that are actually installed — skips missing ones
apps=(
  "/Applications/Ghostty.app"
  "/Applications/WezTerm.app"
  "/Applications/Slack.app"
  "/Applications/zoom.us.app"
  "/Applications/Notion.app"
  "/Applications/Claude.app"
  "/Applications/WhatsApp.app"
)

for app in "${apps[@]}"; do
  if [ -d "$app" ]; then
    dockutil --add "$app" --no-restart
  fi
done

killall Dock

echo "  ✅ Dock configured"
