# ==============================================================================
# Bash shell helpers and prompt customisation
# ==============================================================================
#
# Sourced from ~/.bash_aliases.
#
# Provides:
#   - Custom coloured prompt with Git branch/status indicator
#   - Root-aware prompt colouring
#   - Debian package check helper: installed <package>
#   - Battery status helper: bat
#   - ANSI colour table helper: colors
#
# Notes:
#   - PROMPT_COMMAND rebuilds PS1 before each prompt.
#   - Basic ANSI colours are used on the Linux console.
#   - Brighter ANSI colours are used in most terminal emulators.
#
# ==============================================================================
#
# User-configurable settings
# ==============================================================================

# Battery warning thresholds used by bat().
# Values are percentages.
BATTERY_GREEN_THRESHOLD=60
BATTERY_YELLOW_THRESHOLD=30
# Battery is shown as red below BATTERY_YELLOW_THRESHOLD.


# Color of "@" in the prompt - blue for normal users, red for root
case "$TERM:$EUID" in
	linux:0)
		ATCLR="\[\e[0;31m\]"
		;;
	linux:*)
		ATCLR="\[\e[0;34m\]"
		;;
	*:0)
		ATCLR="\[\e[1;91m\]"
		;;
	*)
		ATCLR="\[\e[1;94m\]"
		;;
esac


# Check whether a Debian package is installed.
installed() {
	local package status apt_result

	package="$1"

	if [[ -z "$package" ]]; then
		printf "Need a package to check for...\n"
		printf "Usage: installed <nameofdebpackage>\n"
		return 1
	fi

	status="$(dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -c "ok installed")"

	if [[ "$status" -eq 1 ]]; then
		printf '\e[1;37m"\e[1;32m%s\e[1;37m"\e[0m is installed on this system...\n' "$package"
	else
		printf '\e[1;37m"\e[1;31m%s\e[1;37m"\e[0m is not installed on this system...\n\n' "$package"

		apt_result="$(apt-cache search "$package" | sed 15q)"
		if [[ -z "$apt_result" ]]; then
			printf "... and seems to be missing in the repo?...\n"
		else
			printf "Possible matches:\n%s\n" "$apt_result"
		fi
	fi
}


# Function that displays current battery charge and status. Supports both BAT0 and BAT1...
bat() {
	local bat capacity status color icon scolor
	local green yellow red blue reset
	local green_threshold="${BATTERY_GREEN_THRESHOLD:-60}"
	local yellow_threshold="${BATTERY_YELLOW_THRESHOLD:-30}"

	green='\033[0;32m'
	yellow='\033[1;33m'
	red='\033[0;31m'
	blue='\033[0;34m'
	reset='\033[0m'

	bat=$(find /sys/class/power_supply -maxdepth 1 -type l -name 'BAT*' | head -n 1)

	if [[ -z "$bat" || ! -r "$bat/capacity" || ! -r "$bat/status" ]]; then
		echo -e "${red}Battery: not found${reset}"
		return 1
	fi

	capacity=$(cat "$bat/capacity")
	status=$(cat "$bat/status")

	if (( capacity >= green_threshold )); then
		color="$green"
	elif (( capacity >= yellow_threshold )); then
		color="$yellow"
	else
		color="$red"
	fi

	case "$status" in
		Charging)
			icon="⚡"
			scolor="$yellow"
			;;
		Discharging)
			icon="🔋"
			scolor="$red"
			;;
		Full)
			icon="✓"
			color="$green"
			scolor="$green"
			;;
		"Not charging")
			icon="⏸"
			color="$blue"
			scolor="$blue"
			;;
		*)
			icon="?"
			scolor="$reset"
			;;
	esac

	echo -e "Battery: ${color}${capacity}%${reset} - ${scolor}${status}${reset} ${icon}"
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


# Show Git alias summary.
galias() {
	cat <<'EOF'
Git aliases:

  gs        = git status
  ga        = git add
  gb        = git branch
  gc        = git commit -m
  gd        = git diff
  go        = git checkout

Git config aliases:

  git dc    = diff --cached
  git lol   = log --graph --decorate --pretty=oneline --abbrev-commit
  git lola  = log --graph --decorate --pretty=oneline --abbrev-commit --all
  git ls    = ls-files
  git ec    = config --global -e
  git amend = commit -a --amend
  git bdone = checkout default branch, update, then clean merged branches
EOF
}


## Colors....
## 40   Black                     | 100  Bright black / dark gray
## 41   Red                       | 101  Bright red
## 42   Green                     | 102  Bright green
## 43   Yellow / brown            | 103  Bright yellow
## 44   Blue                      | 104  Bright blue
## 45   Magenta / purple          | 105  Bright magenta / purple
## 46   Cyan                      | 106  Bright cyan
## 47   White / light gray        | 107  Bright white
##
## 30   Black text                | 90   Bright black / gray text
## 31   Red text                  | 91   Bright red text
## 32   Green text                | 92   Bright green text
## 33   Yellow text               | 93   Bright yellow text
## 34   Blue text                 | 94   Bright blue text
## 35   Magenta text              | 95   Bright magenta text
## 36   Cyan text                 | 96   Bright cyan text
## 37   White / light gray text   | 97   Bright white text


# Colorised git repo status, if inside a git repo.
_git_prompt() {
	local branch ansi status stash_marker

	git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return

	branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null)" ||
		branch="($(git describe --all --contains --abbrev=4 HEAD 2>/dev/null || echo HEAD))"

	stash_marker=''
	if git rev-parse --verify --quiet refs/stash >/dev/null; then
		stash_marker='*'
	fi

	# If branch is main/master/trunk, use a single space instead of writing branch name.
	case "$branch" in
		master|main|trunk)
			branch=' '
			;;
	esac

	status="$(git status --porcelain --untracked-files=normal 2>/dev/null)"

	if [[ -z "$status" ]]; then
		ansi=42			# Green: clean
	elif [[ -z "$(grep -v '^?? ' <<< "$status")" ]]; then
		ansi=43			# Yellow: only untracked files
	elif grep -qE '^(UU|AA|DD|AU|UA|DU|UD) ' <<< "$status"; then
		ansi=45			# Magenta: merge conflict
	else
		ansi=41			# Red: tracked changes
	fi

	echo -n '\[\e[0;37;'"$ansi"';1m\]'"$branch$stash_marker"'\[\e[0m\]'
}


# PROMPT_COMMAND runs before each prompt; use it to rebuild PS1 cleanly.
_prompt_command() {
	if [[ "$TERM" = "linux" ]]; then
		# Linux console: limited color support, so use safer basic ANSI colors.
		PS1="$(_git_prompt)\[\e[0;34m\][\[\e[0;36m\]\u$ATCLR@\[\e[0;36m\]\h\[\e[0;34m\]]\[\e[0;37m\]\w\[\e[0m\]> "
	else
		# Most terminal emulators: use bright colors.
		PS1="$(_git_prompt)\[\e[1;94m\][\[\e[1;96m\]\u$ATCLR@\[\e[1;96m\]\h\[\e[1;94m\]]\[\e[1;97m\]\w\[\e[0m\]> "
	fi
}


# Enable the dynamic prompt.
PROMPT_COMMAND='_prompt_command'
