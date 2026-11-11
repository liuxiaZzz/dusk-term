#!/usr/bin/env bash
# Remove Sakura Term: iTerm2 profiles, zsh modules, and its block in ~/.zshrc.
# Tools it may have installed (oh-my-zsh, powerlevel10k, fzf, zoxide, trzsz) are left in place.
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
echo "Sakura Term removed."
echo "Left in place: ~/.oh-my-zsh, ~/.p10k.zsh, ~/.fzf, ~/.local/bin/{zoxide,tssh,trz,tsz}. Delete them by hand if you like."
echo "If a Sakura profile was your iTerm2 default, pick another one in Settings → Profiles."
