# Dotfiles

Personal dotfiles collection, forked from @vic3lord.

## Quick Start

```bash
git clone https://github.com/alongat/dotfiles ~/.dotfiles
cd ~/.dotfiles && make
```

## Available Commands

- `make` or `make all` - Install all dotfiles and run install scripts
- `make test` - Dry run to preview changes without applying them
- `make dotfiles` - Create symlinks for dotfiles only
- `make install` - Run all install.sh scripts and brew bundle
- `make clean` - Remove broken symlinks
- `make backup` - Backup existing dotfiles before changes
- `make help` - Show all available commands

## What's Included

### Shell & Terminal
- **zsh** - Shell with custom aliases, completions, history, and fpath configuration
- **starship** - Cross-shell prompt
- **ghostty** / **wezterm** - Terminal emulators
- **zellij** - Terminal multiplexer with custom layouts
- **fzf** - Fuzzy finder
- **zoxide** - Smart directory navigation
- **bat** - Syntax-highlighted cat replacement
- **carapace** - Universal shell completions

### Editor
- **nvim** - Neovim with LazyVim configuration

### DevOps & Infrastructure
- **kubernetes** - kubectl aliases and completions
- **argocd** / **flux** - GitOps tools
- **linkerd** - Service mesh
- **terraform** - IaC completions
- **gcloud** - Google Cloud SDK
- **go** - Go language configuration

### AI Coding Assistants
- **claude** - Claude Code configuration
- **opencode** - OpenCode configuration (with encrypted AGENTS.md)
- **gemini-cli** - Gemini CLI setup

### Other
- **git** - Git configuration and aliases
- **ssh** - SSH client configuration
- **macos** - macOS system defaults
- **raycast** - Productivity launcher commands
- **ruby** - rbenv configuration

## Structure

- `.symlink` files are automatically linked to home directory (e.g., `gitconfig.symlink` → `~/.gitconfig`)
- `install.sh` scripts handle tool-specific installation
- `.zsh` files provide shell configuration (aliases, completions, paths)
- Each tool has its own directory for organized configuration

## Safety Features

- Automatic backup of existing dotfiles before installation
- Dry run mode to preview changes
- Error handling with clear success/failure messages
- Broken symlink cleanup utility
