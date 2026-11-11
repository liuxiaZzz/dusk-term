#!/usr/bin/env bash
# Sakura Term installer — macOS + Linux
#
#   ./install.sh                              everything; role is detected automatically:
#                                               macOS → local (iTerm2 themes, tssh client)
#                                               Linux → server (trz/tsz for file transfer)
#   ./install.sh --role local|server          override the detected role
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
ROLE=""
TMUX_HOST=""
DEPS=1
THEMES_ONLY=0
ARGS=("$@")
while [[ $# -gt 0 ]]; do
  case "$1" in
    --modules)     MODULES="${2:?--modules needs a list, e.g. theme,tools}"; shift 2 ;;
    --role)        ROLE="${2:?--role needs local or server}"; shift 2 ;;
    --tmux-host)   TMUX_HOST="${2:?--tmux-host needs a value, e.g. me@server}"; shift 2 ;;
    --no-deps)     DEPS=0; shift ;;
    --themes-only) THEMES_ONLY=1; shift ;;
    -h|--help)     sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done
has_mod() { [[ ",$MODULES," == *",$1,"* ]]; }
[[ -n $ROLE ]] || ROLE=$([[ $OS == Darwin ]] && echo local || echo server)
[[ $ROLE == local || $ROLE == server ]] || { echo "--role must be local or server" >&2; exit 1; }
for m in ${MODULES//,/ }; do
  [[ $m =~ ^(shell|theme|tools|remote)$ ]] || { echo "unknown module: $m (use shell, theme, tools, remote)" >&2; exit 1; }
done

# ─── look & feel: the same blue/pink as the themes ──────────────────────────
ZH=0; [[ "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" == zh* ]] && ZH=1   # before any locale change
t() { if (( ZH )); then printf '%s' "$1"; else printf '%s' "$2"; fi; }   # t "中文" "English"

# character counts need a UTF-8 locale; ASCII ranges need C collation
if [[ "$(locale charmap 2>/dev/null)" != UTF-8 ]]; then
  u="$(locale -a 2>/dev/null | grep -iE '^(c|en_us)\.utf-?8$' | head -1 || true)"
  [[ -n $u ]] && export LC_ALL=$u
fi
export LC_COLLATE=C

TTY=0; [[ -t 1 ]] && TTY=1
if (( TTY )) && [[ -z ${NO_COLOR:-} ]]; then
  rgb()  { printf '\033[38;2;%sm' "$1"; }
  bg()   { printf '\033[48;2;%sm' "$1"; }
  PINK=$(rgb '228;139;180')  BLUE=$(rgb '122;162;255')  SKY=$(rgb '163;203;230')
  MUTE=$(rgb '127;132;163')  ROSE=$(rgb '217;100;127')  WHITE=$(rgb '246;247;252')
  INK=$(rgb '24;33;63')      BLUSH=$(rgb '239;198;219')
  BG_PINK=$(bg '228;139;180') BG_SAPPHIRE=$(bg '74;98;173') BG_NAVY=$(bg '29;42;76')
  BOLD=$'\033[1m' N=$'\033[0m'
else
  PINK="" BLUE="" SKY="" MUTE="" ROSE="" WHITE="" INK="" BLUSH=""
  BG_PINK="" BG_SAPPHIRE="" BG_NAVY="" BOLD="" N=""
fi

# display width: ASCII and a few symbols = 1, CJK = 2
dw() {
  local s=$1 n a
  n="${s//[·→…✓✻─⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏]/}"
  a="${n//[^ -~]/}"
  echo $(( ${#a} + 2 * (${#n} - ${#a}) + (${#s} - ${#n}) ))
}
pad()  { local w; w=$(dw "$1"); printf '%s%*s' "$1" $(( $2 > w ? $2 - w : 0 )) ''; }
rule() { local n=$1 c=${2:-─} out=""; while (( n-- > 0 )); do out+=$c; done; printf '%s' "$out"; }

WIDTH=58
# a pink-framed card; lines are given as "plain text" + "colored text" so widths stay right
card_top()    { local tl=" $1 " w; w=$(dw "$tl"); printf '  %s╭─%s%s%s%s%s%s╮%s\n' "$PINK" "$N" "$BG_PINK$WHITE$BOLD" "$tl" "$N" "$PINK" "$(rule $(( WIDTH - 4 - w )))" "$N"; }
card_line()   { local plain=$1 colored=${2:-$1} w; w=$(dw "$plain"); printf '  %s│%s  %s%*s%s│%s\n' "$PINK" "$N" "$colored" $(( WIDTH - 4 - w )) '' "$PINK" "$N"; }
card_bottom() { printf '  %s╰%s╯%s\n' "$PINK" "$(rule $(( WIDTH - 2 )))" "$N"; }

STEP=0
step() {
  STEP=$((STEP + 1))
  local title=$1 w; w=$(dw "$title")
  printf '\n  %s %s %s %s%s%s %s%s%s\n' "$BG_PINK$WHITE$BOLD" "$STEP" "$N" "$BLUE$BOLD" "$title" "$N" "$MUTE" "$(rule $(( WIDTH - 6 - w )))" "$N"
}
ok()   { printf '     %s✓%s %s %s%s%s\n' "$BLUE" "$N" "$(pad "$1" 24)" "$MUTE" "${2:-}" "$N"; }
skip() { printf '     %s· %s %s%s\n' "$MUTE" "$(pad "$1" 24)" "${2:-$(t 已存在 'already there')}" "$N"; }
warn() { printf '     %s!%s %s\n' "$ROSE" "$N" "$1"; }
NOTES=()   # "text|command" pairs for the finish card

LOG="$(mktemp -t sakura-term.XXXXXX)"
trap 'rm -f "$LOG"' EXIT
# run <label> <detail-on-success> <cmd...>: pink spinner while it runs, ✓ or ! when done
run() {
  local label=$1 detail=$2; shift 2
  local start=$SECONDS frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0 rc=0
  if (( TTY )); then
    ( "$@" ) >"$LOG" 2>&1 &
    local pid=$!
    while kill -0 $pid 2>/dev/null; do
      printf '\r     %s%s%s %s%s%s' "$PINK" "${frames:i++%10:1}" "$N" "$BLUSH" "$(pad "$label" 24)" "$N"
      sleep 0.08
    done
    wait $pid || rc=$?
    printf '\r\033[K'
  else
    ( "$@" ) >"$LOG" 2>&1 || rc=$?
  fi
  local secs=$(( SECONDS - start ))
  (( secs >= 1 )) && detail="${detail:+$detail  }${secs}s"
  if (( rc == 0 )); then ok "$label" "$detail"
  else warn "$label $(t 失败 failed)"; tail -n 5 "$LOG" | sed "s/^/       $MUTE/;s/\$/$N/"; fi
  return $rc
}
have() { command -v "$1" >/dev/null 2>&1; }
as_root() { if [[ $EUID -eq 0 ]]; then "$@"; elif have sudo; then sudo "$@"; else return 1; fi; }
clone() {  # clone <label> <url> <dir>
  if [[ -d "$3" ]]; then skip "$1"
  else run "$1" "" git clone --depth 1 --quiet "$2" "$3" || true; fi
}
short() { printf '%s' "${1/#$HOME/~}"; }

# ─── header ──────────────────────────────────────────────────────────────────
os_name=$([[ $OS == Darwin ]] && echo macOS || echo Linux)
role_name=$([[ $ROLE == local ]] && t 本机 local || t 服务器 server)
echo
printf '  %s ✻ Sakura Term %s %s · %s %s %s %s\n' \
  "$BG_PINK$WHITE$BOLD" "$N$BG_SAPPHIRE$WHITE" "$role_name" "$os_name" "$N$BG_NAVY$BLUSH" "${MODULES//,/ · }" "$N"
printf '  %s%s%s\n' "$MUTE" "$(t '蓝粉终端套件 · 主题、shell 环境与快捷命令' 'blue & pink terminal kit · themes, shell and shortcuts')" "$N"

# ─── 1. iTerm2 profiles (macOS) ──────────────────────────────────────────────
if [[ $OS == Darwin && $ROLE == local ]] && { has_mod theme || (( THEMES_ONLY )); }; then
  step "$(t 主题 Themes)"
  mkdir -p "$ITERM_DIR"
  cp "$REPO_DIR/iterm/sakura-term.json" "$ITERM_DIR/sakura-term.json"
  ok "$(t 'iTerm2 配置文件' 'iTerm2 profiles')" "Mist Sakura · Sakura Glass"
  [[ -d /Applications/iTerm.app ]] || warn "$(t '没找到 iTerm2，可在 https://iterm2.com 下载' 'iTerm2 not found — get it at https://iterm2.com')"
  NOTES+=("$(t '把 Mist Sakura 设为默认：' 'Make Mist Sakura the default:')|iTerm2 → Settings → Profiles → Other Actions…")
fi
if (( THEMES_ONLY )); then
  [[ $OS == Darwin ]] || warn "$(t '--themes-only 只装 iTerm2 主题，仅限 macOS' '--themes-only installs iTerm2 profiles, which are macOS-only')"
  echo; exit 0
fi

# ─── 2. dependencies ─────────────────────────────────────────────────────────
P10K_LAYOUT=0
if (( DEPS )); then
  mkdir -p "$BIN"
  missing=(); for c in zsh git curl; do have "$c" || missing+=("$c"); done
  if (( ${#missing[@]} )); then
    step "$(t 基础工具 'Base tools')"
    pm_install() {
      if   have apt-get; then as_root apt-get update -qq && DEBIAN_FRONTEND=noninteractive as_root apt-get install -y -qq "$@"
      elif have dnf;     then as_root dnf install -y -q "$@"
      elif have yum;     then as_root yum install -y -q "$@"
      elif have pacman;  then as_root pacman -S --noconfirm "$@"
      elif have brew;    then brew install "$@"
      else return 1; fi
    }
    run "${missing[*]}" "$(t 已安装 installed)" pm_install "${missing[@]}" || true
    for c in "${missing[@]}"; do
      have "$c" || { warn "$(t "缺少 $c，且无法自动安装（没有 sudo？）。请先装好它再重新运行。" "$c is missing and could not be installed (no sudo?). Install it, then rerun.")"; echo; exit 1; }
    done
  fi

  if has_mod shell; then
    step "$(t 'Shell 环境' 'Shell')"
    ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
    ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$ZSH_DIR/custom}"
    clone oh-my-zsh               https://github.com/ohmyzsh/ohmyzsh.git                  "$ZSH_DIR"
    clone powerlevel10k           https://github.com/romkatv/powerlevel10k.git             "$ZSH_CUSTOM_DIR/themes/powerlevel10k"
    clone zsh-autosuggestions     https://github.com/zsh-users/zsh-autosuggestions.git     "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
    clone zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"

    if have fzf || [[ -x "$HOME/.fzf/bin/fzf" ]]; then skip fzf
    else
      fzf_install() { [[ -d "$HOME/.fzf" ]] || git clone --depth 1 --quiet https://github.com/junegunn/fzf.git "$HOME/.fzf"; "$HOME/.fzf/install" --bin; }
      run fzf "$(t 'Ctrl-R 搜历史' 'Ctrl-R history search')" fzf_install || true
    fi

    if have zoxide || [[ -x "$BIN/zoxide" ]]; then skip zoxide
    elif [[ $OS == Darwin ]] && have brew; then run zoxide "$(t 'j 跳目录' 'j to jump')" brew install -q zoxide || true
    else
      zoxide_install() { curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh -s -- --bin-dir "$BIN"; }
      run zoxide "$(t 'j 跳目录' 'j to jump')" zoxide_install || true
    fi

    if [[ ! -f "$HOME/.p10k.zsh" ]] && ! grep -qE 'p10k|p9k' "$ZSHRC" 2>/dev/null; then
      cp "$ZSH_CUSTOM_DIR/themes/powerlevel10k/config/p10k-rainbow.zsh" "$HOME/.p10k.zsh"
      P10K_LAYOUT=1
      ok "~/.p10k.zsh" "$(t '提示栏布局' 'prompt layout')"
    else
      skip "$(t '提示栏配置' 'prompt config')" "$(t '保留你自己的' 'keeping yours')"
    fi
  fi

  # local machine needs the tssh client (drag & drop); servers need trz/tsz
  if has_mod remote; then
    step "$(t 远程工具 Remote)"
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
    if [[ $ROLE == local ]]; then
      if have tssh; then skip tssh
      elif [[ -n $arch ]]; then run tssh "$(t '拖拽上传' 'drag & drop upload')" fetch_release trzsz/trzsz-ssh tssh || true
      else warn "$(t "没有适用于 $(uname -m) 的 tssh，已跳过" "no tssh build for $(uname -m); skipped")"; fi
    else
      if have trz; then skip "trz / tsz"
      elif [[ -n $arch ]]; then run "trz / tsz" "$(t 'upload / download' 'upload / download')" fetch_release trzsz/trzsz-go trzsz || true
      else warn "$(t "没有适用于 $(uname -m) 的 trzsz，已跳过" "no trzsz build for $(uname -m); skipped")"; fi
    fi
  fi
fi

# ─── 3. zsh files + config ───────────────────────────────────────────────────
step "$(t 写入配置 Configure)"
mkdir -p "$CONF_DIR/modules"
cp "$REPO_DIR/zsh/sakura-term.zsh" "$CONF_DIR/"
cp "$REPO_DIR"/zsh/modules/*.zsh "$CONF_DIR/modules/"
if [[ $P10K_LAYOUT == 0 && -f "$CONF_DIR/config.zsh" ]] && grep -q 'SAKURA_P10K_LAYOUT=1' "$CONF_DIR/config.zsh"; then
  P10K_LAYOUT=1   # keep the layout we set up on an earlier run
fi
{
  echo "# written by install.sh — rerun it (or \`sakura update\`) instead of editing"
  echo "typeset -ga SAKURA_MODULES=(${MODULES//,/ })"
  echo "typeset -g  SAKURA_ROLE=$ROLE"
  echo "typeset -g  SAKURA_REPO=\"$REPO_DIR\""
  printf 'typeset -g  SAKURA_INSTALL_ARGS=%q\n' "${ARGS[*]-}"
  echo "typeset -g  SAKURA_P10K_LAYOUT=$P10K_LAYOUT"
  if [[ -n $TMUX_HOST ]]; then echo ": \${SAKURA_TMUX_HOST:=\"$TMUX_HOST\"}"; fi
} > "$CONF_DIR/config.zsh"
ok "$(t 'zsh 模块' 'zsh modules')" "$(short "$CONF_DIR")"

touch "$ZSHRC"
cp "$ZSHRC" "$ZSHRC.bak-sakura-term"
awk -v b="$BEGIN" -v e="$END" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$ZSHRC.bak-sakura-term" > "$ZSHRC"
conf_ref="${CONF_DIR/#$HOME/\$HOME}"
{
  echo "$BEGIN"
  echo "[[ -f \"$conf_ref/sakura-term.zsh\" ]] && source \"$conf_ref/sakura-term.zsh\""
  echo "$END"
} >> "$ZSHRC"
ok "$(short "$ZSHRC")" "$(t '已接入，备份为 .zshrc.bak-sakura-term' 'hooked, backup at .zshrc.bak-sakura-term')"
[[ -n $TMUX_HOST ]] && ok "st" "$(t "tmux → $TMUX_HOST" "tmux → $TMUX_HOST")"

# ─── 4. done ─────────────────────────────────────────────────────────────────
if has_mod shell && [[ $OS == Darwin ]] && ! ls "$HOME/Library/Fonts" /Library/Fonts 2>/dev/null | grep -qi nerdfont; then
  NOTES+=("$(t '图标需要 Nerd Font：' 'Icons need a Nerd Font:')|brew install --cask font-jetbrains-mono-nerd-font")
fi
if [[ "$(basename "${SHELL:-}")" != zsh ]] && have zsh; then
  NOTES+=("$(t '默认 shell 还不是 zsh，切换：' 'Your login shell is not zsh yet:')|chsh -s $(command -v zsh)")
fi

echo
card_top "$(t '✓ 完成' '✓ Done')"
card_line ""
cmdline() {  # cmdline <before> <command> <after>: command in pink
  card_line "$1$2$3" "$1$PINK$BOLD$2$N$3"
}
cmdline "$(t '新开一个终端，或运行 ' 'Open a new terminal, or run ')" "exec zsh" ""
cmdline "$(t '输入 ' 'Type ')" "hud" "$(t '          打开控制中心' '          for the Control Center')"
cmdline "$(t '输入 ' 'Type ')" "sakura help" "$(t '  查看全部快捷命令' '  for every shortcut')"
if (( ${#NOTES[@]} )); then
  card_line ""
  card_line "$(t '还差一步' 'One more thing')" "$SKY$BOLD$(t '还差一步' 'One more thing')$N"
  for n in "${NOTES[@]}"; do
    card_line "${n%%|*}"
    card_line "  ${n#*|}" "  $PINK${n#*|}$N"
  done
fi
card_line ""
card_bottom
echo
