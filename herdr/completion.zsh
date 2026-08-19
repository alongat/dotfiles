# Lazy-load herdr completion for faster shell startup
if command -v herdr &> /dev/null; then
  herdr() {
    unfunction herdr
    source <(command herdr completion zsh)
    herdr "$@"
  }
fi
