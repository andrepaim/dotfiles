# ~/.bashrc: interactive bash configuration for WSL, Linux, and macOS.
# Mirrors ~/.zshrc so either shell feels the same.

# Return immediately when the shell is not interactive.
case $- in
	*i*) ;;
	*) return ;;
esac

# History: skip duplicates and space-prefixed commands, append instead of
# overwriting.
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend
shopt -s checkwinsize

# Make less friendlier for non-text input files (Debian/Ubuntu).
if command -v lesspipe >/dev/null 2>&1; then
	eval "$(SHELL=/bin/sh lesspipe)"
fi

# Debian-style prompt: user@host:working-directory$
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
	debian_chroot=$(cat /etc/debian_chroot)
fi
case "$TERM" in
	xterm-color|*-256color)
		PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
		;;
	*)
		PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
		;;
esac

# Keep the terminal title synchronized with the current directory.
case "$TERM" in
	xterm*|rxvt*)
		PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
		;;
esac

# Colored output. GNU `ls` uses `--color`; the BSD version on macOS uses `-G`.
if command -v dircolors >/dev/null 2>&1; then
	if [ -r ~/.dircolors ]; then
		eval "$(dircolors -b ~/.dircolors)"
	else
		eval "$(dircolors -b)"
	fi
fi
if command ls --color=auto -d . >/dev/null 2>&1; then
	alias ls='ls --color=auto'
	alias grep='grep --color=auto'
	alias fgrep='fgrep --color=auto'
	alias egrep='egrep --color=auto'
elif [ "$(uname -s)" = Darwin ]; then
	alias ls='ls -G'
fi
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -lharS'

# Desktop notification after long commands: `sleep 10; alert`
if command -v notify-send >/dev/null 2>&1; then
	alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
fi

if [ -f ~/.bash_aliases ]; then
	. ~/.bash_aliases
fi

# Programmable completion (Debian/Ubuntu, then Homebrew).
if ! shopt -oq posix; then
	for completion in \
		/usr/share/bash-completion/bash_completion \
		/etc/bash_completion \
		/opt/homebrew/etc/profile.d/bash_completion.sh \
		/usr/local/etc/profile.d/bash_completion.sh; do
		if [ -r "$completion" ]; then
			. "$completion"
			break
		fi
	done
	unset completion
fi

# Homebrew (macOS Apple Silicon, macOS Intel, Linuxbrew).
for brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
	if [ -x "$brew" ]; then
		eval "$("$brew" shellenv)"
		break
	fi
done
unset brew

# User-installed tools, first entry wins. Skips entries already on PATH so
# re-sourcing does not grow it.
export BUN_INSTALL="$HOME/.bun"
path_prepend() {
	case ":$PATH:" in
		*":$1:"*) ;;
		*) PATH="$1:$PATH" ;;
	esac
}
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.npm-global/bin"
path_prepend "$HOME/bin"
path_prepend "$HOME/.opencode/bin"
path_prepend "$BUN_INSTALL/bin"
unset -f path_prepend
export PATH

if [ -d "$HOME/android-sdk" ]; then
	export ANDROID_HOME="$HOME/android-sdk"
elif [ -d "$HOME/Library/Android/sdk" ]; then
	export ANDROID_HOME="$HOME/Library/Android/sdk"
fi

# Machine-specific additions that should not be committed.
if [ -f ~/.bashrc.local ]; then
	. ~/.bashrc.local
fi
