# Omarchy Dotfiles

Personal configuration for [Omarchy](https://omarchy.org/). This branch uses
Omarchy's Bash, Hyprland, shell, and theme architecture instead of replacing
the distribution defaults.

The `master` branch retains the original macOS setup. The `omarchy` branch is
the daily branch for Linux and intentionally diverges from `master`. Shared
fixes should be cherry-picked between branches rather than merging either
platform branch wholesale.

## Principles

- Keep Bash as the login and interactive shell.
- Load personal Bash configuration after Omarchy's maintained defaults.
- Never modify files under `/usr/share/omarchy`.
- Preserve Omarchy's Ghostty configuration and dynamic themes.
- Track only user-owned Hyprland and Omarchy overrides.
- Back up existing configuration before replacing it with a symlink.
- Install packages through `omarchy pkg` rather than calling pacman directly.

## Quick Start

Preview all core changes:

```bash
make test
```

Install the core package group and link configuration:

```bash
make install
```

Verify the installed configuration:

```bash
make verify
```

Conflicting files are moved to timestamped directories under
`~/.local/state/dotfiles/backups/` before links are created.

## Package Groups

```bash
make packages                              # core
make packages PACKAGE_GROUPS=development
make packages PACKAGE_GROUPS="core devops"
make packages PACKAGE_GROUPS=aur
make packages-all                          # core + development + devops
```

- `core`: GitHub CLI, Delta, Zellij, and general command-line utilities.
- `development`: Go, Rust, Node.js, npm, and uv.
- `devops`: kubectl, Helm, Terraform, HTTPie, and Argo CD.
- `aur`: Carapace, Google Cloud CLI, k6, and viddy.

Omarchy already provides Bash completion, Starship, fzf, zoxide, Neovim,
Ghostty, eza, bat, fd, ripgrep, and Wayland clipboard tools.

## Managed Configuration

- `bash/`: aliases, functions, environment, fzf preferences, and completions.
- `git/`: Git configuration and global ignore rules.
- `ssh/config.omarchy`: Linux-compatible SSH defaults.
- `starship/`: personal prompt configuration.
- `zellij/`: Zellij configuration and layouts.
- `nvim/dotconfig/`: personal LazyVim configuration.
- `omarchy/hypr/`: Hyprland user overrides.
- `omarchy/shell.toml`: Omarchy shell preferences.

The installer adds one source line to the existing `~/.bashrc`; it does not
replace that file. Machine- or employer-specific settings belong in the
untracked `~/.config/dotfiles.local.bash` file.

Git identity is also machine-local. Create `~/.config/git/local` after the
first installation:

```gitconfig
[user]
    name = Your Name
    email = you@example.com
```

## Linux Replacements

| macOS command or service | Omarchy equivalent |
|---|---|
| `pbcopy` / `pbpaste` | `wl-copy` / `wl-paste` |
| `open` | Omarchy's `open` function using `xdg-open` |
| Raycast | Omarchy menu and menu extensions |
| Homebrew | `omarchy pkg add` and `omarchy pkg aur add` |
| `networksetup` | NetworkManager and per-command proxy variables |
| iCloud Obsidian vault | Local vault or Syncthing-backed vault |

## Remaining Migration

OpenCode is not linked yet. Its existing configuration contains macOS paths
and iCloud-dependent vault integration that must be made Linux-safe first.
