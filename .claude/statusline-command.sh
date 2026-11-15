#!/bin/bash
# Claude Code statusline mirroring the Codex tui.status_line layout.
input=$(cat)
j() { echo "$input" | jq -r "$1 // empty"; }

model=$(j '.model.display_name')
effort=$(j '.effort.level')
cwd=$(j '.workspace.current_dir // .cwd')
rem=$(j '.context_window.remaining_percentage')
five=$(j '.rate_limits.five_hour.used_percentage')
week=$(j '.rate_limits.seven_day.used_percentage')
vim=$(j '.vim.mode')

C='\033[36m'; G='\033[32m'; Y='\033[33m'; M='\033[35m'; B='\033[34m'; R='\033[00m'
sep=" | "
out=""
add() { [ -n "$out" ] && out="$out$sep"; out="$out$1"; }

m="${C}${model}"; [ -n "$effort" ] && m="$m $effort"; add "${m}${R}"
add "${B}${cwd/#$HOME/\~}${R}"
[ -n "$rem" ] && add "${G}ctx $(printf '%.0f' "$rem")% left${R}"
[ -n "$five" ] && add "${Y}5h $(printf '%.0f' "$five")%${R}"
[ -n "$week" ] && add "${Y}wk $(printf '%.0f' "$week")%${R}"

if branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null); then
  add "${M}${branch}${R}"
  n=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | wc -l)
  stat=$(git -C "$cwd" --no-optional-locks diff HEAD --shortstat 2>/dev/null)
  ins=$(echo "$stat" | grep -o '[0-9]* insertion' | grep -o '[0-9]*')
  del=$(echo "$stat" | grep -o '[0-9]* deletion' | grep -o '[0-9]*')
  if [ "$n" -gt 0 ]; then
    add "${Y}${n} changed ${G}+${ins:-0} \033[31m-${del:-0}${R}"
  fi
fi
[ -n "$vim" ] && add "$vim"
printf '%b' "$out"
