if which gh > /dev/null 2>&1
then
	source <(gh completion -s zsh)
fi

compdef _git _git_log_prettily=git-log
compdef _git gccd=git-clone
compdef _git gdnolock=git-diff
compdef _git gdv=git-diff
compdef _git ggf=git-checkout
compdef _git ggfl=git-checkout
compdef _git ggl=git-checkout
compdef _git ggp=git-checkout
compdef _git ggpnp=git-checkout
compdef _git ggu=git-checkout
