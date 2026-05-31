# Load OpenCode MCP secrets from gitignored .env file
# Required for {env:VAR} substitution in opencode.json to resolve correctly
_opencode_env="$HOME/.dotfiles/opencode/.env"
if [ -e "$_opencode_env" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$_opencode_env"
  set +a
fi
unset _opencode_env
