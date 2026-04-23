# opencode uses yargs which requires a #compdef file in fpath (not source <())
# Cache completion to ~/.zsh/completions/_opencode; regenerate when binary changes
# Uses binary mtime for cache invalidation -- no subprocess needed at startup
if command -v opencode &> /dev/null; then
  _opencode_bin="${commands[opencode]}"
  _opencode_cache="${HOME}/.zsh/completions/_opencode"

  if [[ ! -f "${_opencode_cache}" || "${_opencode_bin}" -nt "${_opencode_cache}" ]]; then
    mkdir -p "${HOME}/.zsh/completions"
    opencode completion zsh 2>/dev/null > "${_opencode_cache}.tmp" && \
      mv "${_opencode_cache}.tmp" "${_opencode_cache}"
  fi

  # Add cache dir to fpath if not already present
  if [[ -d "${HOME}/.zsh/completions" ]] && \
     (( ! ${fpath[(Ie)${HOME}/.zsh/completions]} )); then
    fpath=("${HOME}/.zsh/completions" $fpath)
  fi

  unset _opencode_bin _opencode_cache
fi
