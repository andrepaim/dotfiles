#!/usr/bin/env bash
#
# End-to-end test for bootstrap.sh against a throwaway home directory.
# Runs locally or in CI. Set BASH_BIN=/bin/bash on macOS to exercise Bash 3.2.

# Single-quoted $ in sh -c helpers is intentional: the inner shell expands it.
# shellcheck disable=SC2016

set -eu

repo=$(CDPATH='' cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
bash_bin=${BASH_BIN:-bash}
test_home=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX")
test_home=$(CDPATH='' cd -P "$test_home" && pwd)
log="$test_home/.bootstrap.log"
trap 'rm -rf "$test_home"' EXIT

failures=0
pass() { printf 'ok    %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1" >&2; failures=$((failures + 1)); }
check() {
	description=$1
	shift
	if "$@"; then pass "$description"; else fail "$description"; fi
}

bootstrap() {
	DOTFILES_TARGET_HOME="$test_home" DOTFILES_SRC_DIR="$test_home/src" \
		"$bash_bin" "$repo/bootstrap.sh" "$@"
}

snapshot() {
	(cd "$test_home" && find . -path ./.bootstrap.log -prune -o -print | LC_ALL=C sort)
}

is_wsl=false
if grep -qi microsoft /proc/version 2>/dev/null; then
	is_wsl=true
fi
platform=$(uname -s)
$is_wsl && platform="$platform, WSL"
printf 'bootstrap test: bash %s (%s)\n\n' "$("$bash_bin" -c 'echo "$BASH_VERSION"')" "$platform"

# CI sets EXPECT_WSL=1 on the WSL job so a silent fallback to plain Linux fails.
if [ "${EXPECT_WSL:-}" = 1 ]; then
	check 'running inside WSL' $is_wsl
fi

# Pre-existing state: a file to back up, a seed to keep, one external skill.
printf 'old bashrc\n' > "$test_home/.bashrc"
mkdir -p "$test_home/.claude" "$test_home/src/saldo/skills/saldo-cli"
printf '{"old": true}\n' > "$test_home/.claude/settings.json"

# --- argument handling ------------------------------------------------------
status=0; bootstrap --bogus >/dev/null 2>&1 || status=$?
check 'unknown option exits 2' [ "$status" -eq 2 ]
status=0; bootstrap nosuchgroup >/dev/null 2>&1 || status=$?
check 'unknown group exits 2' [ "$status" -eq 2 ]
bootstrap_quiet() { bootstrap "$@" >/dev/null 2>&1; }
check '--help succeeds' bootstrap_quiet --help
if $is_wsl; then
	# Plan only: executing the group needs sudo and reconfigures sshd.
	bootstrap --dry-run wsl-ssh > "$log" 2>&1 || true
	check 'wsl-ssh plans the sshd drop-in' \
		grep -q '/etc/ssh/sshd_config.d/10-wsl-lan.conf' "$log"
	check 'wsl-ssh plans the ssh.socket drop-in' \
		grep -q '/etc/systemd/system/ssh.socket.d/10-ipv4-only.conf' "$log"
else
	status=0; bootstrap wsl-ssh >/dev/null 2>&1 || status=$?
	check 'wsl-ssh refuses outside WSL' [ "$status" -eq 1 ]
fi

# --- dry run ----------------------------------------------------------------
before=$(snapshot)
bootstrap --dry-run > "$log"
check 'dry run leaves the home untouched' [ "$before" = "$(snapshot)" ]
check 'dry run reports pending links' grep -q '^link ' "$log"

# --- declining the conflict prompt ----------------------------------------
status=0; printf 'n\n' | bootstrap > "$log" 2>&1 || status=$?
check 'declined prompt exits 1' [ "$status" -eq 1 ]
check 'declined prompt changes nothing' [ "$before" = "$(snapshot)" ]

# --- install ----------------------------------------------------------------
bootstrap --force > "$log"

links_ok=true
while IFS= read -r line; do
	destination=${line#link      }
	destination=${destination%% -> *}
	source_path=${line##* -> }
	if [ ! -L "$destination" ] || [ "$(readlink "$destination")" != "$source_path" ] ||
		[ ! -e "$destination" ]; then
		printf '      bad link: %s\n' "$destination" >&2
		links_ok=false
	fi
done < <(grep '^link ' "$log")
check 'every link points at its source and resolves' $links_ok
check 'links were created' grep -q '^link ' "$log"

seeds_ok=true
while IFS= read -r line; do
	destination=${line#seed      }
	if [ ! -f "$destination" ] || [ -L "$destination" ] ||
		grep -q '__HOME__\|__USER__' "$destination"; then
		printf '      bad seed: %s\n' "$destination" >&2
		seeds_ok=false
	fi
done < <(grep '^seed ' "$log")
check 'every seed is a rendered regular file' $seeds_ok
check 'codex config rendered with the target home' \
	grep -q "source = \"$test_home/.codex/" "$test_home/.codex/config.toml"

check 'existing .bashrc was backed up' \
	grep -qx 'old bashrc' "$test_home"/.dotfiles-backup/*/.bashrc
check 'differing seed was kept' grep -q '"old": true' "$test_home/.claude/settings.json"
check 'present external skill was linked' [ -L "$test_home/.claude/skills/saldo-cli" ]
check 'missing external skill was skipped' [ ! -e "$test_home/.claude/skills/pdfpal-cli" ]
check 'no systemd units for a non-real home' [ ! -e "$test_home/.config/systemd" ]

# --- idempotence ------------------------------------------------------------
installed=$(snapshot)
bootstrap > "$log"
check 'second run makes no changes' [ "$installed" = "$(snapshot)" ]
check 'second run reports nothing to do' \
	sh -c '! grep -qE "^(link|seed|backup) " "$1"' _ "$log"

# --- --update-seeds ---------------------------------------------------------
bootstrap --update-seeds --force > "$log"
check '--update-seeds replaces the differing seed' \
	cmp -s "$repo/.claude/settings.json" "$test_home/.claude/settings.json"
check '--update-seeds backs up the old seed' \
	sh -c 'grep -q "\"old\": true" "$1"/.dotfiles-backup/*/.claude/settings.json' _ "$test_home"

# --- installed configuration loads ----------------------------------------
loads_in() {
	env HOME="$test_home" ZDOTDIR="$test_home" "$1" -ic 'alias l' </dev/null >/dev/null 2>&1
}
check '.bashrc loads in an interactive bash' loads_in bash
if command -v zsh >/dev/null 2>&1; then
	check '.zshrc loads in an interactive zsh' loads_in zsh
fi
if command -v tmux >/dev/null 2>&1; then
	socket="dotfiles-test-$$"
	tmux_errors=$(env HOME="$test_home" tmux -L "$socket" -f /dev/null new-session -d \; \
		source-file "$test_home/.tmux.conf" 2>&1 || true)
	tmux -L "$socket" kill-server >/dev/null 2>&1 || true
	check '.tmux.conf sources without errors' [ -z "$tmux_errors" ]
fi
for section in cpu mem disk uptime; do
	check "tmux status.sh $section prints a value" \
		sh -c '[ -n "$("$1" "$2")" ]' _ "$test_home/.tmux/status.sh" "$section"
done
check 'claude status line renders' sh -c \
	'printf "%s" "{\"model\":{\"display_name\":\"Test\"},\"cwd\":\"/\"}" | bash "$1" | grep -q Test' \
	_ "$test_home/.claude/statusline-command.sh"

# Only in CI: locally this would overwrite the real clipboard.
if [ -n "${CI:-}" ]; then
	if $is_wsl; then
		check 'clip.exe is reachable from WSL' command -v clip.exe
	fi
	if command -v clip.exe >/dev/null 2>&1 || command -v pbcopy >/dev/null 2>&1; then
		check 'tmux clipboard helper copies' \
			sh -c 'printf dotfiles-ci | "$1" clipboard' _ "$test_home/.tmux/status.sh"
	fi
fi

printf '\n'
if [ "$failures" -gt 0 ]; then
	printf '%s check(s) failed.\n' "$failures" >&2
	exit 1
fi
printf 'All checks passed.\n'
