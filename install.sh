#!/usr/bin/env bash
# Sakura Term installer — macOS + Linux
#
#   ./install.sh                              everything: shell, theme, tools, remote
#   ./install.sh --modules theme,tools        pick modules (shell, theme, tools, remote)
#   ./install.sh --tmux-host me@server        enable `st` (tmux on that host via iTerm2)
#   ./install.sh --no-deps                    don't download anything (oh-my-zsh, fzf, ...)
#   ./install.sh --themes-only                only the iTerm2 profiles (macOS)
#
# Safe to run again: it only replaces its own files and its own block in ~/.zshrc.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
ITERM_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/sakura-term"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
BIN="$HOME/.local/bin"
export PATH="$BIN:$PATH"
BEGIN="# >>> sakura-term >>>"
END="# <<< sakura-term <<<"

MODULES="shell,theme,tools,remote"
TMUX_HOST=""
DEPS=1
THEMES_ONLY=0
ARGS=("$@")
while [[ $# -gt 0 ]]; do
  case "$1" in
    --modules)     MODULES="${2:?--modules needs a list, e.g. theme,tools}"; shift 2 ;;
    --tmux-host)   TMUX_HOST="${2:?--tmux-host needs a value, e.g. me@server}"; shift 2 ;;
    --no-deps)     DEPS=0; shift ;;
    --themes-only) THEMES_ONLY=1; shift ;;
    -h|--help)     sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done
has_mod() { [[ ",$MODULES," == *",$1,"* ]]; }
for m in ${MODULES//,/ }; do
  [[ $m =~ ^(shell|theme|tools|remote)$ ]] || { echo "unknown module: $m (use shell, theme, tools, remote)" >&2; exit 1; }
done

pink() { printf '\033[38;2;228;139;180m%s\033[0m\n' "$*"; }
ok()   { printf '\033[38;2;122;162;255m  ✓ %s\033[0m\n' "$*"; }
warn() { printf '\033[38;2;217;100;127m  ! %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
clone() {  # clone <url> <dir>  (shallow, skipped if present)
  if [[ -d "$2" ]]; then ok "$(basename "$2") (already there)"
  else git clone --depth 1 --quiet "$1" "$2" && ok "$(basename "$2")"; fi
}
as_root() { if [[ $EUID -eq 0 ]]; then "$@"; elif have sudo; then sudo "$@"; else return 1; fi; }

pink "✻ Sakura Term  ($OS · modules: $MODULES)"

# ─── 1. iTerm2 profiles (macOS) ──────────────────────────────────────────────
if [[ $OS == Darwin ]] && { has_mod theme || (( THEMES_ONLY )); }; then
  mkdir -p "$ITERM_DIR"
  cp "$REPO_DIR/iterm/sakura-term.json" "$ITERM_DIR/sakura-term.json"
  ok "iTerm2 profiles: Mist Sakura (light), Sakura Glass (dark)"
  [[ -d /Applications/iTerm.app ]] || warn "iTerm2 not found — get it at https://iterm2.com"
fi
if (( THEMES_ONLY )); then
  [[ $OS == Darwin ]] || warn "--themes-only installs iTerm2 profiles, which are macOS-only"
  exit 0
fi

# ─── 2. dependencies ─────────────────────────────────────────────────────────
P10K_LAYOUT=0
if (( DEPS )); then
  mkdir -p "$BIN"
  # zsh + git + curl
  missing=(); for c in zsh git curl; do have "$c" || missing+=("$c"); done
  if (( ${#missing[@]} )); then
    echo "  installing: ${missing[*]}"
    if   have apt-get; then as_root apt-get update -qq && as_root apt-get install -y -qq "${missing[@]}"
    elif have dnf;     then as_root dnf install -y -q "${missing[@]}"
    elif have yum;     then as_root yum install -y -q "${missing[@]}"
    elif have pacman;  then as_root pacman -S --noconfirm "${missing[@]}"
    elif have brew;    then brew install "${missing[@]}"
    fi || true
    for c in "${missing[@]}"; do have "$c" || { warn "$c is missing and could not be installed (no sudo?). Ask your admin or install it, then rerun."; exit 1; }; done
  fi

  if has_mod shell; then
    ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
    ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$ZSH_DIR/custom}"
    clone https://github.com/ohmyzsh/ohmyzsh.git                 "$ZSH_DIR"
    clone https://github.com/romkatv/powerlevel10k.git            "$ZSH_CUSTOM_DIR/themes/powerlevel10k"
    clone https://github.com/zsh-users/zsh-autosuggestions.git    "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
    clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"

    if ! have fzf && [[ ! -x "$HOME/.fzf/bin/fzf" ]]; then
      clone https://github.com/junegunn/fzf.git "$HOME/.fzf"
      "$HOME/.fzf/install" --bin >/dev/null 2>&1 && ok "fzf binary"
    else ok "fzf (already there)"; fi

    if have zoxide || [[ -x "$BIN/zoxide" ]]; then ok "zoxide (already there)"
    elif [[ $OS == Darwin ]] && have brew; then brew install -q zoxide && ok "zoxide"
    else curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \
           | sh -s -- --bin-dir "$BIN" >/dev/null 2>&1 && ok "zoxide" || warn "zoxide install failed (j won't be available)"
    fi

    # a prompt config, only if you don't have one yet
    if [[ ! -f "$HOME/.p10k.zsh" ]] && ! grep -qE 'p10k|p9k' "$ZSHRC" 2>/dev/null; then
      cp "$ZSH_CUSTOM_DIR/themes/powerlevel10k/config/p10k-rainbow.zsh" "$HOME/.p10k.zsh"
      P10K_LAYOUT=1
      ok "~/.p10k.zsh (powerlevel10k rainbow style + Sakura layout)"
    fi
  fi

  if has_mod remote && { ! have tssh || ! have trz; }; then
    case "$(uname -m)" in x86_64|amd64) arch=x86_64 ;; arm64|aarch64) arch=aarch64 ;; *) arch="" ;; esac
    os=$([[ $OS == Darwin ]] && echo macos || echo linux)
    fetch_release() {  # fetch_release <owner/repo> <asset-prefix>
      local tag ver tmp
      tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest")"; tag="${tag##*/}"; ver="${tag#v}"
      tmp="$(mktemp -d)"
      curl -fsSL "https://github.com/$1/releases/download/$tag/${2}_${ver}_${os}_${arch}.tar.gz" | tar -xz -C "$tmp" --strip-components=1
      find "$tmp" -maxdepth 1 -type f -perm -u+x -exec cp {} "$BIN/" \;
      rm -rf "$tmp"
    }
    if [[ -n $arch ]]; then
      have tssh || { fetch_release trzsz/trzsz-ssh tssh && ok "tssh → $BIN" || warn "tssh download failed"; }
      have trz  || { fetch_release trzsz/trzsz-go trzsz && ok "trz / tsz → $BIN" || warn "trzsz download failed"; }
    else warn "no trzsz build for $(uname -m); skipped"; fi
  fi
fi

# ─── 3. zsh files + config ───────────────────────────────────────────────────
mkdir -p "$CONF_DIR/modules"
cp "$REPO_DIR/zsh/sakura-term.zsh" "$CONF_DIR/"
cp "$REPO_DIR"/zsh/modules/*.zsh "$CONF_DIR/modules/"
if [[ $P10K_LAYOUT == 0 && -f "$CONF_DIR/config.zsh" ]] && grep -q 'SAKURA_P10K_LAYOUT=1' "$CONF_DIR/config.zsh"; then
  P10K_LAYOUT=1   # keep the layout we set up on an earlier run
fi
{
  echo "# written by install.sh — rerun it (or \`sakura update\`) instead of editing"
  echo "typeset -ga SAKURA_MODULES=(${MODULES//,/ })"
  echo "typeset -g  SAKURA_REPO=\"$REPO_DIR\""
  printf 'typeset -g  SAKURA_INSTALL_ARGS=%q\n' "${ARGS[*]-}"
  echo "typeset -g  SAKURA_P10K_LAYOUT=$P10K_LAYOUT"
  if [[ -n $TMUX_HOST ]]; then echo ": \${SAKURA_TMUX_HOST:=\"$TMUX_HOST\"}"; fi
} > "$CONF_DIR/config.zsh"
ok "zsh modules → ${CONF_DIR/#$HOME/~}"

# ─── 4. hook into ~/.zshrc ───────────────────────────────────────────────────
touch "$ZSHRC"
cp "$ZSHRC" "$ZSHRC.bak-sakura-term"
awk -v b="$BEGIN" -v e="$END" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$ZSHRC.bak-sakura-term" > "$ZSHRC"
conf_ref="${CONF_DIR/#$HOME/\$HOME}"
{
  echo "$BEGIN"
  echo "[[ -f \"$conf_ref/sakura-term.zsh\" ]] && source \"$conf_ref/sakura-term.zsh\""
  echo "$END"
} >> "$ZSHRC"
ok "~/.zshrc hooked (backup: .zshrc.bak-sakura-term)"

# ─── 5. hints ────────────────────────────────────────────────────────────────
if has_mod shell && [[ $OS == Darwin ]] && ! ls "$HOME/Library/Fonts" /Library/Fonts 2>/dev/null | grep -qi nerdfont; then
  warn "prompt icons need a Nerd Font:  brew install --cask font-jetbrains-mono-nerd-font"
fi
if [[ "$(basename "${SHELL:-}")" != zsh ]] && have zsh; then
  warn "your login shell is ${SHELL:-unknown}. Switch with:  chsh -s \"$(command -v zsh)\""
fi
echo
pink "Done. Open a new terminal (or run: exec zsh), then type  sakura  for the cheat sheet."
if [[ $OS == Darwin ]] && has_mod theme; then
  echo "  iTerm2 → Settings → Profiles → Mist Sakura → Other Actions… → Set as Default"
fi
