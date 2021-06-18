# Change the color of the "@" in the prompt to red if user is root.
if [[ $EUID -ne 0 ]]; then
	# UDI = !root, set color to Bold High Intensity Blue
	if [[ $TERM = "linux" ]]; then
		ATCLR="\[\e[0;34m\]"
	fi
	if [[ $TERM = "xterm" ]]; then
		ATCLR="\[\e[1;94m\]"
	fi
	if [[ $TERM = "xterm-256color" ]]; then
		ATCLR="\[\e[1;94m\]"
	fi
else
	# UDI = !root, set color to Bold High Intensity Blue
	if [[ $TERM = "linux" ]]; then
		ATCLR="\[\e[0;31m\]"
	fi
	if [[ $TERM = "xterm" ]]; then
		ATCLR="\[\e[1;91m\]"
	fi
	if [[ $TERM = "xterm-256color" ]]; then
		ATCLR="\[\e[1;91m\]"
	fi
fi

show_spinner() {
	local -r pid="${1}"
	local -r delay='0.75'
	local spinstr='\|/-'
	local temp
	while ps a | awk '{print $1}' | grep -q "${pid}"; do
		temp="${spinstr#?}"
		printf " [%c]  " "${spinstr}"
		spinstr=${temp}${spinstr%"${temp}"}
		sleep "${delay}"
		printf "\b\b\b\b\b\b"
	done
	printf "    \b\b\b\b"
}

# Update all update-files
update() {
	printf "\n"

	printf "\e[1;37mRunning \e[1;31mupdate-command-not-found\t\e[1;37m...\t\e[0m"
	if [[ ! $(sudo /usr/sbin/update-command-not-found >/dev/null 2>&1) ]]; then
		printf "\e[1;32mDone\e[1;37m!\e[0m\n"
	else
		printf "\e[1;31mFAILED...\e[0m\n"
	fi

	printf "\e[1;37mRunning \e[1;31mupdate-pciids\t\t\t\e[1;37m...\t\e[0m"
	if [[ ! $(sudo update-pciids >/dev/null 2>&1) ]]; then
		printf "\e[1;32mDone\e[1;37m!\e[0m\n"
	else
		printf "\e[1;31mFAILED \e[1;37m...\e[0m\n"
	fi

	printf "\e[1;37mRunning \e[1;31mupdate-usbids\t\t\t\e[1;37m...\t\e[0m"
	if [[ ! $(sudo update-usbids >/dev/null 2>&1) ]]; then
		printf "\e[1;32mDone\e[1;37m!\e[0m\n"
	else
		printf "\e[1;31mFAILED \e[1;37m...\e[0m\n"
	fi

	printf "\e[1;37mRunning \e[1;31mupdatedb\t\t\t\e[1;37m...\t\e[0m"
	if [[ ! $(sudo updatedb >/dev/null 2>&1) ]]; then
		printf "\e[1;32mDone\e[1;37m!\e[0m\n"
	else
		printf "\e[1;31m\tFAILED \e[1;37m...\e[0m\n"
	fi

	printf "\n"
}

# Check if a debian package is installed...
installed() {
	if [[ -n $1 ]]; then
		STATUS=$(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed")
		if [[ $STATUS -eq 1 ]]; then
			printf "\e[1;37m\"\e[1;32m$1\e[1;37m\"\e[0m is installed on this system... \n"
		else
			printf "\e[1;37m\"\e[1;31m$1\e[1;37m\"\e[0m is not installed on this system... \n\n"
			APTRESULT=$(apt-cache search $1 | sed 15q)
			if [[ -z $APTRESULT ]]; then
				printf "... and seems to be missing in the repo?..."
			fi
		fi
	else
		printf "Need a package to check for... \n"
		printf "Usage: installed <nameofdebpackage> \n"
	fi
}

# Create dir and directly enter it.
mcd() {
	mkdir -p $1
	cd $1
}

get_dir() {
	printf "%s" $(pwd | sed "s:$HOME:~:")
}

get_sha() {
	git rev-parse --short HEAD 2>/dev/null
}

# Bash function displays a table with ready-to-copy escape codes.
colors() {
	local fgc bgc vals seq0

	printf "Color escapes are %s\n" '\e[${value};...;${value}m'
	printf "Values 30..37 are \e[33mforeground colors\e[m\n"
	printf "Values 40..47 are \e[43mbackground colors\e[m\n"
	printf "Value  1 gives a  \e[1mbold-faced look\e[m\n\n"

	# foreground colors
	for fgc in {30..37}; do
		# background colors
		for bgc in {40..47}; do
			fgc=${fgc#37} # white
			bgc=${bgc#40} # black

			vals="${fgc:+$fgc;}${bgc}"
			vals=${vals%%;}

			seq0="${vals:+\e[${vals}m}"
			printf "  %-9s" "${seq0:-(default)}"
			printf " ${seq0}TEXT\e[m"
			printf " \e[${vals:+${vals+$vals;}}1mBOLD\e[m"
		done
		echo
		echo
	done
}

function _git_prompt() {
	local git_status="$(git status -unormal 2>&1)"
	if ! [[ "$git_status" =~ not\ a\ git\ repo ]]; then
		if [[ "$git_status" =~ nothing\ to\ commit ]]; then
			local ansi=42 # Green background
		#local ansi=102   # High Intensity Green background
		elif [[ "$git_status" =~ nothing\ added\ to\ commit\ but\ untracked\ files\ present ]]; then
			# local ansi=43   # Yellow background
			local ansi=103 # High Intensity Yellow background
		else
			local ansi=41 # Red background
		# local ansi=45   # Purple background
		# local ansi=101  # High Intensity Red background
		fi
		if [[ "$git_status" =~ On\ branch\ ([^[:space:]]+) ]]; then
			branch=${BASH_REMATCH[1]}
			test "$branch" != master || branch=' '
		else
			# Detached HEAD.  (branch=HEAD is a faster alternative.)
			branch="($(git describe --all --contains --abbrev=4 HEAD 2>/dev/null || echo HEAD))"
		fi
		echo -n '\[\e[0;37;'"$ansi"';1m\]'"$branch"'\[\e[0m\]'
	fi
}

function _prompt_command() {
	if [[ "$TERM" = "linux" ]]; then
		# Todo if we are at a "linux" type terminal (8/16 colors)
		PS1="$(_git_prompt)\[\e[0;34m\][\[\e[0;36m\]\u$ATCLR@\[\e[0;36m\]\h\[\e[0;34m\]]\[\e[0;37m\]\w\[\e[0m\]> "
	fi
	if [[ "$TERM" = "xterm" ]]; then
		# We support many colors! Ie, my vanilla prompt...
		PS1="$(_git_prompt)\[\e[1;94m\][\[\e[1;96m\]\u$ATCLR@\[\e[1;96m\]\h\[\e[1;94m\]]\[\e[1;97m\]\w\[\e[0m\]> "
	fi
	if [[ "$TERM" = "xterm-256color" ]]; then
		# We support 256 colors! Ie, my vanilla prompt...
		PS1="$(_git_prompt)\[\e[1;94m\][\[\e[1;96m\]\u$ATCLR@\[\e[1;96m\]\h\[\e[1;94m\]]\[\e[1;97m\]\w\[\e[0m\]> "
	fi
}

PROMPT_COMMAND=_prompt_command
