# Dotfiles

[![CI](https://github.com/andrepaim/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/andrepaim/dotfiles/actions/workflows/ci.yml)

Shell, terminal, editor, and AI-agent configuration for WSL, Linux, and macOS.

`bootstrap.sh` installs an explicit manifest into `$HOME`. It does not install
packages, change the login shell, or modify operating-system settings (except
the opt-in `wsl-ssh` group, which uses `sudo`).

## Install

```sh
git clone git@github.com:andrepaim/dotfiles.git ~/src/dotfiles
cd ~/src/dotfiles
./bootstrap.sh --dry-run   # inspect the plan
./bootstrap.sh             # install every default group
./bootstrap.sh tmux vim    # or only some groups
```

When a destination already exists, the installer asks once and moves it under
`~/.dotfiles-backup/<timestamp>/` before installing. `--force` skips the
question; backups are still made. The script is idempotent and runs on the
Bash 3.2 that ships with macOS.

## Linked vs. seeded files

- **Linked** files are symlinks into this checkout. `git pull` updates them
  immediately, and edits made through `~/...` show up in `git status`.
- **Seeded** files are copied once, because the owning tool rewrites them at
  runtime (project trust lists, approval rules, UI state). Existing seeded
  files are kept; bootstrap reports them as `keep` when they differ. Use
  `./bootstrap.sh --dry-run --update-seeds` to see what would be replaced, and
  `--update-seeds` to replace them (with a backup). Seeds may contain
  `__HOME__` and `__USER__`, which are rendered at install time.

## Groups

| Group | Files | Mode |
| --- | --- | --- |
| `shell` | `.bashrc`, `.zshrc` | link |
| `git` | `.gitconfig`, `.config/git/ignore` | link |
| `tmux` | `.tmux.conf`, `.tmux/status.sh` | link |
| `vim` | `.vimrc`, `.vim/colors/tokyonight_custom.vim` | link |
| `agents` | `.claude/statusline-command.sh` | link |
| | `.claude/settings.json`, `.codex/config.toml`, `.codex/rules/default.rules`, `.config/opencode/opencode.jsonc`, `.pi/agent/settings.json`, `.config/agent-deck/config.toml` | seed |
| `skills` | `skills/*` into `~/.agents/skills`, `~/.claude/skills`, `~/.codex/skills` (see [skills/README.md](skills/README.md)) | link |
| | `.agents/.skill-lock.json` | seed |
| `tools` | `.config/btop/btop.conf`, `.config/htop/htoprc` | seed |
| `services` | `.config/systemd/user/{agent-deck-autoupdate.service,agent-deck-autoupdate.timer,saldo.service}`, then `systemctl --user enable` | seed |
| `wsl-ssh` (opt-in) | `wsl/ssh/*.conf` into `/etc/ssh/sshd_config.d/` and `/etc/systemd/system/ssh.socket.d/` | sudo copy |

Platform handling:

- `services` runs only on Linux with a systemd user session (including WSL
  with systemd enabled). Each unit is installed only when what it runs exists
  (`~/.local/bin/agent-deck`, `~/src/saldo`).
- `wsl-ssh` refuses to run outside WSL. After it runs, expose sshd on the LAN
  from an elevated Windows PowerShell:

  ```powershell
  powershell -ExecutionPolicy Bypass -File wsl\configure-ssh-portproxy.ps1 `
    -ListenAddress <windows-lan-ip> -RemoteSubnet <lan-cidr>
  ```

  The drop-in allows password authentication for the installing user; keep the
  firewall rule restricted to your LAN subnet.

## Requirements

- zsh or bash, tmux, Vim
- Git and curl (Vim installs vim-plug and plugins on first launch)
- ripgrep for Vim's `:Rg`
- jq for the Claude Code status line

Clipboard integration in tmux and Vim picks the first available of
`clip.exe` (WSL), `pbcopy` (macOS), `wl-copy`, `xclip`, or `xsel`. GPU status
appears only when `nvidia-smi` exists. Homebrew is added to `PATH` when found.

## Local, uncommitted overrides

| File | Read by |
| --- | --- |
| `~/.bashrc.local` | `.bashrc` |
| `~/.zshrc.local` | `.zshrc` |
| `~/.gitconfig.local` | `.gitconfig` (work identity, credential helpers, signing) |

Because `~/.gitconfig` is a link, `git config --global ...` writes into this
checkout; use `git config --file ~/.gitconfig.local ...` for anything private.

## What is never stored here

Credentials and tokens (`~/.claude/.credentials.json`, `~/.codex/auth.json`,
`~/.pi/agent/auth.json`, `~/.npmrc`, `~/.ssh/`), shell and agent history,
sessions, caches, and databases. `.gitignore` blocks the common names as a
second line of defence.

## Tests

`tests/bootstrap-test.sh` installs into a throwaway home and checks the dry
run, the conflict prompt, backups, link targets, seed rendering, idempotence,
`--update-seeds`, and that the shell, tmux, and status-line configs load. Run
it locally with `tests/bootstrap-test.sh`.

CI (`.github/workflows/ci.yml`) runs on every push and pull request:

- **Lint**: `bash -n`, ShellCheck, and JSON/TOML parsing of the seeded configs
- **Secret scan**: gitleaks over the full history
- **Bootstrap**: the test script on Ubuntu and macOS, and again on macOS with
  the system Bash 3.2

WSL is not available on hosted runners; the WSL-specific paths (clipboard via
`clip.exe`, the `wsl-ssh` group) are exercised only by running locally.

## Update

```sh
cd ~/src/dotfiles
git pull --ff-only
./bootstrap.sh   # only needed when the manifest changes
```

## Uninstall

Remove the links that point into this checkout and restore what you need from
`~/.dotfiles-backup/`. There is no automatic uninstaller, so nothing unrelated
can be removed by accident.
