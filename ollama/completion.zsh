# Ollama zsh completions
# The _ollama compdef script lives at ~/.dotfiles/ollama/_ollama
# It's added to fpath automatically via zsh/fpath.zsh (which globs all dotfiles topic dirs)
# Nothing to do here — fpath.zsh handles the wiring.
# This file exists as a marker and for any future completion config hooks.

# Reload completions if ollama was just installed in this session
if command -v ollama &>/dev/null && ! command -v _ollama &>/dev/null; then
  autoload -Uz _ollama
fi
