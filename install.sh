#!/usr/bin/env sh
# ============================================================================
# ABC Bash - installer for Linux, macOS, WSL and Git Bash on Windows
#
# Usage (from a clone):
#   git clone https://github.com/aaronbcarlisle/abc-bash.git ~/abc-bash
#   sh ~/abc-bash/install.sh [--force] [--wezterm]
#
# Copies the dotfiles from this checkout into $HOME:
#   .bashrc .bash_profile .profile, and inputrc as .inputrc
#   (.wezterm.lua too with --wezterm)
#
# Idempotent and safe to re-run. A file already identical to the repo copy is
# skipped. A file that differs is left alone unless you pass --force, which
# moves it to <file>.bak.<yyyyMMddHHmmss> before copying the repo version in.
# ============================================================================

set -eu

STAMP=$(date +%Y%m%d%H%M%S)
FORCE=0
WEZTERM=0
INSTALLED=0
SKIPPED=0
BACKUPS=""
NL='
'

# --- pretty logging ---------------------------------------------------------
info() { printf '\033[0;32m[abc-bash]\033[0m %s\n' "$1"; }
warn() { printf '\033[0;33m[abc-bash]\033[0m %s\n' "$1" >&2; }
err()  { printf '\033[0;31m[abc-bash]\033[0m %s\n' "$1" >&2; }
die()  { err "$1"; exit 1; }

# --- arguments --------------------------------------------------------------
usage() {
    printf 'Usage: sh install.sh [--force] [--wezterm]\n'
    printf '  --force    replace files that differ, backing each up to <file>.bak.<stamp> first\n'
    printf '  --wezterm  also install .wezterm.lua\n'
}
for arg in "$@"; do
    case "$arg" in
        --force|-f) FORCE=1 ;;
        --wezterm) WEZTERM=1 ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; die "Unknown option: $arg" ;;
    esac
done

# --- find the source --------------------------------------------------------
SRC=$(CDPATH='' cd -- "$(dirname -- "$0")" 2>/dev/null && pwd -P) || SRC=""
if [ -z "$SRC" ] || [ ! -f "$SRC/.bashrc" ] || [ ! -f "$SRC/inputrc" ]; then
    die "Run install.sh from an abc-bash checkout: git clone https://github.com/aaronbcarlisle/abc-bash.git ~/abc-bash && sh ~/abc-bash/install.sh"
fi
[ -n "${HOME:-}" ] && [ -d "$HOME" ] || die "\$HOME is not set to a directory."
info "Installing from $SRC into $HOME."

# install_file SRC_NAME DEST_NAME - copy $SRC/SRC_NAME to $HOME/DEST_NAME.
install_file() {
    from="$SRC/$1"
    to="$HOME/$2"
    if [ ! -e "$to" ] && [ ! -L "$to" ]; then
        cp "$from" "$to"
        info "Installed ~/$2"
        INSTALLED=$((INSTALLED + 1))
        return 0
    fi
    if [ -f "$to" ] && cmp -s "$from" "$to"; then
        info "~/$2 is up to date."
        return 0
    fi
    if [ "$FORCE" != 1 ]; then
        warn "~/$2 differs from the repo - leaving it alone (re-run with --force to back it up and replace it)."
        SKIPPED=$((SKIPPED + 1))
        return 0
    fi
    if [ -d "$to" ] && [ ! -L "$to" ]; then
        warn "~/$2 is a directory - leaving it alone even with --force."
        SKIPPED=$((SKIPPED + 1))
        return 0
    fi
    backup="$to.bak.$STAMP"
    mv "$to" "$backup"
    BACKUPS="$BACKUPS$backup$NL"
    cp "$from" "$to"
    info "Replaced ~/$2 (old copy at $backup)"
    INSTALLED=$((INSTALLED + 1))
}

install_file .bashrc .bashrc
install_file .bash_profile .bash_profile
install_file .profile .profile
install_file inputrc .inputrc
if [ "$WEZTERM" = 1 ]; then
    install_file .wezterm.lua .wezterm.lua
fi

# --- summary ----------------------------------------------------------------
if [ -n "$BACKUPS" ]; then
    info "Backed up the files that were replaced (compare them, then delete the backups):"
    printf '%s' "$BACKUPS" | sed 's/^/    /'
fi
if [ "$SKIPPED" -gt 0 ]; then
    warn "Skipped $SKIPPED file(s) that differ from the repo. Re-run with --force to replace them."
fi
if [ "$INSTALLED" -gt 0 ]; then
    info "Done. Open a new terminal (or run: source ~/.bashrc) to pick up the changes."
elif [ "$SKIPPED" -eq 0 ]; then
    info "Done. Everything was already up to date."
fi
