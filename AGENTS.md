# Agent Guidelines for Omarchy Dotfiles

## Build/Test Commands

- `make test` - Validate scripts and preview changes
- `make install` - Install core packages and link configuration
- `make dotfiles` - Back up conflicts and create managed symlinks
- `make packages PACKAGE_GROUPS="core devops"` - Install package groups
- `make packages-all` - Install all non-AUR package groups
- `make verify` - Validate the installed configuration
- `make clean` - Remove broken managed symlinks

## Code Style Guidelines

- **Shell Scripts**: Use `#!/bin/bash` shebang and `set -e` for error handling
- **Interactive Shell**: Extend Omarchy's Bash defaults; do not switch the login shell
- **File Structure**: Put Bash fragments in `bash/` and package manifests in `packages/`
- **Naming**: Use kebab-case for directories, snake_case for variables, descriptive function names
- **Error Handling**: Always check command success with proper exit codes and error messages
- **Output**: Use `echo "› Action"` for main actions, `echo "  Detail"` for sub-actions
- **Success/Failure**: Use ✅ for success, ❌ for failure in output messages

## File Conventions

- Managed links are declared explicitly in `scripts/link-configs.sh`
- Existing targets are backed up before links are created
- Keep this branch Omarchy-specific; remove macOS, Homebrew, and Zsh-only files
- Never modify `/usr/share/omarchy`; track user overrides under `omarchy/`
- Use absolute paths in scripts, avoid relative path dependencies

## Omarchy Conventions

- Preserve the Omarchy bootstrap at the beginning of `~/.bashrc`
- Prefer packaged Bash completions, then generated completion, then Carapace
- Use `omarchy pkg add` and `omarchy pkg aur add` for packages
- Keep Ghostty owned by Omarchy so dynamic themes continue to work
- Validate Hyprland changes with `hyprctl reload` and `hyprctl configerrors`
- Keep machine-specific and work-specific values out of version control
- Make every installer idempotent and support a non-mutating preview

## Encrypted Files

The `opencode/AGENTS.md` file is password-encrypted using OpenSSL:
- `AGENTS.md.enc` is committed (encrypted)
- `AGENTS.md` is gitignored (plaintext)
- OpenCode migration is pending; decrypt manually when working on that module
- Use `agents-encrypt` / `agents-decrypt` aliases to manage

## Branches

- `master` is the preserved macOS branch and remains the remote default for now
- `omarchy` is the daily Linux branch
- Cherry-pick isolated shared fixes instead of merging platform branches wholesale
