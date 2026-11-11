#!/usr/bin/env bash
# Sakura Term installer — iTerm2 profiles + zsh setup
#
#   ./install.sh                         install everything
#   ./install.sh --tmux-host me@server   also enable `st` (jump into tmux on that host)
#   ./install.sh --themes-only           only install the iTerm2 profiles
#
# Safe to run again: it replaces its own files and its own block in ~/.zshrc.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ITERM_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/sakura-term"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
BEGIN="# >>> sakura-term >>>"
END="# <<< sakura-term <<<"

TMUX_HOST=""
THEMES_ONLY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tmux-host)   TMUX_HOST="${2:?--tmux-host needs a value, e.g. me@server}"; shift 2 ;;
    --themes-only) THEMES_ONLY=1; shift ;;
    -h|--help)     sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

pink()  { printf '\033[38;2;228;139;180m%s\033[0m\n' "$*"; }
blue()  { printf '\033[38;2;122;162;255m%s\033[0m\n' "$*"; }
warn()  { printf '\033[38;2;217;100;127m! %s\033[0m\n' "$*"; }

pink "✻ Sakura Term"

[[ "$(uname -s)" == Darwin ]] || warn "iTerm2 profiles need macOS; skipping them."

# 1. iTerm2 dynamic profiles (picked up live, no restart needed)
if [[ "$(uname -s)" == Darwin ]]; then
  mkdir -p "$ITERM_DIR"
  cp "$REPO_DIR/iterm/sakura-term.json" "$ITERM_DIR/sakura-term.json"
  blue "  ✓ iTerm2 profiles: Sakura Glass (dark), Mist Sakura (light)"
  [[ -d /Applications/iTerm.app ]] || warn "iTerm2 not found in /Applications — install it from https://iterm2.com"
fi

# 2. zsh setup
if (( ! THEMES_ONLY )); then
  mkdir -p "$CONF_DIR"
  cp "$REPO_DIR/zsh/sakura-term.zsh" "$CONF_DIR/sakura-term.zsh"

  touch "$ZSHRC"
  cp "$ZSHRC" "$ZSHRC.bak-sakura-term"
  # drop an older sakura-term block, then append a fresh one at the end
  awk -v b="$BEGIN" -v e="$END" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$ZSHRC.bak-sakura-term" > "$ZSHRC"
  {
    echo "$BEGIN"
    [[ -n "$TMUX_HOST" ]] && echo "SAKURA_TMUX_HOST=\"$TMUX_HOST\""
    conf_ref="${CONF_DIR/#$HOME/\$HOME}"   # write $HOME/... so the block is portable
    echo "[[ -f \"$conf_ref/sakura-term.zsh\" ]] && source \"$conf_ref/sakura-term.zsh\""
    echo "$END"
  } >> "$ZSHRC"
  blue "  ✓ zsh: $CONF_DIR/sakura-term.zsh (sourced from $ZSHRC, backup at .zshrc.bak-sakura-term)"
  [[ -n "$TMUX_HOST" ]] && blue "  ✓ st → tmux on $TMUX_HOST"
fi

# 3. Nerd Font check (prompt icons need it)
if ! ls "$HOME/Library/Fonts" /Library/Fonts 2>/dev/null | grep -qi "JetBrainsMonoNerdFont"; then
  warn "JetBrainsMono Nerd Font not found. Icons need it:"
  echo "    brew install --cask font-jetbrains-mono-nerd-font"
fi

echo
pink "Next steps"
echo "  1. iTerm2 → Settings → Profiles → Mist Sakura → Other Actions… → Set as Default"
echo "  2. Open a new tab. ssh / tssh / mosh switch to Sakura Glass automatically."
