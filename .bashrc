#!/bin/bash

# used for conditionalsfor empty input/new command
iatest=$(expr index "$-" i)

# source global definitions
if [ -f /etc/bashrc ]; then . /etc/bashrc; fi

# update based on window size
shopt -s checkwinsize

# stupid bell
if [[ $iatest > 0 ]]; then bind "set bell-style visible"; fi

# auto completion ignore case; more stable than nocaseglob
if [[ $iatest > 0 ]]; then bind "set completion-ignore-case on"; fi

# show history on first tab press
if [[ $iatest > 0 ]]; then bind "set show-all-if-ambiguous On"; fi

# history
export HISTCONTROL=erasedups:ignoredups:ignorespace:ignoreboth
export HISTFILESIZE=10000
export HISTSIZE=500

# async terminal history
shopt -s histappend
PROMPT_COMMAND='history -a'

# ctrl-R search history
stty -ixon

# enable history regex quick lookup
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# Reset
Color_Off='\e[0m'       # Text Reset

# Regular Colors
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White

# Bold
BBlack='\e[1;30m'       # Black
BRed='\e[1;31m'         # Red
BGreen='\e[1;32m'       # Green
BYellow='\e[1;33m'      # Yellow
BBlue='\e[1;34m'        # Blue
BPurple='\e[1;35m'      # Purple
BCyan='\e[1;36m'        # Cyan
BWhite='\e[1;37m'       # White

# Underline
UBlack='\e[4;30m'       # Black
URed='\e[4;31m'         # Red
UGreen='\e[4;32m'       # Green
UYellow='\e[4;33m'      # Yellow
UBlue='\e[4;34m'        # Blue
UPurple='\e[4;35m'      # Purple
UCyan='\e[4;36m'        # Cyan
UWhite='\e[4;37m'       # White

# Background
On_Black='\e[40m'       # Black
On_Red='\e[41m'         # Red
On_Green='\e[42m'       # Green
On_Yellow='\e[43m'      # Yellow
On_Blue='\e[44m'        # Blue
On_Purple='\e[45m'      # Purple
On_Cyan='\e[46m'        # Cyan
On_White='\e[47m'       # White

# High Intensity
IBlack='\e[0;90m'       # Black
IRed='\e[0;91m'         # Red
IGreen='\e[0;92m'       # Green
IYellow='\e[0;93m'      # Yellow
IBlue='\e[0;94m'        # Blue
IPurple='\e[0;95m'      # Purple
ICyan='\e[0;96m'        # Cyan
IWhite='\e[0;97m'       # White

# Bold High Intensity
BIBlack='\e[1;90m'      # Black
BIRed='\e[1;91m'        # Red
BIGreen='\e[1;92m'      # Green
BIYellow='\e[1;93m'     # Yellow
BIBlue='\e[1;94m'       # Blue
BIPurple='\e[1;95m'     # Purple
BICyan='\e[1;96m'       # Cyan
BIWhite='\e[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\e[0;100m'   # Black
On_IRed='\e[0;101m'     # Red
On_IGreen='\e[0;102m'   # Green
On_IYellow='\e[0;103m'  # Yellow
On_IBlue='\e[0;104m'    # Blue
On_IPurple='\e[0;105m'  # Purple
On_ICyan='\e[0;106m'    # Cyan
On_IWhite='\e[0;107m'   # White

# Various variables you might want for your PS1 prompt instead
Time12h="\T"
Time12a="\@"
PathShort="\w"
PathFull="\W"
NewLine="\n"
Jobs="\j"

# git terminal colors and text
export PS1=$IBlack$Time12h$Color_Off'$(git branch &>/dev/null;\
if [ $? -eq 0 ]; then \
  echo "$(echo `git status` | grep "nothing to commit" > /dev/null 2>&1; \
  if [ "$?" -eq "0" ]; then \
    # @4 - Clean repository - nothing to commit
    echo "'$Green'" $(git branch 2>/dev/null | grep '^*' | cut -c 1-2 -complement); \
  else \
    # @5 - Changes to working tree
    echo "'$IRed'" $(git branch 2>/dev/null | grep '^*' | cut -c 1-2 -complement); \
  fi) '$BCyan$PathShort$Color_Off'\$ "; \
else \
  # @2 - Prompt when not in GIT repo
  echo " '$Cyan$PathShort$Color_Off'\$ "; \
fi)'

# defaults
export EDITOR=vim
export VISUAL=gvim

# aliases

# - grep
alias cgrep='grep --color=always -n -r'
alias hgrep='history | cgrep'
alias fgrep='find . | cgrep'
unset GREP_OPTIONS # GREP_OPTIONS deprecated

# - vim
alias vim='gvim -v' # so clipboard works
alias evrc='gvim -v ~/.vimrc'

# - bashrc
alias ebrc='vim ~/.bashrc'
alias sbrc='source ~/.bashrc && echo -e "${Cyan}Sourced ~/.bashrc..."'

# - shortcuts
alias c='clear'
alias h='history'
alias dnf='sudo dnf'
alias null=’/dev/null’
alias echo='echo -e'
alias fbrowser='nautilus --browser'
alias open='xdg-open'
alias cd..='cd ..' # for typos

# time and date
alias time='timedatectl'
alias date='date "+%Y-%m-%d %A %T %Z"'

# - system
alias diskspace="du -S | sort -n -r |more"
alias set-headphones='pactl set-sink-port 8 analog-output-headphones'
alias set-speakers='pactl set-sink-port 8 analog-output-lineout'

# - maintenance
alias clear-errors='sudo rm /var/crash/*'
alias backup-system='sudo rsync -aAXv / --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} /run/media/acarlisle/Transcend/fedora32-backup'
alias restore-system='sudo rsync -aAXv /run/media/acarlisle/Transcend/fedora32-backup --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} /'

# functions
# - cd wrappers
function cdup() {
	local workingdir=$PWD
	cd $(printf '%0.s../' $(seq 1 $1 ))
	echo "${Blue}Moved Up: $1 dir(s) from '$workingdir' to '$PWD'..."
	ls
}
alias cdpop='cd "$OLDPWD"'

# Copy and go to the directory
function cpop() {
	if [ -d "$2" ]; then
		cp $1 $2 && cd $2
	else
		cp $1 $2
	fi
}

# Move and go to the directory
function mvpop() {
	if [ -d "$2" ];then
		mv $1 $2 && cd $2
	else
		mv $1 $2
	fi
}

# Create and go to the directory
function mkdirpop() {
	mkdir -p $1
	cd $1
}
