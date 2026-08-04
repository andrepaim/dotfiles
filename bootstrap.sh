#!/usr/bin/env bash

set -e

script_dir=$(CDPATH= cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
force=false
dry_run=false

usage() {
	cat <<'EOF'
Usage: ./bootstrap.sh [--dry-run] [--force]

Install the repository's zsh, tmux, and Vim configuration by linking an
explicit allowlist into $HOME.

  --dry-run  Print the actions without changing any files.
  --force    Skip confirmation when existing files need to be backed up.
  -h, --help Show this help text.
EOF
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		--dry-run)
			dry_run=true
			;;
		-f|--force)
			force=true
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			printf 'Unknown option: %s\n\n' "$1" >&2
			usage >&2
			exit 2
			;;
	esac
	shift
done

target_home=${DOTFILES_TARGET_HOME:-${HOME:-}}
if [ -z "$target_home" ] || [ ! -d "$target_home" ]; then
	printf 'The target home must name an existing directory.\n' >&2
	exit 1
fi

# This is the complete install surface. Adding any other repository file does
# not make bootstrap install it.
files=(
	.zshrc
	.tmux.conf
	.tmux/status.sh
	.vimrc
	.vim/colors/tokyonight_custom.vim
)

conflicts=0
for relative_path in "${files[@]}"; do
	source_path="$script_dir/$relative_path"
	destination="$target_home/$relative_path"

	if [ ! -e "$source_path" ]; then
		printf 'Missing source file: %s\n' "$source_path" >&2
		exit 1
	fi

	if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source_path" ]; then
		continue
	fi

	if [ -e "$destination" ] || [ -L "$destination" ]; then
		conflicts=$((conflicts + 1))
	fi
done

if [ "$conflicts" -gt 0 ] && ! $force && ! $dry_run; then
	printf '%s existing configuration file(s) will be backed up. Continue? [y/N] ' "$conflicts"
	read -r reply
	case "$reply" in
		[yY]|[yY][eE][sS]) ;;
		*)
			printf 'Cancelled.\n'
			exit 1
			;;
	esac
fi

timestamp=$(date '+%Y%m%d-%H%M%S')
backup_root="$target_home/.dotfiles-backup/$timestamp"

for relative_path in "${files[@]}"; do
	source_path="$script_dir/$relative_path"
	destination="$target_home/$relative_path"

	if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source_path" ]; then
		printf 'unchanged %s\n' "$destination"
		continue
	fi

	if [ -e "$destination" ] || [ -L "$destination" ]; then
		backup_path="$backup_root/$relative_path"
		printf 'backup    %s -> %s\n' "$destination" "$backup_path"
		if ! $dry_run; then
			mkdir -p "$(dirname "$backup_path")"
			mv "$destination" "$backup_path"
		fi
	fi

	printf 'link      %s -> %s\n' "$destination" "$source_path"
	if ! $dry_run; then
		mkdir -p "$(dirname "$destination")"
		ln -s "$source_path" "$destination"
	fi
done

if ! command -v zsh >/dev/null 2>&1; then
	printf '\nNote: zsh is not installed; .zshrc was linked but cannot be used yet.\n'
fi

printf '\nDotfiles installation complete.\n'
