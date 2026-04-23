# add Homebrew's zsh completions to fpath (provides completions for brew, bat, fd, rg, eza, helm, k3d, jira, zellij, etc.)
if [ -d /opt/homebrew/share/zsh/site-functions ]; then
  fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
elif [ -d /usr/local/share/zsh/site-functions ]; then
  fpath=(/usr/local/share/zsh/site-functions $fpath)
fi

# add each topic folder to fpath so that they can add functions and completion scripts
for topic_folder ($DOTFILES/*) if [ -d $topic_folder ]; then  fpath=($topic_folder $fpath); fi;
