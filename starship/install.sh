#!/usr/bin/env sh
if [ ! -d ~/.config/starship.toml ]; then
  mkdir -p ~/.config
  ln -s $HOME/.dotfiles/starship/starship.toml ~/.config/starship.toml
fi
