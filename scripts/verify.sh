#!/bin/bash
set -e

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
errors=0
scripts_only=false

if [ "${1:-}" = "--scripts-only" ]; then
    scripts_only=true
elif [ "$#" -gt 0 ]; then
    echo "Usage: $0 [--scripts-only]"
    exit 1
fi

echo "› Checking Bash syntax"
while IFS= read -r script; do
    if ! bash -n "$script"; then
        errors=$((errors + 1))
    fi
done < <(printf '%s\n' "$repo_root/install.sh" "$repo_root"/scripts/*.sh "$repo_root"/bash/*.bash)

echo "› Checking interactive Bash configuration"
if ! DOTFILES_TEST_ROOT="$repo_root" bash --noprofile --norc -e -ic \
    'source "$DOTFILES_TEST_ROOT/bash/bashrc"; declare -F pubkey >/dev/null; declare -F fedit >/dev/null; alias kc >/dev/null' \
    >/dev/null 2>&1; then
    echo "  ❌ Bash configuration failed to load"
    errors=$((errors + 1))
fi

if command -v shellcheck >/dev/null 2>&1; then
    echo "› Checking scripts with ShellCheck"
    shellcheck "$repo_root/install.sh" "$repo_root"/scripts/*.sh "$repo_root"/bash/*.bash || errors=$((errors + 1))
fi

if $scripts_only; then
    if [ "$errors" -gt 0 ]; then
        exit 1
    fi
    echo "› Script validation completed successfully"
    exit 0
fi

echo "› Checking managed links"
expected_links=(
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

for mapping in "${expected_links[@]}"; do
    source=${mapping%%|*}
    destination=${mapping#*|}
    if [ -L "$destination" ] && [ "$(readlink -f "$destination")" = "$(readlink -f "$source")" ]; then
        echo "  ✅ $destination"
    else
        echo "  ❌ $destination"
        errors=$((errors + 1))
    fi
done

bashrc_line='[[ -r "$HOME/.config/dotfiles/bashrc" ]] && source "$HOME/.config/dotfiles/bashrc"'
if ! grep -Fqx "$bashrc_line" "$HOME/.bashrc" 2>/dev/null; then
    echo "  ❌ Bash loader is not configured"
    errors=$((errors + 1))
fi

if command -v hyprctl >/dev/null 2>&1 && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    echo "› Validating Hyprland configuration"
    hyprctl reload >/dev/null || errors=$((errors + 1))
    if ! config_errors=$(hyprctl configerrors); then
        errors=$((errors + 1))
    elif [ -n "$config_errors" ]; then
        echo "$config_errors"
        errors=$((errors + 1))
    fi
fi

if [ "$errors" -gt 0 ]; then
    echo "› Verification failed with $errors issue(s)"
    exit 1
fi

echo "› Verification completed successfully"
