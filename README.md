ABC Bash
================================

My personal bash/tmux setup for Linux.

---

# Install

```bash
cd ~ && git clone https://github.com/aaronbcarlisle/abc-bash.git && { mv -n ~/abc-bash/.tmux.conf ~/abc-bash/.bash* ~/abc-bash/.profile ~; mv -n ~/abc-bash/inputrc ~/.inputrc; rm -rf ~/abc-bash; }
```

WezTerm config install (optional, works on Windows and Linux):

```bash
cd ~ && git clone https://github.com/aaronbcarlisle/abc-bash.git && { mv ~/abc-bash/.wezterm.lua ~; rm -rf ~/abc-bash; }
```

---

# Contributions
- [Bash Profile dot Files from Stefaan Lippens](https://www.stefaanlippens.net/my_bashrc_aliases_profile_and_other_stuff/)

---

# License

MIT, see [LICENSE](LICENSE), except for `.profile`. `.profile` is adapted from Stefaan Lippens' post credited above, which is © Stefaan Lippens, all rights reserved, so the MIT license doesn't cover it.
