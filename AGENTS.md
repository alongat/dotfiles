# Agent Guidelines for Dotfiles Repository

## Build/Test Commands

- `make` - Install all dotfiles and run install scripts
- `make test` - Dry run to preview changes without applying them
- `make dotfiles` - Create symlinks for dotfiles only
- `make install` - Run all install.sh scripts and brew bundle
- `make clean` - Remove broken symlinks
- `make backup` - Backup existing dotfiles before changes

## Code Style Guidelines

- **Shell Scripts**: Use `#!/bin/bash` shebang, `set -e` for error handling
- **File Structure**: Each tool has its own directory with install.sh, aliases.zsh, completion.zsh, path.zsh as needed
- **Naming**: Use kebab-case for directories, snake_case for variables, descriptive function names
- **Error Handling**: Always check command success with proper exit codes and error messages
- **Output**: Use `echo "› Action"` for main actions, `echo "  Detail"` for sub-actions
- **Success/Failure**: Use ✅ for success, ❌ for failure in output messages

## File Conventions

- `.symlink` files are automatically linked to home directory (e.g., `gitconfig.symlink` → `~/.gitconfig`)
- `install.sh` scripts handle tool-specific installation and configuration
- `.zsh` files are sourced by zsh configuration (aliases, completions, paths)
- Use absolute paths in scripts, avoid relative path dependencies

