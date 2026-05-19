# ==============================================================================
# Bash aliases
# ==============================================================================
#
# Sourced from ~/.bashrc.
#
# Provides:
#   - Colour-aware aliases for common commands
#   - Git shortcuts
#   - Loading of optional extension/helper files
#
# ==============================================================================


# Enable colour support for common commands, if dircolors is available.
if [[ -x /usr/bin/dircolors ]]; then
	if [[ -r ~/.dircolors ]]; then
		eval "$(dircolors -b ~/.dircolors)"
	else
		eval "$(dircolors -b)"
	fi

	alias dir='dir --color=auto'
	alias vdir='vdir --color=auto'

	alias grep='grep --color=auto'
	alias fgrep='grep -F --color=auto'
	alias egrep='grep -E --color=auto'
fi


# Common ls aliases.
alias ll='ls -lAh'
alias l='ls -CF'


# Human-readable dmesg output.
alias dmesg='dmesg -H'


# Git aliases.
alias gs='git status'
alias ga='git add'
alias gb='git branch'
alias gc='git commit -m'
alias gd='git diff'
alias go='git checkout'
alias gk='gitk --all &'
alias gx='gitx --all'


# Load optional local extensions.
[[ -f ~/.bash_ext ]] && source ~/.bash_ext

# Load larger Bash functions and prompt customisation.
[[ -f ~/.bash_functions ]] && source ~/.bash_functions
