#!/bin/bash
# Set up rex-agents: state dir, config, the hooks that record each agent's session (Claude Code
# settings.json, Codex hooks.json + trust entries), the OpenCode plugin link, and the skill.
# Idempotent. Every file it changes is backed up next to itself first (*.bak-<timestamp>).
set -e

echo "› Setting up rex-agents"

DOT="$HOME/.dotfiles/rex"
RA="$DOT/bin/rex-agents"
STATE_DIR="$HOME/.local/state/rex-agents"
CONFIG_DIR="$HOME/.config/rex-agents"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"

chmod +x "$DOT/bin/rex-agent" "$DOT/bin/rex-agents" "$DOT/test/"*.sh 2>/dev/null || true

if [ ! -d "$STATE_DIR/agents" ]; then
    mkdir -p "$STATE_DIR/agents"
    echo "  ✅ state dir created: $STATE_DIR"
else
    echo "  state dir exists: $STATE_DIR"
fi

if [ ! -f "$CONFIG_DIR/config.json" ]; then
    mkdir -p "$CONFIG_DIR"
    printf '{\n  "max_depth": 2,\n  "max_children": 5,\n  "default_agent": "claude"\n}\n' > "$CONFIG_DIR/config.json"
    echo "  ✅ config written: $CONFIG_DIR/config.json"
else
    echo "  config exists: $CONFIG_DIR/config.json"
fi

# Claude Code: hooks live in ~/.claude/settings.json.
if [ -f "$HOME/.claude/settings.json" ]; then
    echo "  $("$RA" install-hooks --agent claude --path "$HOME/.claude/settings.json")"
else
    echo "  ❌ ~/.claude/settings.json not found; run claude once, then re-run this script"
fi

# Codex: same hook format in ~/.codex/hooks.json, but codex only runs hooks it has recorded trust
# for (hooks.state in config.toml). codex-trust adds entries for the rex-agents hooks only.
if [ -d "$CODEX_HOME" ]; then
    echo "  $("$RA" install-hooks --agent codex --path "$CODEX_HOME/hooks.json")"
    echo "  $("$RA" codex-trust --hooks-json "$CODEX_HOME/hooks.json" --config "$CODEX_HOME/config.toml")"
else
    echo "  codex not set up ($CODEX_HOME missing); skipping its hooks"
fi

# OpenCode: loads every plugin in ~/.config/opencode/plugins; that dir is the dotfiles plugins dir.
if [ -e "$HOME/.config/opencode/plugins/rex-agents.js" ]; then
    echo "  opencode plugin present: ~/.config/opencode/plugins/rex-agents.js"
elif [ ! -e "$HOME/.config/opencode/plugins" ]; then
    mkdir -p "$HOME/.config/opencode"
    ln -s "$HOME/.dotfiles/opencode/plugins" "$HOME/.config/opencode/plugins"
    echo "  ✅ opencode plugins dir linked"
else
    echo "  ❌ ~/.config/opencode/plugins exists but does not contain rex-agents.js; link $DOT/opencode/rex-agents.js into it"
fi

# Skill: Claude reads ~/.claude/skills, Codex and OpenCode read ~/.agents/skills.
for skills in "$HOME/.claude/skills" "$HOME/.agents/skills"; do
    mkdir -p "$skills"
    if [ ! -e "$skills/rex-agents" ]; then
        ln -s "$DOT/skill" "$skills/rex-agents"
        echo "  ✅ skill linked: $skills/rex-agents"
    else
        echo "  skill exists: $skills/rex-agents"
    fi
done

echo "  ✅ rex-agents setup completed"
