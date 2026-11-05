# rex-agents: when Rex restores a block after a server restart it brings back a plain shell,
# not the command that ran in it. If this block belonged to a tracked Claude agent, hand the
# shell over to the launcher, which resumes the recorded session. Plain shells pay one stat.
if [[ -n "$REX_BLOCK" && -o interactive && -z "$CLAUDECODE" && -z "$REX_AGENT_NO_RESUME" ]]; then
  _rex_uuid="${REX_BLOCK#block:}"
  _rex_state="${REX_AGENTS_STATE_DIR:-$HOME/.local/state/rex-agents}"
  if [[ -f "$HOME/.local/state/rex-agents/redirect/$_rex_uuid" ]]; then
    _rex_state="$(<"$HOME/.local/state/rex-agents/redirect/$_rex_uuid")"
  fi
  if [[ -f "$_rex_state/agents/$_rex_uuid.json" ]]; then
    export REX_AGENTS_STATE_DIR="$_rex_state"
    if "$HOME/.dotfiles/rex/bin/rex-agents" should-resume "$REX_BLOCK"; then
      unset _rex_uuid _rex_state
      exec "$HOME/.dotfiles/rex/bin/rex-agent"
    fi
  fi
  unset _rex_uuid _rex_state
fi
