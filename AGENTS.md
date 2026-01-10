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

## Directory Structure

Each tool directory typically contains:
- `install.sh` - Installation and setup script (optional)
- `aliases.zsh` - Shell aliases (sourced automatically)
- `completion.zsh` - Shell completions (sourced automatically)
- `path.zsh` - PATH modifications (sourced automatically)

## install.sh Conventions

When creating or modifying install.sh scripts:

1. **Symlink to ~/.config**: Most tools expect config in `~/.config/<tool>/`. The install script should:
   - Check if source config exists in dotfiles repo
   - Create `~/.config/<tool>` directory if needed
   - Create symlink from dotfiles to ~/.config location
   - Handle existing files/links gracefully

2. **Example pattern**:
```bash
#!/bin/bash
set -e

echo "› Setting up <tool> configuration"

if [ ! -d ~/.config/<tool> ]; then
    mkdir -p ~/.config/<tool>
fi

if [ ! -e ~/.config/<tool>/config ]; then
    ln -s "$HOME/.dotfiles/<tool>/config" ~/.config/<tool>/config
    echo "  ✅ config linked successfully"
else
    echo "  config already exists"
fi
```

3. **Idempotency**: Scripts should be safe to run multiple times without errors or duplicate work.

## Encrypted Files

The `opencode/AGENTS.md` file is password-encrypted using OpenSSL:
- `AGENTS.md.enc` is committed (encrypted)
- `AGENTS.md` is gitignored (plaintext)
- Decryption happens automatically during `make install`
- Use `agents-encrypt` / `agents-decrypt` aliases to manage

## Brewfile

`Brewfile` at repo root contains all Homebrew packages, casks, and Mac App Store apps. Organized by category with comments explaining each package.

