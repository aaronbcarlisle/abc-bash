ABC Bash
================================

My personal bash and readline setup for Linux, WSL and Git Bash on
Windows, plus an optional WezTerm config.

---

# What's included

| Repo file      | Installed as     | What it does                                                                 |
| -------------- | ---------------- | ---------------------------------------------------------------------------- |
| `.bashrc`      | `~/.bashrc`      | History, a git-aware prompt, aliases and small `cd` helpers                  |
| `.bash_profile`| `~/.bash_profile`| Login shells: sources `~/.profile`, then `~/.bashrc`                         |
| `.profile`     | `~/.profile`     | Adds `~/usr/bin` and `~/usr/lib` to `PATH` and the library search paths      |
| `inputrc`      | `~/.inputrc`     | Readline: no bell, case-insensitive completion, arrow-key history search     |
| `.wezterm.lua` | `~/.wezterm.lua` | Optional WezTerm config (Windows and Linux); opens Git Bash on Windows       |

---

# Install

```bash
git clone https://github.com/aaronbcarlisle/abc-bash.git ~/abc-bash
sh ~/abc-bash/install.sh
```

The installer copies the files above into your home directory. It's safe to
re-run:

- A file that doesn't exist yet is installed.
- A file that already matches the repo is skipped.
- A file that differs from the repo is **left alone**, and the installer tells
  you which ones it skipped.

Open a new terminal (or `source ~/.bashrc`) afterwards.

## Options

| Option      | Effect                                                                                                     |
| ----------- | ---------------------------------------------------------------------------------------------------------- |
| `--force`   | Replace files that differ from the repo. Each one is first moved to `<file>.bak.<yyyyMMddHHmmss>`, so nothing is lost. |
| `--wezterm` | Also install `.wezterm.lua`.                                                                               |
| `--help`    | Show usage.                                                                                                |

For example, to take over an existing setup and keep backups of the old files:

```bash
sh ~/abc-bash/install.sh --force
```

The installer lists every backup it made. Compare them with the new files
(`diff ~/.bashrc.bak.<stamp> ~/.bashrc`) and delete them when you're done.

## Updating

```bash
git -C ~/abc-bash pull --ff-only
sh ~/abc-bash/install.sh --force
```

`--force` is needed here because the installed files are copies: once the repo
changes, they differ from it. Without it, the installer only reports which files
are out of date.

## Notes

- **Windows:** run the installer from Git Bash. The WezTerm config starts Git
  Bash as a login shell, so `~/.bash_profile` and `~/.bashrc` both load.
- **Machine-specific changes:** put them in `~/.bashrc.local`, which `.bashrc`
  sources last and the installer never touches. The installer also won't
  overwrite a file that differs unless you pass `--force`.

---

# Contributions
- [Bash Profile dot Files from Stefaan Lippens](https://www.stefaanlippens.net/my_bashrc_aliases_profile_and_other_stuff/)

---

# License

MIT, see [LICENSE](LICENSE), except for `.profile`. `.profile` is adapted from Stefaan Lippens' post credited above, which is © Stefaan Lippens, all rights reserved, so the MIT license doesn't cover it.
