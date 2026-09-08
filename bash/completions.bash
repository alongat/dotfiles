if command -v kubectl >/dev/null 2>&1; then
    source <(kubectl completion bash)
    complete -o default -F __start_kubectl kc

    _dotfiles_kube_contexts() {
        mapfile -t COMPREPLY < <(compgen -W "$(kubectl config get-contexts -o name 2>/dev/null)" -- "${COMP_WORDS[COMP_CWORD]}")
    }
    complete -F _dotfiles_kube_contexts k
fi

if command -v argocd >/dev/null 2>&1; then
    source <(argocd completion bash)
fi

if command -v carapace >/dev/null 2>&1; then
    source <(carapace _carapace)
fi
