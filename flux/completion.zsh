# Lazy-load flux completion for faster shell startup
if command -v flux &> /dev/null; then
  flux() {
    unfunction flux
    source <(command flux completion zsh)
    compdef _flux flux
    flux "$@"
  }
fi
