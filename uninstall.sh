#!/usr/bin/env bash
# Remove Sakura Term: iTerm2 profiles, zsh file, and its block in ~/.zshrc.
set -euo pipefail

ITERM_FILE="$HOME/Library/Application Support/iTerm2/DynamicProfiles/sakura-term.json"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/sakura-term"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

rm -f "$ITERM_FILE"
rm -rf "$CONF_DIR"
if [[ -f "$ZSHRC" ]]; then
  cp "$ZSHRC" "$ZSHRC.bak-sakura-term-uninstall"
  awk '$0=="# >>> sakura-term >>>"{skip=1} !skip{print} $0=="# <<< sakura-term <<<"{skip=0}' \
    "$ZSHRC.bak-sakura-term-uninstall" > "$ZSHRC"
fi
echo "Sakura Term removed. If a Sakura profile was your iTerm2 default, pick another default in Settings → Profiles."
