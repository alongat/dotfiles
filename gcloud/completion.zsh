# Lazy-load gcloud completion for faster shell startup
# This avoids the slow 'brew --prefix' call at startup
if command -v gcloud &> /dev/null; then
  GCLOUD_SDK_PATH="/opt/homebrew/share/google-cloud-sdk"
  
  if [ -f "${GCLOUD_SDK_PATH}/completion.zsh.inc" ]; then
    gcloud() {
      unfunction gcloud
      source "${GCLOUD_SDK_PATH}/completion.zsh.inc"
      gcloud "$@"
    }
  fi
fi

# Custom g completion for configuration switching
function __g {
	_arguments "1: :($(gcloud config configurations list --format='value(name)'))"
}

compdef __g g
