#!/usr/bin/env bash
#
# Install this repository's configuration into $HOME on macOS, Linux, and WSL.
# Compatible with the Bash 3.2 that ships with macOS.

set -e

script_dir=$(CDPATH='' cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
all_groups="shell git tmux vim agents skills tools services"

usage() {
	cat <<EOF
Usage: ./bootstrap.sh [options] [group ...]

Install configuration by linking (or seeding) an explicit manifest into \$HOME.
With no groups, every default group is installed:

  shell     .bashrc, .zshrc
  git       .gitconfig, global gitignore
  tmux      .tmux.conf, .tmux/status.sh
  vim       .vimrc, Tokyo Night colorscheme
  agents    Claude Code, Codex, opencode, pi, agent-deck settings
  skills    agent skills for Claude Code, Codex, and ~/.agents
  tools     btop, htop
  services  systemd user units (Linux with systemd only)

Opt-in groups (never installed by default):

  wsl-ssh   sshd drop-ins for LAN SSH into WSL (uses sudo)

Options:
  --dry-run       Print the actions without changing any files.
  --force         Skip confirmation when existing files need to be backed up.
  --update-seeds  Also replace seeded files that differ from the repository
                  (the old file is backed up first).
  -h, --help      Show this help text.

Linked files are symbolic links into this checkout, so 'git pull' updates
them. Seeded files are copied once because the owning tool rewrites them;
they are left alone when they already exist unless --update-seeds is given.
EOF
}

force=false
dry_run=false
update_seeds=false
groups=""

while [ "$#" -gt 0 ]; do
	case "$1" in
		--dry-run) dry_run=true ;;
		-f|--force) force=true ;;
		--update-seeds) update_seeds=true ;;
		-h|--help) usage; exit 0 ;;
		-*)
			printf 'Unknown option: %s\n\n' "$1" >&2
			usage >&2
			exit 2
			;;
		*)
			case " $all_groups wsl-ssh " in
				*" $1 "*) groups="$groups $1" ;;
				*)
					printf 'Unknown group: %s\n\n' "$1" >&2
					usage >&2
					exit 2
					;;
			esac
			;;
	esac
	shift
done
[ -n "$groups" ] || groups=" $all_groups"

target_home=${DOTFILES_TARGET_HOME:-${HOME:-}}
if [ -z "$target_home" ] || [ ! -d "$target_home" ]; then
	printf 'The target home must name an existing directory.\n' >&2
	exit 1
fi
target_home=$(CDPATH='' cd -P "$target_home" && pwd)
src_dir=${DOTFILES_SRC_DIR:-$target_home/src}

os=$(uname -s)
is_wsl=false
if [ "$os" = Linux ] && grep -qi microsoft /proc/version 2>/dev/null; then
	is_wsl=true
fi

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT

want() {
	case "$groups " in
		*" $1 "*) return 0 ;;
		*) return 1 ;;
	esac
}

have() {
	command -v "$1" >/dev/null 2>&1
}

has_user_systemd() {
	# systemctl --user acts on the real user session, so only manage units
	# when installing into that user's own home.
	[ "$target_home" = "$(CDPATH='' cd -P "$HOME" && pwd)" ] &&
		[ "$os" = Linux ] && have systemctl &&
		systemctl --user show-environment >/dev/null 2>&1
}

# Replace __HOME__ and __USER__ placeholders. Writes to stdout.
render() {
	home_escaped=$(printf '%s' "$target_home" | sed 's/[\\&|]/\\&/g')
	user_escaped=$(printf '%s' "${USER:-$(id -un)}" | sed 's/[\\&|]/\\&/g')
	sed -e "s|__HOME__|$home_escaped|g" -e "s|__USER__|$user_escaped|g" "$1"
}

# ---------------------------------------------------------------------------
# Planning: every install_* call records one action. Nothing is changed until
# the whole plan is known, so a conflict prompt happens once, up front.
# Each action is "kind<TAB>source<TAB>destination".
# ---------------------------------------------------------------------------

actions=()
conflicts=0
tab=$(printf '\t')

add_action() {
	actions+=("$1$tab$2$tab$3")
}

# install_link SOURCE [DESTINATION]: symlink a repository path into $HOME.
install_link() {
	source_path="$script_dir/$1"
	destination="$target_home/${2:-$1}"

	if [ ! -e "$source_path" ]; then
		printf 'Missing source file: %s\n' "$source_path" >&2
		exit 1
	fi

	if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source_path" ]; then
		add_action unchanged "$source_path" "$destination"
		return
	fi
	if [ -e "$destination" ] || [ -L "$destination" ]; then
		conflicts=$((conflicts + 1))
		add_action backup-link "$source_path" "$destination"
	else
		add_action link "$source_path" "$destination"
	fi
}

# install_external TARGET DESTINATION: symlink a path outside the repository
# (for example a skill that lives in another project checkout), when present.
install_external() {
	source_path=$1
	destination="$target_home/$2"

	if [ ! -e "$source_path" ]; then
		add_action skip "$source_path" "$destination"
		return
	fi
	if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source_path" ]; then
		add_action unchanged "$source_path" "$destination"
		return
	fi
	if [ -e "$destination" ] || [ -L "$destination" ]; then
		conflicts=$((conflicts + 1))
		add_action backup-link "$source_path" "$destination"
	else
		add_action link "$source_path" "$destination"
	fi
}

# install_seed SOURCE [DESTINATION]: copy a rendered file that the owning tool
# rewrites at runtime. Existing files are kept unless --update-seeds.
install_seed() {
	source_path="$script_dir/$1"
	destination="$target_home/${2:-$1}"
	rendered="$work_dir/seed.$((${#actions[@]} + 1))"

	if [ ! -f "$source_path" ]; then
		printf 'Missing source file: %s\n' "$source_path" >&2
		exit 1
	fi
	render "$source_path" > "$rendered"

	if [ -L "$destination" ] || { [ -e "$destination" ] && [ ! -f "$destination" ]; }; then
		conflicts=$((conflicts + 1))
		add_action backup-copy "$rendered" "$destination"
	elif [ ! -e "$destination" ]; then
		add_action copy "$rendered" "$destination"
	elif cmp -s "$rendered" "$destination"; then
		add_action unchanged "$rendered" "$destination"
	elif $update_seeds; then
		conflicts=$((conflicts + 1))
		add_action backup-copy "$rendered" "$destination"
	else
		add_action keep "$rendered" "$destination"
	fi
}

# install_system SOURCE DESTINATION: copy a rendered file outside $HOME with
# sudo. Used only by opt-in groups.
install_system() {
	source_path="$script_dir/$1"
	destination=$2
	rendered="$work_dir/system.$((${#actions[@]} + 1))"

	render "$source_path" > "$rendered"
	if [ -f "$destination" ] && cmp -s "$rendered" "$destination"; then
		add_action unchanged "$rendered" "$destination"
	else
		add_action sudo-copy "$rendered" "$destination"
	fi
}

# ---------------------------------------------------------------------------
# Manifest. This is the complete install surface: adding a file to the
# repository does not make bootstrap install it.
# ---------------------------------------------------------------------------

if want shell; then
	install_link .bashrc
	install_link .zshrc
fi

if want git; then
	install_link .gitconfig
	install_link .config/git/ignore
fi

if want tmux; then
	install_link .tmux.conf
	install_link .tmux/status.sh
fi

if want vim; then
	install_link .vimrc
	install_link .vim/colors/tokyonight_custom.vim
fi

if want agents; then
	install_seed .claude/settings.json
	install_link .claude/statusline-command.sh
	install_seed .codex/config.toml
	install_seed .codex/rules/default.rules
	install_seed .config/opencode/opencode.jsonc
	install_seed .pi/agent/settings.json
	install_seed .config/agent-deck/config.toml
fi

if want skills; then
	install_link skills/loopy .agents/skills/loopy
	install_link skills/wacli .agents/skills/wacli
	install_seed .agents/.skill-lock.json

	install_link skills/loopy .claude/skills/loopy
	install_link skills/wacli .claude/skills/wacli
	install_external "$src_dir/pdfpal/skills/pdfpal-cli" .claude/skills/pdfpal-cli
	install_external "$src_dir/saldo/skills/saldo-cli" .claude/skills/saldo-cli

	install_link skills/wacli .codex/skills/wacli
	for skill in pluggy-doctor pluggy-integration pluggy-open-finance pluggy-payments; do
		install_link "skills/$skill" ".codex/skills/$skill"
	done
	install_external "$src_dir/pdfpal/skills/pdfpal-cli" .codex/skills/pdfpal-cli
	install_external "$src_dir/saldo/skills/saldo-cli" .codex/skills/saldo-cli
fi

if want tools; then
	install_seed .config/btop/btop.conf
	install_seed .config/htop/htoprc
fi

units=""
if want services; then
	if has_user_systemd; then
		if [ -x "$target_home/.local/bin/agent-deck" ]; then
			install_seed .config/systemd/user/agent-deck-autoupdate.service
			install_seed .config/systemd/user/agent-deck-autoupdate.timer
			units="$units agent-deck-autoupdate.timer"
		else
			printf 'note: skipping agent-deck units (~/.local/bin/agent-deck not found)\n'
		fi
		if [ -d "$src_dir/saldo" ]; then
			install_seed .config/systemd/user/saldo.service
			units="$units saldo.service"
		else
			printf 'note: skipping saldo.service (%s/saldo not found)\n' "$src_dir"
		fi
	else
		printf 'note: skipping services (needs Linux, a systemd user session, and the real home)\n'
	fi
fi

if want wsl-ssh; then
	if ! $is_wsl; then
		printf 'The wsl-ssh group only applies inside WSL.\n' >&2
		exit 1
	fi
	install_system wsl/ssh/10-wsl-lan.conf /etc/ssh/sshd_config.d/10-wsl-lan.conf
	install_system wsl/ssh/10-ipv4-only.conf /etc/systemd/system/ssh.socket.d/10-ipv4-only.conf
fi

# ---------------------------------------------------------------------------
# Confirmation
# ---------------------------------------------------------------------------

if [ "$conflicts" -gt 0 ] && ! $force && ! $dry_run; then
	printf '%s existing file(s) will be moved to ~/.dotfiles-backup. Continue? [y/N] ' "$conflicts"
	read -r reply
	case "$reply" in
		[yY]|[yY][eE][sS]) ;;
		*)
			printf 'Cancelled.\n'
			exit 1
			;;
	esac
fi

# ---------------------------------------------------------------------------
# Execution
# ---------------------------------------------------------------------------

timestamp=$(date '+%Y%m%d-%H%M%S')
backup_root="$target_home/.dotfiles-backup/$timestamp"
kept_seeds=0
changed_units=false
changed_system=false

run() {
	if ! $dry_run; then
		"$@"
	fi
}

backup() {
	relative=${1#"$target_home"/}
	backup_path="$backup_root/$relative"
	printf 'backup    %s -> %s\n' "$1" "$backup_path"
	run mkdir -p "$(dirname "$backup_path")"
	run mv "$1" "$backup_path"
}

for action in "${actions[@]}"; do
	kind=${action%%"$tab"*}
	rest=${action#*"$tab"}
	source_path=${rest%%"$tab"*}
	destination=${rest#*"$tab"}

	case "$destination" in
		*/.config/systemd/user/*)
			case "$kind" in copy|backup-copy) changed_units=true ;; esac
			;;
	esac

	case "$kind" in
		unchanged)
			printf 'unchanged %s\n' "$destination"
			;;
		skip)
			printf 'skip      %s (%s not found)\n' "$destination" "$source_path"
			;;
		keep)
			printf 'keep      %s (differs from repo; see --update-seeds)\n' "$destination"
			kept_seeds=$((kept_seeds + 1))
			;;
		link|backup-link)
			[ "$kind" = backup-link ] && backup "$destination"
			printf 'link      %s -> %s\n' "$destination" "$source_path"
			run mkdir -p "$(dirname "$destination")"
			run ln -s "$source_path" "$destination"
			;;
		copy|backup-copy)
			[ "$kind" = backup-copy ] && backup "$destination"
			printf 'seed      %s\n' "$destination"
			run mkdir -p "$(dirname "$destination")"
			run cp "$source_path" "$destination"
			;;
		sudo-copy)
			printf 'sudo      %s\n' "$destination"
			if [ -f "$destination" ]; then
				run sudo cp "$destination" "$destination.dotfiles-backup-$timestamp"
			fi
			run sudo mkdir -p "$(dirname "$destination")"
			run sudo install -m 644 "$source_path" "$destination"
			changed_system=true
			;;
	esac
done

if [ -n "$units" ] && ! $dry_run; then
	if $changed_units; then
		systemctl --user daemon-reload
	fi
	# shellcheck disable=SC2086 # $units is a space-separated list
	systemctl --user enable $units >/dev/null 2>&1 &&
		printf 'enabled   %s\n' "$units" ||
		printf 'warning: could not enable%s\n' "$units" >&2
fi

if $changed_system && ! $dry_run; then
	sudo sshd -t
	sudo systemctl daemon-reload
	sudo systemctl restart ssh.socket 2>/dev/null || sudo systemctl restart ssh
	printf '\nsshd reconfigured. Run wsl/configure-ssh-portproxy.ps1 on Windows to expose it on the LAN.\n'
fi

if want shell && ! have zsh; then
	printf '\nNote: zsh is not installed; .zshrc was linked but cannot be used yet.\n'
fi
if want git && [ ! -f "$target_home/.gitconfig.local" ]; then
	printf 'Note: put machine-specific git settings in ~/.gitconfig.local.\n'
fi
if [ "$kept_seeds" -gt 0 ]; then
	printf '\n%s seeded file(s) differ from the repository and were kept.\n' "$kept_seeds"
	printf 'Compare with: ./bootstrap.sh --dry-run --update-seeds\n'
fi

if $dry_run; then
	printf '\nDry run complete. No files were changed.\n'
else
	printf '\nDotfiles installation complete.\n'
fi
