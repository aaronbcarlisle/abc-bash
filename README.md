ABC Bash
================================

My personal bash/tmux setup for Linux.

---

# Install

tmux installation for git-bash (requires [msys64](https://www.msys2.org/) running as **admin**:

    pacman -S tmux && cd "C:\msys64\usr\bin" && cp -t "C:\Program Files\Git\usr\bin" tmux.exe msys-event*.exe
    
bashrc and tmux config install:

    cd ~ && git clone https://github.com/abcarlisle/abc-bash.git && mv -n ~/abc-bash/.tmux.conf ~/abc-bash/.bash* ~/abc-bash/.profile ~; rm -rf ~/abc-bash

---

# Contributions
- [Bash Profile dot Files from Stefaan Lippens](https://www.stefaanlippens.net/my_bashrc_aliases_profile_and_other_stuff/)
