#!/bin/bash
set -e

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
dry_run=false

if [ "${1:-}" = "--dry-run" ]; then
    dry_run=true
    shift
fi

if [ "$#" -eq 0 ]; then
    set -- core
fi

if ! command -v omarchy >/dev/null 2>&1; then
    echo "  ❌ Omarchy CLI not found"
    exit 1
fi

read_packages() {
    local manifest=$1
    while IFS= read -r line || [ -n "$line" ]; do
        line=${line%%#*}
        line=${line//[[:space:]]/}
        [ -n "$line" ] && printf '%s\n' "$line"
    done < "$manifest"
}

# Validate every requested group before installing any packages.
for group in "$@"; do
    if [ ! -f "$repo_root/packages/$group.txt" ]; then
        echo "  ❌ Unknown package group: $group"
        exit 1
    fi
done

for group in "$@"; do
    manifest="$repo_root/packages/$group.txt"
    mapfile -t packages < <(read_packages "$manifest")
    [ "${#packages[@]}" -gt 0 ] || continue

    echo "› Package group: $group"
    if $dry_run; then
        printf '  Would ensure: %s\n' "${packages[*]}"
    elif [ "$group" = "aur" ]; then
        omarchy pkg aur add "${packages[@]}"
    else
        omarchy pkg add "${packages[@]}"
    fi
done
