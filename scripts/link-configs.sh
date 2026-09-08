#!/bin/bash
set -e

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
dry_run=false
clean=false
backup_root="$HOME/.local/state/dotfiles/backups/$(date +%Y%m%d-%H%M%S-%N)"

if ! grep -q '^ID=omarchy$' /etc/os-release 2>/dev/null; then
    echo "  ❌ This branch supports Omarchy only"
    exit 1
fi

case "${1:-}" in
    --dry-run) dry_run=true ;;
    --clean) clean=true ;;
    "") ;;
    *) echo "Usage: $0 [--dry-run|--clean]"; exit 1 ;;
esac

links=(
    "$repo_root/bash|$HOME/.config/dotfiles"
    "$repo_root/git/gitconfig.symlink|$HOME/.gitconfig"
    "$repo_root/git/gitignore.symblink|$HOME/.gitignore_global"
    "$repo_root/ssh/config.omarchy|$HOME/.ssh/config"
    "$repo_root/starship/starship.toml|$HOME/.config/starship.toml"
    "$repo_root/zellij/config.kdl|$HOME/.config/zellij/config.kdl"
    "$repo_root/nvim/dotconfig|$HOME/.config/nvim"
    "$repo_root/omarchy/hypr/input.lua|$HOME/.config/hypr/input.lua"
    "$repo_root/omarchy/hypr/monitors.lua|$HOME/.config/hypr/monitors.lua"
    "$repo_root/omarchy/shell.toml|$HOME/.config/omarchy/shell.toml"
)

if $clean; then
    echo "› Removing broken managed symlinks"
    for mapping in "${links[@]}"; do
        destination=${mapping#*|}
        source=${mapping%%|*}
        if [ -L "$destination" ] && [ ! -e "$destination" ] && [ "$(readlink "$destination")" = "$source" ]; then
            echo "  Removing $destination"
            rm "$destination"
        fi
    done
    exit 0
fi

link_path() {
    local source=$1
    local destination=$2
    local current_target=""
    local backup=""

    if [ -L "$destination" ]; then
        current_target=$(readlink -f "$destination" 2>/dev/null || true)
        if [ "$current_target" = "$(readlink -f "$source")" ]; then
            echo "  Already linked: $destination"
            return
        fi
    fi

    if $dry_run; then
        if [ -e "$destination" ] || [ -L "$destination" ]; then
            echo "  Would back up and replace: $destination"
        else
            echo "  Would link: $destination"
        fi
        return
    fi

    mkdir -p "$(dirname "$destination")"
    if [ -e "$destination" ] || [ -L "$destination" ]; then
        backup="$backup_root/${destination#"$HOME"/}"
        mkdir -p "$(dirname "$backup")"
        mv "$destination" "$backup"
        echo "  Backed up: $destination"
    fi

    if ! ln -s "$source" "$destination"; then
        echo "  ❌ Failed to link: $destination"
        if [ -n "$backup" ] && { [ -e "$backup" ] || [ -L "$backup" ]; }; then
            mv "$backup" "$destination"
            echo "  Restored: $destination"
        fi
        return 1
    fi
    echo "  Linked: $destination"
}

# Validate every source before modifying any destination.
for mapping in "${links[@]}"; do
    source=${mapping%%|*}
    if [ ! -e "$source" ]; then
        echo "  ❌ Missing source: $source"
        exit 1
    fi
done

echo "› Linking Omarchy configuration"
for mapping in "${links[@]}"; do
    source=${mapping%%|*}
    destination=${mapping#*|}
    link_path "$source" "$destination"
done

bashrc_line='[[ -r "$HOME/.config/dotfiles/bashrc" ]] && source "$HOME/.config/dotfiles/bashrc"'
if grep -Fqx "$bashrc_line" "$HOME/.bashrc" 2>/dev/null; then
    echo "  Bash loader already configured"
elif $dry_run; then
    echo "  Would add dotfiles loader to $HOME/.bashrc"
else
    printf '\n# Personal Omarchy dotfiles\n%s\n' "$bashrc_line" >> "$HOME/.bashrc"
    echo "  Added dotfiles loader to $HOME/.bashrc"
fi
