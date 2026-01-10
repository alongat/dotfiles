# AGENTS.md encryption helpers
alias agents-encrypt='openssl enc -aes-256-cbc -pbkdf2 -in ~/.dotfiles/opencode/AGENTS.md -out ~/.dotfiles/opencode/AGENTS.md.enc'
alias agents-decrypt='openssl enc -aes-256-cbc -pbkdf2 -d -in ~/.dotfiles/opencode/AGENTS.md.enc -out ~/.dotfiles/opencode/AGENTS.md'
