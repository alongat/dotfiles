#!/bin/bash
# Claude Code setup — mirrors ~/.dotfiles/opencode/install.sh
# Idempotent. Run with --verify to check without changing anything.
set -euo pipefail

VERIFY=false
[ "${1:-}" = "--verify" ] && VERIFY=true

VAULT="/Users/alongat/obsidian-second-brain"
CLAUDE="$HOME/.claude"
OC_SKILLS="$HOME/.config/opencode/skills"

mkdir -p "$CLAUDE/commands" "$CLAUDE/skills"

# --- circular-symlink guard (the iCloud dehydration failure mode) ------------
is_bad_link() {
  local p="$1"
  [ -L "$p" ] || return 1
  [ -e "$p" ] && return 1   # resolves fine
  return 0                  # dangling or circular
}

link() {  # link <target> <linkname>
  local target="$1" name="$2"
  if is_bad_link "$name"; then
    echo "  ⚠️  removing broken link: $name"
    $VERIFY || rm -f "$name"
  fi
  if [ -e "$name" ] && [ ! -L "$name" ]; then
    echo "  ⏭️  real file present, skipping: $name"; return
  fi
  if [ -L "$name" ] && [ "$(readlink "$name")" = "$target" ]; then
    echo "  ✅ $name"; return
  fi
  if $VERIFY; then echo "  ❌ missing: $name -> $target"; return; fi
  ln -sfn "$target" "$name"
  echo "  ➕ $name -> $target"
}

echo "› Vault skills"
for d in "$VAULT/Skills/skills"/*/; do
  [ -f "$d/SKILL.md" ] || continue
  link "${d%/}" "$CLAUDE/skills/$(basename "${d%/}")"
done

echo "› Obsidian skills bundle"
for d in "$OC_SKILLS/obsidian-skills/skills"/*/; do
  [ -f "$d/SKILL.md" ] || continue
  link "${d%/}" "$CLAUDE/skills/$(basename "${d%/}")"
done

echo "› unslop"
link "$OC_SKILLS/unslop" "$CLAUDE/skills/unslop"

echo "› Vault commands"
for f in "$VAULT/Skills/commands"/*.md; do
  [ -e "$f" ] || continue        # skips the dead circular links
  link "$f" "$CLAUDE/commands/$(basename "$f")"
done

echo
echo "› Done. Torq plugins are installed separately via:"
echo "    claude plugin marketplace add ~/Code/torqio/ai-dev-tools"
