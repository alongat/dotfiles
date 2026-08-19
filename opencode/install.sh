#!/bin/bash

set -e

# ---------------------------------------------------------------------------
# Usage: install.sh [--verify]
#   --verify   Check all symlinks are valid without making changes
# ---------------------------------------------------------------------------

VERIFY_ONLY=false
if [ "${1:-}" = "--verify" ]; then
    VERIFY_ONLY=true
fi

OBSIDIAN_VAULT="$HOME/.obsidian-vault"
VAULT_COMMANDS="$OBSIDIAN_VAULT/Skills/commands"
COMMANDS_DIR="$HOME/.config/opencode/commands"
VAULT_SKILLS="$OBSIDIAN_VAULT/Skills/skills"
SKILLS_DIR="$HOME/.config/opencode/skills"
OBSIDIAN_SKILLS_DIR="$SKILLS_DIR/obsidian-skills"

# ---------------------------------------------------------------------------
# Helper: detect circular/self-referential symlinks (iCloud dehydration artifact)
# Returns 0 (true) if symlink is circular, 1 otherwise
# ---------------------------------------------------------------------------
is_circular_symlink() {
    local path="$1"
    [ ! -L "$path" ] && return 1
    local target
    target=$(readlink "$path")
    # Circular if target == path itself, or reading it causes ELOOP
    if [ "$target" = "$path" ]; then
        return 0
    fi
    # Try to stat the resolved target; ELOOP means circular
    if ! stat -f "%N" "$path" >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# ---------------------------------------------------------------------------
# --verify mode: check all symlinks and report issues
# ---------------------------------------------------------------------------
if $VERIFY_ONLY; then
    echo "› Verifying OpenCode symlinks"
    ERRORS=0

    # Commands
    if [ -d "$COMMANDS_DIR" ]; then
        for cmd in "$COMMANDS_DIR"/*.md; do
            [ -e "$cmd" ] || continue
            name=$(basename "$cmd")
            if is_circular_symlink "$cmd"; then
                echo "  ❌ CIRCULAR symlink (iCloud artifact): commands/$name"
                ERRORS=$((ERRORS + 1))
            elif [ -L "$cmd" ] && [ ! -e "$cmd" ]; then
                echo "  ❌ BROKEN symlink: commands/$name → $(readlink "$cmd")"
                ERRORS=$((ERRORS + 1))
            else
                echo "  ✅ commands/$name"
            fi
        done
    else
        echo "  ⚠️  Commands dir not found: $COMMANDS_DIR"
    fi

    # Skills
    if [ -d "$SKILLS_DIR" ]; then
        for skill in "$SKILLS_DIR"/*/; do
            name=$(basename "$skill")
            if is_circular_symlink "${skill%/}"; then
                echo "  ❌ CIRCULAR symlink (iCloud artifact): skills/$name"
                ERRORS=$((ERRORS + 1))
            elif [ -L "${skill%/}" ] && [ ! -e "${skill%/}" ]; then
                echo "  ❌ BROKEN symlink: skills/$name → $(readlink "${skill%/}")"
                ERRORS=$((ERRORS + 1))
            else
                echo "  ✅ skills/$name"
            fi
        done
    else
        echo "  ⚠️  Skills dir not found: $SKILLS_DIR"
    fi

    # plugins directory
    PLUGINS_TARGET="$HOME/.config/opencode/plugins"
    if [ -L "$PLUGINS_TARGET" ] && [ -e "$PLUGINS_TARGET" ]; then
        echo "  ✅ plugins → $(readlink "$PLUGINS_TARGET")"
    elif [ -L "$PLUGINS_TARGET" ]; then
        echo "  ❌ BROKEN symlink: plugins → $(readlink "$PLUGINS_TARGET")"
        ERRORS=$((ERRORS + 1))
    elif [ -d "$PLUGINS_TARGET" ]; then
        echo "  ⚠️  plugins is a plain directory, not a symlink — run install.sh to repair"
        ERRORS=$((ERRORS + 1))
    else
        echo "  ❌ plugins missing"
        ERRORS=$((ERRORS + 1))
    fi

    # tools directory
    TOOLS_TARGET="$HOME/.config/opencode/tools"
    if [ -L "$TOOLS_TARGET" ] && [ -e "$TOOLS_TARGET" ]; then
        echo "  ✅ tools → $(readlink "$TOOLS_TARGET")"
    elif [ -L "$TOOLS_TARGET" ]; then
        echo "  ❌ BROKEN symlink: tools → $(readlink "$TOOLS_TARGET")"
        ERRORS=$((ERRORS + 1))
    elif [ -d "$TOOLS_TARGET" ]; then
        echo "  ⚠️  tools is a plain directory, not a symlink — run install.sh to repair"
        ERRORS=$((ERRORS + 1))
    else
        echo "  ❌ tools missing"
        ERRORS=$((ERRORS + 1))
    fi

    if [ "$ERRORS" -eq 0 ]; then
        echo ""
        echo "  All symlinks OK"
    else
        echo ""
        echo "  $ERRORS issue(s) found. Run install.sh (without --verify) to repair."
    fi
    exit 0
fi

# ---------------------------------------------------------------------------
# Normal install mode
# ---------------------------------------------------------------------------

echo "› Setting up OpenCode configuration"

# Check if source config exists
if [ ! -f "$HOME/.dotfiles/opencode/opencode.json" ]; then
    echo "  ❌ Source OpenCode config not found: $HOME/.dotfiles/opencode/opencode.json"
    exit 1
fi

# Decrypt AGENTS.md if encrypted version exists and plaintext doesn't
if [ -f "$HOME/.dotfiles/opencode/AGENTS.md.enc" ] && [ ! -f "$HOME/.dotfiles/opencode/AGENTS.md" ]; then
    echo "  Decrypting AGENTS.md..."
    if openssl enc -aes-256-cbc -pbkdf2 -d -in "$HOME/.dotfiles/opencode/AGENTS.md.enc" -out "$HOME/.dotfiles/opencode/AGENTS.md" 2>/dev/null; then
        echo "  ✅ AGENTS.md decrypted successfully"
    else
        echo "  ❌ Failed to decrypt AGENTS.md (wrong password or corrupted file)"
        echo "  Continuing with installation..."
    fi
fi

if [ ! -f "$HOME/.dotfiles/opencode/AGENTS.md" ]; then
    echo "  ❌ Source OpenCode AGENTS.md not found: $HOME/.dotfiles/opencode/AGENTS.md"
    exit 1
fi

# Create ~/.config/opencode directory if it doesn't exist
if [ ! -d ~/.config/opencode ]; then
    echo "  Creating ~/.config/opencode directory"
    mkdir -p ~/.config/opencode
fi

# Link opencode.json if it doesn't exist
if [ ! -e ~/.config/opencode/opencode.json ]; then
    echo "  Linking opencode.json"
    if ln -s "$HOME/.dotfiles/opencode/opencode.json" ~/.config/opencode/opencode.json; then
        echo "  ✅ opencode.json linked successfully"
    else
        echo "  ❌ Failed to link opencode.json"
        exit 1
    fi
else
    echo "  opencode.json already exists"
fi

# Link AGENTS.md if it doesn't exist
if [ ! -e ~/.config/opencode/AGENTS.md ]; then
    echo "  Linking AGENTS.md"
    if ln -s "$HOME/.dotfiles/opencode/AGENTS.md" ~/.config/opencode/AGENTS.md; then
        echo "  ✅ AGENTS.md linked successfully"
    else
        echo "  ❌ Failed to link AGENTS.md"
        exit 1
    fi
else
    echo "  AGENTS.md already exists"
fi

# Link plugins directory (auto-discovered by opencode at startup)
# If a plain directory exists from a prior ad-hoc setup, replace it with a symlink.
if [ -d ~/.config/opencode/plugins ] && [ ! -L ~/.config/opencode/plugins ]; then
    echo "  Replacing plain plugins/ directory with symlink"
    rm -rf ~/.config/opencode/plugins
fi
if [ ! -e ~/.config/opencode/plugins ]; then
    echo "  Linking plugins directory"
    if ln -s "$HOME/.dotfiles/opencode/plugins" ~/.config/opencode/plugins; then
        echo "  ✅ plugins directory linked successfully"
    else
        echo "  ❌ Failed to link plugins directory"
        exit 1
    fi
else
    echo "  plugins directory already linked"
fi

# Link tools directory (auto-discovered by opencode at startup)
# If a plain directory exists from a prior ad-hoc setup, replace it with a symlink.
if [ -d ~/.config/opencode/tools ] && [ ! -L ~/.config/opencode/tools ]; then
    echo "  Replacing plain tools/ directory with symlink"
    rm -rf ~/.config/opencode/tools
fi
if [ ! -e ~/.config/opencode/tools ]; then
    echo "  Linking tools directory"
    if ln -s "$HOME/.dotfiles/opencode/tools" ~/.config/opencode/tools; then
        echo "  ✅ tools directory linked successfully"
    else
        echo "  ❌ Failed to link tools directory"
        exit 1
    fi
else
    echo "  tools directory already linked"
fi

# Remove legacy stale plugin (singular) file if it exists
if [ -f ~/.config/opencode/plugin ] && [ ! -L ~/.config/opencode/plugin ]; then
    echo "  Removing stale plugin file (legacy artifact)"
    rm ~/.config/opencode/plugin
fi

# Check for .env secrets file (may be a regular file, symlink, or a named
# pipe fed by a 1Password-backed process — use -e so any of those count as present)
if [ ! -e "$HOME/.dotfiles/opencode/.env" ]; then
    echo ""
    echo "  ⚠️  Missing secrets file: ~/.dotfiles/opencode/.env"
    echo "  Copying .env.example as a starting point..."
    cp "$HOME/.dotfiles/opencode/.env.example" "$HOME/.dotfiles/opencode/.env"
    echo "  ✏️  Fill in the values in ~/.dotfiles/opencode/.env:"
    echo "       JELLYFISH_API_TOKEN — from Jellyfish settings"
    echo "       MCP_SLACK_URL       — from mcptotal dashboard"
    echo "       MCP_GDRIVE_URL      — from mcptotal dashboard"
    echo ""
else
    echo "  .env secrets file present"
fi

echo "  ✅ OpenCode configuration setup completed"

# ---------------------------------------------------------------------------
# Vault commands — symlink from Obsidian vault (source of truth)
# Detects and repairs circular symlinks caused by iCloud dehydration
# ---------------------------------------------------------------------------

if [ -d "$VAULT_COMMANDS" ]; then
    echo "› Setting up OpenCode commands"
    mkdir -p "$COMMANDS_DIR"
    for cmd in "$VAULT_COMMANDS"/*.md; do
        # glob may not match anything
        [ -e "$cmd" ] || [ -L "$cmd" ] || continue
        name=$(basename "$cmd")
        target="$COMMANDS_DIR/$name"

        # Detect and warn about circular source symlinks (iCloud artifact)
        if is_circular_symlink "$cmd"; then
            echo "  ⚠️  CIRCULAR symlink in vault (iCloud artifact): $name"
            echo "     The file content is missing. Restore from Time Machine or recreate."
            echo "     Skipping link creation for $name"
            continue
        fi

        # Replace plain file copies or circular targets with proper symlinks
        if [ -L "$target" ] && is_circular_symlink "$target"; then
            echo "  Repairing circular symlink: $name"
            rm "$target"
        elif [ -f "$target" ] && [ ! -L "$target" ]; then
            echo "  Replacing copy with symlink: $name"
            rm "$target"
        fi

        if [ ! -e "$target" ] && [ ! -L "$target" ]; then
            ln -s "$cmd" "$target"
            echo "  ✅ Linked command: $name"
        else
            echo "  command already linked: $name"
        fi
    done
else
    echo "  ⚠️  Vault commands directory not found: $VAULT_COMMANDS"
fi

# ---------------------------------------------------------------------------
# Vault skills — symlink from Obsidian vault (source of truth)
# Skips targets that already exist (preserves ai-dev-tools symlinks)
# ---------------------------------------------------------------------------

if [ -d "$VAULT_SKILLS" ]; then
    echo "› Setting up vault OpenCode skills"
    mkdir -p "$SKILLS_DIR"
    for skill_dir in "$VAULT_SKILLS"/*/; do
        name=$(basename "$skill_dir")
        [ "$name" = "output" ] && continue  # skip build artifacts
        target="$SKILLS_DIR/$name"
        # -e follows symlinks, so a broken symlink (e.g. stale ai-dev-tools
        # path) looks "missing" and ln -s would fail with "File exists".
        # Also check -L so any existing link, broken or not, counts as present.
        if [ ! -e "$target" ] && [ ! -L "$target" ]; then
            ln -s "$skill_dir" "$target"
            echo "  ✅ Linked skill: $name"
        else
            echo "  skill already linked: $name"
        fi
    done
else
    echo "  ⚠️  Vault skills directory not found: $VAULT_SKILLS"
fi

# ---------------------------------------------------------------------------
# Kepano's obsidian-skills — teach agent Obsidian Flavored Markdown, Bases, Canvas, CLI
# https://github.com/kepano/obsidian-skills
# ---------------------------------------------------------------------------

echo "› Setting up obsidian-skills"
if [ ! -d "$OBSIDIAN_SKILLS_DIR" ]; then
    if command -v git >/dev/null 2>&1; then
        echo "  Cloning kepano/obsidian-skills..."
        git clone --quiet https://github.com/kepano/obsidian-skills.git "$OBSIDIAN_SKILLS_DIR"
        echo "  ✅ obsidian-skills installed"
    else
        echo "  ❌ git not found — skipping obsidian-skills install"
    fi
else
    echo "  obsidian-skills already installed (run 'git pull' in $OBSIDIAN_SKILLS_DIR to update)"
fi

echo ""
echo "› Done. Run 'install.sh --verify' to confirm all symlinks are healthy."
