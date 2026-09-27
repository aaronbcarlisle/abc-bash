# shellcheck shell=bash
# ~/.bashrc

# source global definitions
[ -f /etc/bashrc ] && . /etc/bashrc

# ---------------------------------------------------------------------------
# environment (set before the interactive check so scripts and tools see it)
# ---------------------------------------------------------------------------

export EDITOR=vim
# gvim forks and returns immediately unless given -f, which makes git commit,
# crontab -e and sudoedit see an empty file; fall back to vim where there is
# no gvim (e.g. Git Bash)
if command -v gvim >/dev/null 2>&1; then
	export VISUAL='gvim -f'
else
	export VISUAL=vim
fi

# ---------------------------------------------------------------------------
# everything below is for interactive shells only
# ---------------------------------------------------------------------------
[[ $- != *i* ]] && return

# readline settings (bell, completion, arrow-key history search) live in
# ~/.inputrc so they need no interactive guard

# free up Ctrl-S for forward history search (disables XON/XOFF flow control)
stty -ixon 2>/dev/null

# ---------------------------------------------------------------------------
# history
# ---------------------------------------------------------------------------
export HISTCONTROL=ignoreboth:erasedups   # ignoreboth = ignorespace + ignoredups
export HISTSIZE=10000                     # entries kept in memory
export HISTFILESIZE=10000                 # entries kept in ~/.bash_history
export HISTTIMEFORMAT='%F %T '            # timestamps in `history` output
shopt -s histappend                       # append to the file, don't overwrite

# ---------------------------------------------------------------------------
# colors
# $'...' stores the real escape byte, so these work in printf, echo and PS1
# without needing echo -e
# ---------------------------------------------------------------------------
Color_Off=$'\e[0m'
Green=$'\e[0;32m'
Blue=$'\e[0;34m'
Cyan=$'\e[0;36m'
BCyan=$'\e[1;36m'
IBlack=$'\e[0;90m'
IRed=$'\e[0;91m'

# ---------------------------------------------------------------------------
# prompt
# rebuilt before every prompt via PROMPT_COMMAND. every color code sits inside
# \[ \] so readline knows it takes no screen space. the branch goes in through
# ${__git_branch} rather than being pasted into PS1 so a branch name is never
# re-expanded as shell code.
#
# PS1 escapes:  \T = 12h time   \w = full path (~ abbreviated)   \W = basename
# ---------------------------------------------------------------------------
__set_prompt() {
	PS1='\['"$IBlack"'\]\T\['"$Color_Off"'\]'

	# symbolic-ref works in a fresh repo with no commits; rev-parse covers a
	# detached HEAD by showing the short hash; both fail outside a repo
	if __git_branch=$(git symbolic-ref --short -q HEAD 2>/dev/null ||
	                  git rev-parse --short HEAD 2>/dev/null); then
		# add -uno to the status call if untracked files shouldn't count as dirty
		if [[ -z $(git status --porcelain 2>/dev/null) ]]; then
			PS1+='\['"$Green"'\]'    # clean
		else
			PS1+='\['"$IRed"'\]'     # uncommitted changes
		fi
		PS1+=' ${__git_branch} \['"$BCyan"'\]\w\['"$Color_Off"'\]\$ '
	else
		PS1+=' \['"$Cyan"'\]\w\['"$Color_Off"'\]\$ '
	fi
}

# append to PROMPT_COMMAND instead of overwriting it, so Fedora's vte.sh
# (new terminal tabs open in the current directory) keeps working; the guard
# stops `sbrc` from adding it again on every re-source
if [[ $(declare -p PROMPT_COMMAND 2>/dev/null) == 'declare -a'* ]]; then
	if [[ ! ${PROMPT_COMMAND[*]} =~ __set_prompt ]]; then
		PROMPT_COMMAND+=('history -a; __set_prompt')
	fi
elif [[ $PROMPT_COMMAND != *__set_prompt* ]]; then
	PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }history -a; __set_prompt"
fi

# ---------------------------------------------------------------------------
# aliases
# ---------------------------------------------------------------------------

# - grep
# no -r on the piped versions: grep -r with no file searches the current
# directory and ignores stdin
alias cgrep='grep --color=auto -rn'
alias hgrep='history | grep --color=auto'
alias findgrep='find . | grep --color=auto'

# - vim
# on Fedora, vimx is the terminal vim built with clipboard support
command -v vimx >/dev/null 2>&1 && alias vim='vimx'
alias evrc='vim ~/.vimrc'
alias evimrc='vim ~/.vimrc'

# - bashrc
alias ebrc='vim ~/.bashrc'
alias ebashrc='vim ~/.bashrc'
alias sbrc='source ~/.bashrc && printf "%sSourced ~/.bashrc...%s\n" "$Cyan" "$Color_Off"'
alias sbashrc='sbrc'

# - claude
alias cld='claude'
alias cldanger='claude --dangerously-skip-permissions' # --channels plugin:telegram@claude-plugins-official'

# - shortcuts
alias c='clear'
alias h='history'
alias cd..='cd ..'   # for typos
alias cdpop='cd -'

# - time and date (renamed so the `time` keyword and `date` still work)
alias now='date "+%Y-%m-%d %A %T %Z"'

# - system
alias diskspace='du -h --max-depth=1 2>/dev/null | sort -rh | head -n 20'

# ---------------------------------------------------------------------------
# platform-specific
# ---------------------------------------------------------------------------
case "$OSTYPE" in
	msys*|cygwin*)
		# Git Bash on Windows
		if [ -d E:/Dev ]; then
			# cygpath gives E:/Dev's mount path (/e/Dev in Git Bash,
			# /cygdrive/e/Dev in Cygwin); CDPATH needs it because its entries
			# are colon-separated
			__dev=$(cygpath -u E:/Dev)
			# CDPATH lets you `cd <repo-name>` from anywhere
			CDPATH=.:$__dev:$__dev/repos:$__dev/projects
			alias cddev="cd $__dev"
			alias cdr="cd $__dev/repos"
			alias cdrepos="cd $__dev/repos"
			alias cdp="cd $__dev/projects"
			alias cdprojects="cd $__dev/projects"
			unset __dev
		fi
		alias open='start'
		;;
	linux*)
		alias dnf='sudo dnf'
		alias fbrowser='nautilus --browser'
		alias open='xdg-open'
		alias tdc='timedatectl'

		# @DEFAULT_SINK@ instead of a hard-coded index that changes between boots
		alias set-headphones='pactl set-sink-port @DEFAULT_SINK@ analog-output-headphones'
		alias set-speakers='pactl set-sink-port @DEFAULT_SINK@ analog-output-lineout'

		# Fedora records crashes via systemd-coredump, not /var/crash
		alias crashes='coredumpctl list'
		;;
esac

# ---------------------------------------------------------------------------
# functions
# ---------------------------------------------------------------------------

# move up N directories (default 1) and list the result
cdup() {
	local n=${1:-1} from=$PWD
	if [[ ! $n =~ ^[0-9]+$ ]] || (( n < 1 )); then
		printf 'usage: cdup [N]\n' >&2
		return 1
	fi
	cd "$(printf '../%.0s' $(seq "$n"))" || return
	printf '%sMoved up %s dir(s): %s -> %s%s\n' "$Blue" "$n" "$from" "$PWD" "$Color_Off"
	ls
}

# copy (files or directories, one or more sources), then cd into the
# destination if it is a directory
cpop() {
	cp -r -- "$@" && [[ -d ${!#} ]] && cd -- "${!#}"
}

# move one or more sources, then cd into the destination if it is a directory
mvpop() {
	mv -- "$@" || return
	if [[ -d ${!#} ]]; then
		cd -- "${!#}"
	fi
}

# create a directory (with parents) and cd into it
mkdirpop() {
	mkdir -p -- "$1" && cd -- "$1"
}
alias mkcd='mkdirpop'
