# Return immediately when the shell is not interactive.
[[ -o interactive ]] || return

# Keep useful history without recording duplicates.
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt append_history
setopt hist_ignore_all_dups
setopt hist_reduce_blanks
setopt share_history

# Enable completion and use the existing text as the search prefix when
# navigating command history.
autoload -Uz compinit
compinit
bindkey -e
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# Debian-style prompt matching the previous Bash prompt:
# user@host:working-directory$ (or # when running as root).
autoload -Uz colors
colors
if [[ "$TERM" == *-256color || "$TERM" == xterm-color ]]; then
	PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%(#.#.$) '
else
	PROMPT='%n@%m:%~%(#.#.$) '
fi

# Keep the terminal title synchronized with the current directory.
case "$TERM" in
	xterm*|rxvt*)
		precmd() { print -Pn '\e]0;%n@%m: %~\a' }
		;;
esac

# Familiar colored command output and directory-listing shortcuts. GNU `ls`
# uses `--color`; the BSD version shipped by macOS uses `-G`.
if (( $+commands[dircolors] )); then
	eval "$(dircolors -b)"
fi
if command ls --color=auto -d . >/dev/null 2>&1; then
	alias ls='ls --color=auto'
	alias grep='grep --color=auto'
	alias fgrep='fgrep --color=auto'
	alias egrep='egrep --color=auto'
elif [[ "$OSTYPE" == darwin* ]]; then
	alias ls='ls -G'
fi
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -lharS'

# User-installed tools. `path` is unique, so repeated sourcing does not add
# duplicate entries.
typeset -U path PATH
path=(
	"$HOME/.opencode/bin"
	"$HOME/bin"
	"$HOME/.npm-global/bin"
	"$HOME/.local/bin"
	$path
)
export PATH

if [[ -d "$HOME/android-sdk" ]]; then
	export ANDROID_HOME="$HOME/android-sdk"
elif [[ -d "$HOME/Library/Android/sdk" ]]; then
	export ANDROID_HOME="$HOME/Library/Android/sdk"
fi
