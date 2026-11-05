# rex-agents: when Rex restores a block after a server restart it brings back a plain shell,
# not the command that ran in it. If this block belonged to a tracked Claude agent, hand the
# shell over to the launcher, which resumes the recorded session. Plain shells pay one stat.
#
# Runs from a precmd hook so the whole zshrc (PATH, REX_BIN_DIR, etc.) has been read first.
if [[ -n "$REX_BLOCK" && -o interactive && -z "$CLAUDECODE" && -z "$REX_AGENT_NO_RESUME" ]]; then
  _rex_autoresume() {
    add-zsh-hook -d precmd _rex_autoresume
    local uuid="${REX_BLOCK#block:}"
    local state="${REX_AGENTS_STATE_DIR:-$HOME/.local/state/rex-agents}"
    if [[ -f "$HOME/.local/state/rex-agents/redirect/$uuid" ]]; then
      state="$(<"$HOME/.local/state/rex-agents/redirect/$uuid")"
    fi
    [[ -f "$state/agents/$uuid.json" ]] || return 0
    export REX_AGENTS_STATE_DIR="$state"
    if "$HOME/.dotfiles/rex/bin/rex-agents" should-resume "$REX_BLOCK"; then
      exec "$HOME/.dotfiles/rex/bin/rex-agent"
    fi
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _rex_autoresume
fi
