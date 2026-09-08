pubkey() {
    local key=${1:-"$HOME/.ssh/id_ed25519.pub"}
    if [[ ! -f "$key" ]]; then
        echo "Public key not found: $key" >&2
        return 1
    fi
    wl-copy < "$key" && echo "Public key copied to clipboard."
}

myip() {
    dig myip.opendns.com @resolver1.opendns.com +short
}

whoseport() {
    if [[ -z "${1:-}" ]]; then
        echo "Usage: whoseport <port>" >&2
        return 1
    fi
    ss -ltnp "sport = :$1"
}

contained() {
    docker run -it --rm -v "$PWD:/workspace" -w /workspace "$@"
}

cronjobjob() {
    if [[ -z "${1:-}" ]]; then
        echo "Usage: cronjobjob JOB [NAMESPACE]" >&2
        return 1
    fi
    local job=$1
    local namespace=${2:-default}
    kubectl -n "$namespace" create job --from="cronjob/$job" "$job-$(date +%s)"
}

kwatchpodlogs() {
    if [[ -z "${1:-}" ]]; then
        echo "Usage: kwatchpodlogs POD [NAMESPACE]" >&2
        return 1
    fi
    local pod=$1
    local namespace=${2:-default}
    kubectl -n "$namespace" logs -f "$pod"
}

kwatchpod() {
    if [[ -z "${1:-}" ]]; then
        echo "Usage: kwatchpod POD [NAMESPACE]" >&2
        return 1
    fi
    local pod=$1
    local namespace=${2:-default}
    if command -v viddy >/dev/null 2>&1; then
        viddy "kubectl -n $(printf '%q' "$namespace") get pods | grep $(printf '%q' "$pod")"
    else
        watch -n 2 "kubectl -n $(printf '%q' "$namespace") get pods | grep $(printf '%q' "$pod")"
    fi
}

gcpset() {
    if [[ -z "${1:-}" ]]; then
        echo "Usage: gcpset PROJECT" >&2
        return 1
    fi
    local project=$1
    gcloud config set project "$project"
}

pcdn() {
    if [[ -z "${1:-}" || -z "${2:-}" ]]; then
        echo "Usage: pcdn URL_MAP PATH" >&2
        return 1
    fi
    local urlmap=$1
    local urlpath=$2
    local name
    name=$(gcloud compute url-maps list --filter="name~$urlmap" --format='value(name)') || return
    echo "Invalidating path $urlpath for $name"
    gcloud compute url-maps invalidate-cdn-cache "$name" --path "$urlpath"
}

git_current_branch() {
    git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null
}

ggp() {
    local branch=${1:-$(git_current_branch)}
    git push origin "$branch"
}

ggu() {
    local branch=${1:-$(git_current_branch)}
    git pull --rebase origin "$branch"
}

ggpnp() {
    ggu "$@" && ggp "$@"
}
