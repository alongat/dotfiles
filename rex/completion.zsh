# Rex completion, cached so shell startup doesn't spawn rex every time.
# rex is only on PATH inside Rex terminals (see the REX_BIN_DIR block in zshrc.symlink).
if command -v rex &> /dev/null; then
  _rex_comp=~/.cache/rex/completion.zsh
  rex_bin=$(command -v rex)
  if [[ ! -s $_rex_comp || $rex_bin -nt $_rex_comp ]]; then
    mkdir -p ~/.cache/rex
    command rex completion zsh --autostart=false > $_rex_comp 2>/dev/null
  fi
  source $_rex_comp
  unset _rex_comp rex_bin
fi
