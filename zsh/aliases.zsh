alias reload!=". ~/.zshrc"
alias ..="cd .."
alias ...="cd ../.."
alias ls="eza --color=always --git --no-user --no-permissions --icons=always --group-directories-first"
alias ll="ls --long"
alias vd="viddy"
alias sf='fzf -m --preview="bat --color=always {}" --bind "ctrl-w:execute(nvim {+})+abort,ctrl-y:execute-silent(echo {} | pbcopy)+abort"'
alias c="clear"
