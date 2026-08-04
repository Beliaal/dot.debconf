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
#   - Git alias summary helper: galias
#
# Notes:
#   - PROMPT_COMMAND rebuilds PS1 before each prompt.
#   - Basic ANSI colours are used on the Linux console.
#   - Bold ANSI colours are used in most terminal emulators.
#
# ==============================================================================
#
# User-configurable settings
# ==============================================================================

# -----------------------------------------------------------------------------
# ANSI color constants
#
# Naming:
#   <color>      Regular
#   b_<color>    Bold
#   br_<color>   Bright
#   brb_<color>  Bright and bold
#
# These variables contain the actual escape sequences and can therefore be
# printed directly using printf with %s. When used in PS1, enclose them in
# \[ and \] so Readline does not count them as visible prompt characters.
# -----------------------------------------------------------------------------

reset=$'\e[0m'

# Regular colors
black=$'\e[0;30m'
red=$'\e[0;31m'
green=$'\e[0;32m'
yellow=$'\e[0;33m'
blue=$'\e[0;34m'
magenta=$'\e[0;35m'
cyan=$'\e[0;36m'
white=$'\e[0;37m'

# Bold colors
b_black=$'\e[1;30m'
b_red=$'\e[1;31m'
b_green=$'\e[1;32m'
b_yellow=$'\e[1;33m'
b_blue=$'\e[1;34m'
b_magenta=$'\e[1;35m'
b_cyan=$'\e[1;36m'
b_white=$'\e[1;37m'

# Bright colors
br_black=$'\e[0;90m'
br_red=$'\e[0;91m'
br_green=$'\e[0;92m'
br_yellow=$'\e[0;93m'
br_blue=$'\e[0;94m'
br_magenta=$'\e[0;95m'
br_cyan=$'\e[0;96m'
br_white=$'\e[0;97m'

# Bright and bold colors
brb_black=$'\e[1;90m'
brb_red=$'\e[1;91m'
brb_green=$'\e[1;92m'
brb_yellow=$'\e[1;93m'
brb_blue=$'\e[1;94m'
brb_magenta=$'\e[1;95m'
brb_cyan=$'\e[1;96m'
brb_white=$'\e[1;97m'

# Battery warning thresholds used by bat().
# Values are percentages.
BATTERY_GREEN_THRESHOLD=60
BATTERY_YELLOW_THRESHOLD=30
# Battery is shown as red below BATTERY_YELLOW_THRESHOLD.

# Detect the battery once when this file is sourced. This avoids scanning sysfs
# before every prompt on systems without a battery.
BATTERY_PATH=''
for power_supply in /sys/class/power_supply/BAT*; do
	if [[ -r "$power_supply/capacity" && -r "$power_supply/status" ]]; then
		BATTERY_PATH="$power_supply"
		break
	fi
done
unset power_supply


# Color of "@" in the prompt - blue for normal users, red for root.
# Use normal colours on the Linux console and bold colours elsewhere.
case "$TERM:$EUID" in
	linux:0)
		ATCLR="\[$red\]"
		;;
	linux:*)
		ATCLR="\[$blue\]"
		;;
	*:0)
		ATCLR="\[$b_red\]"
		;;
	*)
		ATCLR="\[$b_blue\]"
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
		printf '%s"%s%s%s"%s is installed on this system...\n' \
			"$b_white" "$b_green" "$package" "$b_white" "$reset"
	else
		printf '%s"%s%s%s"%s is not installed on this system...\n\n' \
			"$b_white" "$b_red" "$package" "$b_white" "$reset"

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
	local bat capacity status color icon scolor prompt_mode
	local green_threshold="${BATTERY_GREEN_THRESHOLD:-60}"
	local yellow_threshold="${BATTERY_YELLOW_THRESHOLD:-30}"

	prompt_mode=false
	[[ "${1:-}" == "--prompt" ]] && prompt_mode=true

	bat="${BATTERY_PATH:-}"

	if [[ -z "$bat" || ! -r "$bat/capacity" || ! -r "$bat/status" ]]; then
		$prompt_mode && return 1
		printf '%sBattery: not found%s\n' "$red" "$reset"
		return 1
	fi

	capacity=$(cat "$bat/capacity")

	if (( capacity >= green_threshold )); then
		color="$green"
	elif (( capacity >= yellow_threshold )); then
		color="$yellow"
	else
		color="$red"
	fi

	if $prompt_mode; then
		# Readline needs non-printing colour sequences enclosed in \[ and \].
		printf '\\[%s\\]%d%%\\[%s\\]\\[%s\\]|\\[%s\\]' "$color" "$capacity" "$reset" "$br_white" "$reset"
		return
	fi

	status=$(cat "$bat/status")

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

	printf 'Battery: %s%d%%%s | %s%s%s %s\n' \
		"$color" "$capacity" "$reset" "$scolor" "$status" "$reset" "$icon"
}


# Show battery information in PS1 only on systems with a readable battery.
_battery_prompt() {
	bat --prompt 2>/dev/null || :
}


# Display ANSI colour codes and examples.
colors() {
	local code

	printf "ANSI colour codes\n"
	printf "=================\n\n"

	printf "Foreground text colours:\n"
	for code in {30..37} {90..97}; do
		printf "  %-3s  \e[%smTEXT\e[0m\n" "$code" "$code"
	done

	printf "\nBackground colours:\n"
	for code in {40..47} {100..107}; do
		printf "  %-3s  \e[37;%sm TEXT \e[0m\n" "$code" "$code"
	done

	printf "\nCommon style codes:\n"
	printf "  0    reset / normal\n"
	printf "  1    bold / bright\n"
	printf "  4    underline\n\n"

	printf "Examples:\n"
	printf "  \\e[31mTEXT\\e[0m        red text\n"
	printf "  \\e[1;31mTEXT\\e[0m      bold red text\n"
	printf "  \\e[37;42mTEXT\\e[0m     white text on green background\n"
	printf "  \\e[1;97;41mTEXT\\e[0m   bright white text on red background\n"
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


# Colorised git repo status, if inside a git repo.
_git_prompt() {
	local branch ansi status stash_marker

	git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return

	branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null)" ||
		branch="($(git describe --all --contains --abbrev=4 HEAD 2>/dev/null || echo HEAD))"

	# Add a small marker if this repository has stashed changes.
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
	elif grep -qE '^(UU|AA|DD|AU|UA|DU|UD) ' <<< "$status"; then
		ansi=45			# Magenta: merge conflict
	elif [[ -z "$(grep -v '^?? ' <<< "$status")" ]]; then
		ansi=43			# Yellow: only untracked files
	else
		ansi=41			# Red: tracked changes
	fi

	printf '\\[%s\e[%sm\\]%s\\[%s\\]' \
		"$b_white" "$ansi" "$branch$stash_marker" "$reset"
}


# PROMPT_COMMAND runs before each prompt; use it to rebuild PS1 cleanly.
_prompt_command() {
	local battery_prompt

	battery_prompt=''
	if [[ -n "${BATTERY_PATH:-}" ]]; then
		battery_prompt="$(_battery_prompt)"
	fi

	if [[ "$TERM" = "linux" ]]; then
		# Linux console: limited color support, so use normal ANSI colours.
		PS1="$(_git_prompt)\[$blue\][${battery_prompt}\[$cyan\]\u$ATCLR@\[$cyan\]\h\[$blue\]]\[$white\]\w\[$reset\]> "
	else
		# Most terminal emulators: use the bold variants of the same colours.		
		PS1="$(_git_prompt)\[$b_blue\][${battery_prompt}\[$b_cyan\]\u$ATCLR@\[$b_cyan\]\h\[$b_blue\]]\[$b_white\]\w\[$reset\]> "
	fi
}


# Enable the dynamic prompt.
PROMPT_COMMAND='_prompt_command'
