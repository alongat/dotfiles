# Dotfiles

My private dotfiles collection, forked from @vic3lord 💪.

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

This dotfiles collection includes configurations for:

- **Shell**: Zsh with custom aliases, completions, and history
- **Editor**: Neovim with LazyVim configuration
- **Terminal**: Wezterm and Starship prompt
- **macOS**: System defaults and preferences
- **Package Management**: Homebrew with Brewfile

## Structure

- `.symlink` files are automatically linked to home directory
- `install.sh` scripts handle tool-specific installation
- `.zsh` files provide shell configuration (aliases, completions, paths)
- Each tool has its own directory for organized configuration

## Safety Features

- Automatic backup of existing dotfiles before installation
- Dry run mode to preview changes
- Error handling with clear success/failure messages
- Broken symlink cleanup utility
