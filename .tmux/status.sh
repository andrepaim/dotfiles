#!/usr/bin/env bash

# tmux status and clipboard helper for WSL, Linux, and macOS.

case "$1" in
	cpu)
		if [ -r /proc/stat ]; then
			prev_file="${TMPDIR:-/tmp}/.tmux_cpu_prev_${UID:-$(id -u)}"
			read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
			total=$((user + nice + system + idle + iowait + irq + softirq + steal))
			idle_total=$((idle + iowait))

			if [ -r "$prev_file" ]; then
				read -r prev_total prev_idle < "$prev_file"
				diff_total=$((total - prev_total))
				diff_idle=$((idle_total - prev_idle))
				if [ "$diff_total" -gt 0 ]; then
					printf '%d%%' $((100 * (diff_total - diff_idle) / diff_total))
				else
					printf '0%%'
				fi
			else
				printf '%s' '--%'
			fi
			printf '%s %s\n' "$total" "$idle_total" > "$prev_file"
		elif [ "$(uname -s)" = Darwin ]; then
			top -l 2 -n 0 -s 1 2>/dev/null | awk '
				/CPU usage/ { idle = $7 }
				END { gsub(/%/, "", idle); printf "%.0f%%", 100 - idle }
			'
		else
			printf 'n/a'
		fi
		;;

	mem)
		if command -v free >/dev/null 2>&1; then
			free | awk '/Mem:/ { printf "%.0f%%", $3 / $2 * 100 }'
		elif command -v memory_pressure >/dev/null 2>&1; then
			memory_pressure 2>/dev/null | awk '
				/System-wide memory free percentage/ {
					gsub(/%/, "", $5); printf "%d%%", 100 - $5
				}
			'
		else
			printf 'n/a'
		fi
		;;

	disk)
		df -h / | awk 'NR == 2 { print $5 }'
		;;

	uptime)
		if uptime -p >/dev/null 2>&1; then
			uptime -p | sed 's/^up //; s/ hours\?/h/; s/ minutes\?/m/; s/ days\?/d/; s/,//g'
		elif [ "$(uname -s)" = Darwin ]; then
			boot_time=$(sysctl -n kern.boottime | awk -F'[=,]' '{ gsub(/ /, "", $2); print $2 }')
			now=$(date +%s)
			elapsed=$((now - boot_time))
			days=$((elapsed / 86400))
			hours=$(((elapsed % 86400) / 3600))
			minutes=$(((elapsed % 3600) / 60))
			[ "$days" -gt 0 ] && printf '%dd ' "$days"
			[ "$hours" -gt 0 ] && printf '%dh ' "$hours"
			printf '%dm' "$minutes"
		else
			printf 'n/a'
		fi
		;;

	git)
		dir=$2
		[ -n "$dir" ] || exit 0
		cd "$dir" 2>/dev/null || exit 0
		git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

		branch=$(git symbolic-ref --short HEAD 2>/dev/null)
		if [ -z "$branch" ]; then
			branch=$(git rev-parse --short HEAD 2>/dev/null) || exit 0
			branch=":$branch"
		fi

		dirty=
		[ -n "$(git status --porcelain 2>/dev/null | head -n 1)" ] && dirty='*'

		ahead_behind=
		upstream=$(git rev-parse --abbrev-ref '@{u}' 2>/dev/null)
		if [ -n "$upstream" ]; then
			ahead=$(git rev-list --count '@{u}..HEAD' 2>/dev/null)
			behind=$(git rev-list --count 'HEAD..@{u}' 2>/dev/null)
			[ "${ahead:-0}" -gt 0 ] && ahead_behind="${ahead_behind}+${ahead}"
			[ "${behind:-0}" -gt 0 ] && ahead_behind="${ahead_behind}-${behind}"
			[ -n "$ahead_behind" ] && ahead_behind=" $ahead_behind"
		fi

		printf ' %s%s%s' "$branch" "$dirty" "$ahead_behind"
		;;

	gpu)
		if command -v nvidia-smi >/dev/null 2>&1; then
			nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total \
				--format=csv,noheader,nounits 2>/dev/null | awk -F', ' '
				NR == 1 && $1 ~ /^[0-9]+([.][0-9]+)?$/ {
					printf " | GPU %s%% %.1fG/%.0fG", $1, $2 / 1024, $3 / 1024
				}
			'
		fi
		;;

	clipboard)
		if command -v clip.exe >/dev/null 2>&1; then
			clip.exe
		elif command -v pbcopy >/dev/null 2>&1; then
			pbcopy
		elif command -v wl-copy >/dev/null 2>&1; then
			wl-copy
		elif command -v xclip >/dev/null 2>&1; then
			xclip -selection clipboard -in
		elif command -v xsel >/dev/null 2>&1; then
			xsel --clipboard --input
		else
			printf 'No supported clipboard command found.\n' >&2
			exit 1
		fi
		;;

	*)
		printf 'usage: %s {cpu|mem|disk|uptime|gpu|git <path>|clipboard}\n' "$0" >&2
		exit 2
		;;
esac
