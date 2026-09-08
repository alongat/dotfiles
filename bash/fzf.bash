export FZF_DEFAULT_COMMAND='fd --hidden --strip-cwd-prefix --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type=d --hidden --strip-cwd-prefix --exclude .git'

_fzf_compgen_path() {
    fd --hidden --exclude .git . "$1"
}

_fzf_compgen_dir() {
    fd --type=d --hidden --exclude .git . "$1"
}

export FZF_CTRL_T_OPTS="--preview 'if [[ -d {} ]]; then eza --tree --color=always {}; else bat -n --color=always --line-range :500 {}; fi'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {}'"

fedit() {
    local file
    file=$(fzf --query="${1:-}" --no-multi --select-1 --exit-0 \
        --preview 'bat --color=always --line-range :500 {}')
    [[ -n "$file" ]] && "$EDITOR" "$file"
}

sf() {
    fzf --multi \
        --preview 'bat --color=always --line-range :500 {}' \
        --bind 'ctrl-w:execute(nvim {+})+abort,ctrl-y:execute-silent(wl-copy < {})+abort'
}
