#!/bin/bash

# used for conditionals for empty input/new command
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
export HISTCONTROL=erasedups:ignoreboth
export HISTFILESIZE=10000
export HISTSIZE=500

# async terminal history
shopt -s histappend
PROMPT_COMMAND='history -a'

# ctrl-R search history
if [[ $iatest > 0 ]]; then stty -ixon; fi

# enable history regex quick lookup
if [[ $iatest > 0 ]]; then bind '"\e[A": history-search-backward'; fi
if [[ $iatest > 0 ]]; then bind '"\e[B": history-search-forward'; fi

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

# High Intensity
IBlack='\e[0;90m'       # Black
IRed='\e[0;91m'         # Red
IGreen='\e[0;92m'       # Green
IYellow='\e[0;93m'      # Yellow
IBlue='\e[0;94m'        # Blue
IPurple='\e[0;95m'      # Purple
ICyan='\e[0;96m'        # Cyan
IWhite='\e[0;97m'       # White

# Various variables you might want for your PS1 prompt instead
Time12h="\T"
PathShort="\w"

# git terminal colors and text
export PS1=$IBlack$Time12h$Color_Off'$(git branch &>/dev/null;\
if [ $? -eq 0 ]; then \
  echo "$(echo `git status` | grep "nothing to commit" > /dev/null 2>&1; \
  if [ "$?" -eq "0" ]; then \
    # @4 - Clean repository - nothing to commit
    echo "'$Green'" $(git branch 2>/dev/null | grep '^*' | cut -c 3-); \
  else \
    # @5 - Changes to working tree
    echo "'$IRed'" $(git branch 2>/dev/null | grep '^*' | cut -c 3-); \
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
alias findgrep='find . | cgrep'

# - bashrc
alias ebrc='vim ~/.bashrc'
alias sbrc='source ~/.bashrc && echo -e "${Cyan}Sourced ~/.bashrc..."'

# - shortcuts
alias c='clear'
alias h='history'
alias dnf='sudo dnf'
alias echo='echo -e'
alias fbrowser='nautilus --browser'
alias open='xdg-open'
alias cd..='cd ..' # for typos

# time and date
alias time='timedatectl'
alias date='date "+%Y-%m-%d %A %T %Z"'

# - system
alias diskspace="du -S | sort -n -r |more"

# functions
# - cd wrappers
#
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
