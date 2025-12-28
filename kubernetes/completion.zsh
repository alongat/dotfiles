# Lazy-load kubectl completion for faster shell startup
if command -v kubectl &> /dev/null; then
  kubectl() {
    unfunction kubectl
    source <(command kubectl completion zsh)
    kubectl "$@"
  }
fi

# Custom k completion for context switching
function __k {
	_arguments "1: :($(kubectl config get-contexts --output='name'))"
}

compdef __k k

# Minikube -- Removed as it's slow
# if which minikube > /dev/null 2>&1
# then
# 	source <(minikube completion zsh)
# fi
