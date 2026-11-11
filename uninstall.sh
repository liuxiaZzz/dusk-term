#!/usr/bin/env bash
# Remove Dusk: iTerm2 profiles, zsh modules, and its block in ~/.zshrc.
# Tools it may have installed (oh-my-zsh, powerlevel10k, fzf, zoxide, trzsz) are left in place.
set -euo pipefail

ITERM_FILE="$HOME/Library/Application Support/iTerm2/DynamicProfiles/dusk.json"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dusk"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

rm -f "$ITERM_FILE"
# profiles the installer moved aside because they clashed with Dusk's: put them back
if [[ -d "$CONF_DIR/backup" ]]; then
  for f in "$CONF_DIR"/backup/*.json; do
    [[ -f $f ]] && mv "$f" "$(dirname "$ITERM_FILE")/" && echo "Restored iTerm2 profile: $(basename "$f")"
  done
fi
rm -rf "$CONF_DIR"
if [[ -f "$ZSHRC" ]]; then
  cp "$ZSHRC" "$ZSHRC.bak-dusk-uninstall"
  awk '$0=="# >>> dusk >>>"{skip=1} !skip{print} $0=="# <<< dusk <<<"{skip=0}' \
    "$ZSHRC.bak-dusk-uninstall" > "$ZSHRC"
fi
echo "Dusk removed."
echo "Left in place: ~/.oh-my-zsh, ~/.p10k.zsh, ~/.fzf, ~/.local/bin/{zoxide,tssh,trz,tsz}. Delete them by hand if you like."
echo "If a Dusk profile was your iTerm2 default, pick another one in Settings → Profiles."
