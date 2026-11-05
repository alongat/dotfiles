#!/bin/bash
# Set up rex-agents: state dir, config, and the Claude Code hooks that record each agent's session.
# Idempotent. Backs up ~/.claude/settings.json before the first change.
set -e

echo "› Setting up rex-agents"

DOT="$HOME/.dotfiles/rex"
STATE_DIR="$HOME/.local/state/rex-agents"
CONFIG_DIR="$HOME/.config/rex-agents"
SETTINGS="$HOME/.claude/settings.json"

chmod +x "$DOT/bin/rex-agent" "$DOT/bin/rex-agents" "$DOT/test/"*.sh 2>/dev/null || true

if [ ! -d "$STATE_DIR/agents" ]; then
    mkdir -p "$STATE_DIR/agents"
    echo "  ✅ state dir created: $STATE_DIR"
else
    echo "  state dir exists: $STATE_DIR"
fi

if [ ! -f "$CONFIG_DIR/config.json" ]; then
    mkdir -p "$CONFIG_DIR"
    printf '{\n  "max_depth": 2,\n  "max_children": 5\n}\n' > "$CONFIG_DIR/config.json"
    echo "  ✅ config written: $CONFIG_DIR/config.json"
else
    echo "  config exists: $CONFIG_DIR/config.json"
fi

if [ ! -f "$SETTINGS" ]; then
    echo "  ❌ $SETTINGS not found; run claude once first"
    exit 1
fi

# Merge the hooks. The command is a marker: an entry whose command contains "rex-agents hook"
# is ours, so re-running never duplicates it and never touches rex's or herdr's entries.
HOOK_CMD="/bin/sh -c '[ -n \"\$REX_BLOCK\" ] || exit 0; exec \"$DOT/bin/rex-agents\" hook'"
export HOOK_CMD SETTINGS
changed=$(python3 - <<'PY'
import json, os, shutil, time
path = os.environ["SETTINGS"]
cmd = os.environ["HOOK_CMD"]
with open(path) as fh:
    settings = json.load(fh)
hooks = settings.setdefault("hooks", {})
changed = False
for event in ("SessionStart", "UserPromptSubmit", "Stop", "Notification", "SessionEnd"):
    entries = hooks.setdefault(event, [])
    if any("rex-agents hook" in h.get("command", "") for e in entries for h in e.get("hooks", [])):
        continue
    entries.append({"hooks": [{"type": "command", "command": cmd, "timeout": 5}]})
    changed = True
if changed:
    backup = f"{path}.bak-{time.strftime('%Y%m%d-%H%M%S')}"
    shutil.copy2(path, backup)
    with open(path, "w") as fh:
        json.dump(settings, fh, indent=2)
        fh.write("\n")
    print(f"backup={backup}")
PY
)
if [ -n "$changed" ]; then
    echo "  ✅ Claude Code hooks installed (${changed})"
else
    echo "  Claude Code hooks already installed"
fi

echo "  ✅ rex-agents setup completed"
