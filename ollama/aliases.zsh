# Ollama aliases
alias oll='ollama'
alias ollr='ollama run'
alias olll='ollama list'
alias ollp='ollama pull'
alias ollrm='ollama rm'

# Sync local models to match ~/.dotfiles/ollama/models.txt
# Pulls new models and removes unlisted ones
ollama-sync() {
    sh "$HOME/.dotfiles/ollama/install.sh"
}
