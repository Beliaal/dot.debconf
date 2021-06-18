# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
	test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
	alias ls='ls --color=auto'
	alias ll='ls -lAh'
	alias la='ls -A'
	alias l='ls -CA'
	alias grep='grep --color=auto'
	alias fgrep='fgrep --color=auto'
	alias egrep='egrep --color=auto'
#  alias dmesg='/bin/dmesg --color=always | less -R'
fi

# Replace top with htop if installed
#if [ -x /usr/bin/htop ]; then
#  alias top='htop'
#fi

# uconf alias
alias uconf='/usr/bin/git --git-dir=$HOME/.uconf/ --work-tree=$HOME'
alias uconfs='/usr/bin/git --git-dir=$HOME/.uconf/ --work-tree=$HOME status'
alias uconfa='/usr/bin/git --git-dir=$HOME/.uconf/ --work-tree=$HOME add'

# Two cd aliases
alias ..='cd ..'
alias ...='cd ../../'

# Alias to add or edit aliases
alias realias='nano ~/.bash_aliases && source ~/.bash_aliases'

# Alias to add or edit functions
alias refunct='nano ~/.bash_functions && source ~/.bash_functions'

# A few git aliases
alias galias="echo -e 'gs = git status\t\tga = git add \
\ngb = git branch\t\tgc = git commit -m \
\ngd = git diff\t\tgo = git checkout \
\n\ngit dc\t\t= diff --cached \
\ngit lol\t\t= log --graph --decorate --pretty=oneline --abbrev-commit \
\ngit lola\t= log --graph --decorate --pretty=oneline --abbrev-commit --all \
\ngit ls\t\t= ls-files \
\ngit ec\t\t= config --global -e \
\ngit ammend\t= commit -a --amend \
\ngit bdone\t= !f() { git checkout ${1-master} && git up && git bclean ${1-master}; }; f'"
alias gs='git status '
alias ga='git add '
alias gb='git branch '
alias gc='git commit -m'
alias gd='git diff'
alias go='git checkout '
alias gk='gitk --all&'
alias gx='gitx --all'

alias got='git '
alias get='git '

# Finish off by running the last files referenced in dot.debconf skel
[[ -f ~/.bash_ext ]] && source ~/.bash_ext
[[ -f ~/.bash_functions ]] && source ~/.bash_functions
