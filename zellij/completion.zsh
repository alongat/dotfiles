# zellij completions are provided by Homebrew's _zellij in site-functions
# Map aliases to the same completion function
if command -v zellij &> /dev/null; then
  compdef _zellij z
  compdef _zellij za
  compdef _zellij vz
  compdef _zellij voc
fi
