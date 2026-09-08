alias reload!=". ~/.zshrc"
alias ..="cd .."
alias ...="cd ../.."
# eza reads stdin as an implicit path list when stdin isn't a TTY, and silently lists nothing
# if it finds none. That never shows up typing at a prompt (stdin stays the terminal even when
# you pipe/redirect stdout), only in scripts and agent tool calls, so it looks fine here and
# breaks there. Keep eza for interactive listings; fall back to real ls otherwise.
_eza_ls=(eza --color=always --git --no-user --no-permissions --icons=always --group-directories-first)

ls() {
  if [[ -t 1 ]]; then
    "${_eza_ls[@]}" "$@"
  else
    /bin/ls "$@"
  fi
}

ll() {
  if [[ -t 1 ]]; then
    "${_eza_ls[@]}" --long "$@"
  else
    /bin/ls -l "$@"
  fi
}
alias vd="viddy"
alias sf='fzf -m --preview="bat --color=always {}" --bind "ctrl-w:execute(nvim {+})+abort,ctrl-y:execute-silent(echo {} | pbcopy)+abort"'
alias c="clear"
