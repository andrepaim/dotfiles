# Dotfiles

A focused zsh, tmux, and Vim setup for WSL, Linux, and macOS.

The repository does not install packages, change the login shell, or modify
operating-system settings. `bootstrap.sh` only links an explicit list of
configuration files into `$HOME`.

## Installed files

| Repository file | Destination | Purpose |
| --- | --- | --- |
| `.zshrc` | `~/.zshrc` | Shell history, completion, prompt, aliases, and user paths |
| `.tmux.conf` | `~/.tmux.conf` | tmux behavior, keybindings, and Tokyo Night theme |
| `.tmux/status.sh` | `~/.tmux/status.sh` | Portable status metrics and clipboard integration |
| `.vimrc` | `~/.vimrc` | Vim behavior, mappings, plugins, and status line |
| `.vim/colors/tokyonight_custom.vim` | `~/.vim/colors/tokyonight_custom.vim` | Fallback Tokyo Night colorscheme |

No other repository file is installed.

## Requirements

The installer requires Bash and standard Unix tools such as `ln`, `mv`, and
`mkdir`. The configuration itself expects:

- zsh
- tmux
- Vim
- Git and curl for automatic Vim plugin installation
- ripgrep for Vim's `:Rg` command

Vim downloads vim-plug and the configured plugins on first launch. Generated
plugin checkouts, undo history, shell history, and caches are intentionally not
stored in this repository.

Clipboard integration selects the first available command:

- WSL: `clip.exe`
- macOS: `pbcopy`
- Wayland Linux: `wl-copy`
- X11 Linux: `xclip` or `xsel`

GPU status is shown only when `nvidia-smi` is available. CPU, memory, disk, and
uptime status support Linux and macOS without additional scripts.

## Install

Clone the repository and inspect the planned changes:

```sh
git clone git@github.com:andrepaim/dotfiles.git ~/src/dotfiles
cd ~/src/dotfiles
./bootstrap.sh --dry-run
```

Install the links:

```sh
./bootstrap.sh
```

When a destination already exists, the installer asks for confirmation and
moves it under `~/.dotfiles-backup/<timestamp>/` before creating the link. Use
`--force` to skip that confirmation; backups are still created.

The script is idempotent. Links that already point to this checkout are left
unchanged.

To make zsh the login shell after installing it, use the operating system's
normal `chsh` command. The bootstrap script deliberately does not do this.

## Update

Because the installed files are symbolic links, pulling changes into the
checkout updates the active configuration immediately:

```sh
cd ~/src/dotfiles
git pull --ff-only
```

Run `./bootstrap.sh` again only when the install manifest changes or links have
been removed.

## Uninstall

Remove only links that point into this checkout, then restore any desired files
from `~/.dotfiles-backup/`. The repository does not provide an automatic
uninstaller so it cannot accidentally remove unrelated user files.
