path_prepend() {
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1${PATH:+:$PATH}" ;;
    esac
}

path_prepend "$DOTFILES_ROOT/bin"
path_prepend "$HOME/.go/bin"
path_prepend "$HOME/.linkerd2/bin"
path_prepend "$HOME/.krew/bin"
export PATH
unset -f path_prepend

export EDITOR=nvim
export SUDO_EDITOR=nvim
export GOPATH="$HOME/.go"
export GOPROXY="https://proxy.golang.org,direct"
export USE_GKE_GCLOUD_AUTH_PLUGIN=true

opencode_env="$DOTFILES_ROOT/opencode/.env"
if [[ -r "$opencode_env" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "$opencode_env"
    set +a
fi
unset opencode_env
