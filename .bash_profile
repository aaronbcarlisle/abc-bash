# .bash_profile
# bash login shells read this file instead of ~/.profile, so source both here:
# ~/.profile for the PATH and library settings, ~/.bashrc for everything else

if [ -f ~/.profile ]; then
    . ~/.profile
fi

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
