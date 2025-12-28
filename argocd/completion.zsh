# Lazy-load argocd completion for faster shell startup
if command -v argocd &> /dev/null; then
  argocd() {
    unfunction argocd
    source <(command kubectl argo rollouts completion zsh)
    argocd "$@"
  }
fi
