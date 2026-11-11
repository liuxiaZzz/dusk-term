#!/usr/bin/env bash
# Dusk installer — macOS + Linux
#
#   ./install.sh                              everything; role is detected automatically:
#                                               macOS → local (iTerm2 themes, tssh client)
#                                               Linux → server (trz/tsz for file transfer)
#   ./install.sh --role local|server          override the detected role
#   ./install.sh --modules theme,tools        pick modules (shell, theme, tools, remote)
#   ./install.sh --style classic|glass        classic: Dusk Light + Dusk Dark (5% see-through)
#                                             glass:   Dusk Glass Light + Dusk Glass Dark (frosted glass)
#   ./install.sh --mode split|dark|light      split: light locally, dark on remote hosts (auto switch)
#                                             dark / light: one look everywhere
#   ./install.sh -y                           no questions, use defaults (classic, split)
#   ./install.sh --tmux-host me@server        one command to open tmux on that host (see `dusk tmux`)
#
# Running it again keeps your earlier answers unless you pass a new value.
#   ./install.sh --no-deps                    don't download anything (oh-my-zsh, fzf, ...)
#   ./install.sh --themes-only                only the iTerm2 profiles (macOS)
#
# Safe to run again: it only replaces its own files and its own block in ~/.zshrc.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
ITERM_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dusk"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
BIN="$HOME/.local/bin"
export PATH="$BIN:$PATH"
BEGIN="# >>> dusk >>>"
END="# <<< dusk <<<"

ORIG_ARGS=("$@")
MODULES=""
ROLE=""
TMUX_HOST=""
DEPS=1
THEMES_ONLY=0
STYLE=""
MODE=""
ASK=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --modules)     MODULES="${2:?--modules needs a list, e.g. theme,tools}"; shift 2 ;;
    --role)        ROLE="${2:?--role needs local or server}"; shift 2 ;;
    --tmux-host)   TMUX_HOST="${2:?--tmux-host needs a value, e.g. me@server}"; shift 2 ;;
    --no-deps)     DEPS=0; shift ;;
    --themes-only) THEMES_ONLY=1; shift ;;
    --style)       STYLE="${2:?--style needs classic or glass}"; shift 2 ;;
    --mode)        MODE="${2:?--mode needs split, dark or light}"; shift 2 ;;
    -y|--yes)      ASK=0; shift ;;
    -h|--help)     sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done
# earlier answers (config.zsh from a previous run) are the defaults this time
cfg_get() { [[ -f "$CONF_DIR/config.zsh" ]] && sed -nE "s/^: \\\$\{$1:='(.*)'\}$/\1/p" "$CONF_DIR/config.zsh" | tail -1 || true; }
PREV_MODULES="$( [[ -f "$CONF_DIR/config.zsh" ]] && sed -nE 's/^typeset -ga DUSK_MODULES=\((.*)\)$/\1/p' "$CONF_DIR/config.zsh" | tr ' ' ',' || true)"
MODULES=${MODULES:-${PREV_MODULES:-shell,theme,tools,remote}}
ROLE=${ROLE:-$(cfg_get DUSK_ROLE)}
PREV_STYLE=$(cfg_get DUSK_STYLE); PREV_MODE=$(cfg_get DUSK_MODE)
TMUX_SESSION=$(cfg_get DUSK_TMUX_SESSION); TMUX_CMD=$(cfg_get DUSK_TMUX_CMD); TMUX_PROFILE=$(cfg_get DUSK_TMUX_PROFILE)
PREV_TMUX_HOST=$(cfg_get DUSK_TMUX_HOSTS); PREV_TMUX_HOST=${PREV_TMUX_HOST:-$(cfg_get DUSK_TMUX_HOST)}
has_mod() { [[ ",$MODULES," == *",$1,"* ]]; }
[[ -n $ROLE ]] || ROLE=$([[ $OS == Darwin ]] && echo local || echo server)
[[ $ROLE == local || $ROLE == server ]] || { echo "--role must be local or server" >&2; exit 1; }
[[ -z $STYLE || $STYLE == classic || $STYLE == glass ]] || { echo "--style must be classic or glass" >&2; exit 1; }
[[ -z $MODE || $MODE == split || $MODE == dark || $MODE == light ]] || { echo "--mode must be split, dark or light" >&2; exit 1; }
for m in ${MODULES//,/ }; do
  [[ $m =~ ^(shell|theme|tools|remote)$ ]] || { echo "unknown module: $m (use shell, theme, tools, remote)" >&2; exit 1; }
done

# ─── look & feel: the same blue/pink as the themes ──────────────────────────
ZH=0; [[ "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" == zh* ]] && ZH=1   # before any locale change
t() { if (( ZH )); then printf '%s' "$1"; else printf '%s' "$2"; fi; }   # t "中文" "English"

# character counts need a UTF-8 locale (bash only picks it up at start, so restart once
# under one); ASCII ranges need C collation
if [[ "$(locale charmap 2>/dev/null)" != UTF-8 && -z ${DUSK_REEXEC:-} ]]; then
  u="$(locale -a 2>/dev/null | grep -iE '^(c|en_us)\.utf-?8$' | head -1 || true)"
  [[ -n $u ]] && DUSK_REEXEC=1 LC_CTYPE=$u exec env -u LC_ALL bash "$0" "${ORIG_ARGS[@]+"${ORIG_ARGS[@]}"}"
fi
# LC_ALL would override LC_COLLATE: move it to LC_CTYPE (character set) instead
if [[ -n ${LC_ALL:-} ]]; then export LC_CTYPE=$LC_ALL; unset LC_ALL; fi
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
card_top()    { local tl=" $1 " w; w=$(dw "$tl"); printf '  %s╭─%s%s%s%s%s%s╮%s\n' "$PINK" "$N" "$BG_PINK$WHITE$BOLD" "$tl" "$N" "$PINK" "$(rule $(( WIDTH - 3 - w )))" "$N"; }
card_line()   { local plain=$1 colored=${2:-$1} w; w=$(dw "$plain"); printf '  %s│%s  %s%*s%s│%s\n' "$PINK" "$N" "$colored" $(( WIDTH - 4 - w )) '' "$PINK" "$N"; }
# wrap <width> <text>: print the text in lines of at most <width> display columns
wrap() {
  local width=$1 line="" w
  for w in $2; do
    if [[ -z $line ]]; then line=$w
    elif (( $(dw "$line $w") <= width )); then line="$line $w"
    else printf '%s\n' "$line"; line=$w; fi
  done
  [[ -n $line ]] && printf '%s\n' "$line"
  return 0
}
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

LOG="$(mktemp -t dusk.XXXXXX)"
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
# never prompt for a password: on shared servers we only use sudo if it works without one
as_root() { if [[ $EUID -eq 0 ]]; then "$@"; elif have sudo && sudo -n true 2>/dev/null; then sudo -n "$@"; else return 1; fi; }
# zsh built into your home folder (GCR and similar no-sudo setups) counts as installed
for z in "$HOME/zsh/bin" "$HOME/.local/bin" "$HOME/opt/zsh/bin"; do
  [[ -x "$z/zsh" ]] && case ":$PATH:" in *":$z:"*) ;; *) export PATH="$z:$PATH" ;; esac
done
clone() {  # clone <label> <url> <dir>
  if [[ -d "$3" ]]; then skip "$1"
  else run "$1" "" git clone --depth 1 --quiet "$2" "$3" || true; fi
}
short() { printf '%s' "${1/#$HOME/~}"; }

# ─── header ──────────────────────────────────────────────────────────────────
os_name=$([[ $OS == Darwin ]] && echo macOS || echo Linux)
role_name=$([[ $ROLE == local ]] && t 本机 local || t 服务器 server)
echo
printf '  %s ✻ Dusk %s %s · %s %s %s %s\n' \
  "$BG_PINK$WHITE$BOLD" "$N$BG_SAPPHIRE$WHITE" "$role_name" "$os_name" "$N$BG_NAVY$BLUSH" "${MODULES//,/ · }" "$N"
printf '  %s%s%s\n' "$MUTE" "$(t '蓝粉终端套件 · 主题、shell 环境与快捷命令' 'blue & pink terminal kit · themes, shell and shortcuts')" "$N"

# ─── choices: style and local/remote look (local machine with themes only) ──
# choose <title> <default> "label|description" ...   → REPLY = 1-based choice
choose() {
  local title=$1 def=$2; shift 2
  local i=1 o lab
  printf '\n  %s ? %s %s%s%s\n' "$BG_SAPPHIRE$WHITE$BOLD" "$N" "$BLUE$BOLD" "$title" "$N"
  for o in "$@"; do
    lab=${o%%|*}
    if (( i == def )); then printf '     %s%s%s  %s%s%s  %s%s%s\n' "$PINK$BOLD" "$i" "$N" "$BOLD" "$(pad "$lab" 6)" "$N" "$MUTE" "${o#*|}" "$N"
    else                   printf '     %s%s%s  %s  %s%s%s\n' "$BLUE" "$i" "$N" "$(pad "$lab" 6)" "$MUTE" "${o#*|}" "$N"; fi
    i=$((i + 1))
  done
  local ans
  while :; do
    printf '     %s❯%s %s' "$PINK" "$N" "$(t "输入 1-${#}，回车选 ${def}：" "Pick 1-${#} (Enter = ${def}): ")"
    IFS= read -r ans </dev/tty || ans=""
    [[ -z $ans ]] && ans=$def
    [[ $ans =~ ^[0-9]+$ ]] && (( ans >= 1 && ans <= $# )) && break
  done
  REPLY=$ans
}
WANT_THEME=0; [[ $OS == Darwin && $ROLE == local ]] && { has_mod theme || (( THEMES_ONLY )); } && WANT_THEME=1
CAN_ASK=0; (( ASK && TTY )) && [[ -r /dev/tty ]] && CAN_ASK=1
if (( WANT_THEME )); then
  if [[ -z $STYLE ]]; then
    STYLE=${PREV_STYLE:-classic}
    if (( CAN_ASK )); then
      choose "$(t 选择风格 'Pick a style')" $([[ $STYLE == glass ]] && echo 2 || echo 1) \
        "$(t 经典 Classic)|$(t 'Dusk Light + Dusk Dark，5% 透明' 'Dusk Light + Dusk Dark, 5% see-through')" \
        "$(t 玻璃 Glass)|$(t 'Dusk Glass Light + Glass Dark，毛玻璃' 'Dusk Glass Light + Glass Dark, frosted glass')"
      STYLE=$([[ $REPLY == 2 ]] && echo glass || echo classic)
    fi
  fi
  if [[ -z $MODE ]]; then
    MODE=${PREV_MODE:-split}
    if (( CAN_ASK )); then
      mode_idx=1; [[ $MODE == dark ]] && mode_idx=2; [[ $MODE == light ]] && mode_idx=3
      choose "$(t '本机和远程' 'Local and remote')" $mode_idx \
        "$(t 分开 Split)|$(t '本机浅色，ssh 到服务器自动换深色' 'light here, dark automatically on ssh')" \
        "$(t 全深色 Dark)|$(t '到处都用深色' 'dark everywhere')" \
        "$(t 全浅色 Light)|$(t '到处都用浅色' 'light everywhere')"
      case $REPLY in 2) MODE=dark ;; 3) MODE=light ;; *) MODE=split ;; esac
    fi
  fi
  # one command into tmux on a server (optional)
  if [[ -z $TMUX_HOST ]]; then
    TMUX_HOST=$PREV_TMUX_HOST
    if (( CAN_ASK )); then
      printf '\n  %s ? %s %s%s%s\n' "$BG_SAPPHIRE$WHITE$BOLD" "$N" "$BLUE$BOLD" "$(t '一键进服务器 tmux（可选）' 'One command into tmux on a server (optional)')" "$N"
      printf '     %s%s%s\n' "$MUTE" "$(t '填 user@host 或 ~/.ssh/config 里的名字，多个用空格隔开；回车跳过，以后可用 dusk tmux 设置' 'user@host or names from ~/.ssh/config, space separated; Enter to skip (later: dusk tmux)')" "$N"
      printf '     %s❯%s %s' "$PINK" "$N" "$(t "服务器 [${TMUX_HOST:-跳过}]：" "Server [${TMUX_HOST:-skip}]: ")"
      IFS= read -r ans </dev/tty || ans=""
      [[ -n $ans ]] && TMUX_HOST=$ans
      if [[ -n $TMUX_HOST ]]; then
        printf '     %s❯%s %s' "$PINK" "$N" "$(t "命令叫什么 [${TMUX_CMD:-tm}]：" "Command name [${TMUX_CMD:-tm}]: ")"
        IFS= read -r ans </dev/tty || ans=""
        [[ -n $ans ]] && TMUX_CMD=$ans
      fi
    fi
  fi
fi
STYLE=${STYLE:-classic}; MODE=${MODE:-split}
if [[ $STYLE == glass ]]; then LIGHT_P="Dusk Glass Light"; DARK_P="Dusk Glass Dark"
else                          LIGHT_P="Dusk Light";  DARK_P="Dusk Dark"; fi
case $MODE in
  split) LOCAL_P=$LIGHT_P; REMOTE_P=$DARK_P; AUTO=1 ;;
  dark)  LOCAL_P=$DARK_P;  REMOTE_P=$DARK_P; AUTO=0 ;;
  light) LOCAL_P=$LIGHT_P; REMOTE_P=$LIGHT_P; AUTO=0 ;;
esac

# command names other tools already define (GCR, your aliases): dusk will leave them alone
OUR_NAMES="del|rm|delf|empty_trash|gita|gitaa|gitb|gitst|gitl|gitr|gitpl|gitps|gitc|gitch|sz|szn|pid|port|pathadd|mychmod|mychown|cl|sc|listen|upload|download|dps|dsh|dlog|dockeradd"
TAKEN=""
if [[ -f $ZSHRC ]]; then
  rcfiles=("$ZSHRC")
  while IFS= read -r f; do
    f="${f/#\~/$HOME}"; f="${f//\$HOME/$HOME}"; f="${f//\"/}"
    [[ -f $f && $f != "$CONF_DIR"* ]] && rcfiles+=("$f")
  done < <(sed -nE 's/^[[:space:]]*(source|\.)[[:space:]]+([^;&|[:space:]]+).*/\2/p' "$ZSHRC")
  TAKEN="$(cat "${rcfiles[@]}" 2>/dev/null \
    | sed -nE "s/^[[:space:]]*(alias[[:space:]]+|function[[:space:]]+)?($OUR_NAMES)(=|[[:space:]]*\(\)|[[:space:]]*\{).*/\2/p" \
    | sort -u | tr '\n' ' ')"
fi

# ─── 1. iTerm2 profiles (macOS) ──────────────────────────────────────────────
if [[ $OS == Darwin && $ROLE == local ]] && { has_mod theme || (( THEMES_ONLY )); }; then
  step "$(t 主题 Themes)"
  mkdir -p "$ITERM_DIR"
  # other files defining the same profiles (same GUIDs) would clash: move them to a backup
  for f in "$ITERM_DIR"/*.json; do
    [[ -f $f && $(basename "$f") != dusk.json ]] || continue
    if grep -qE '6f1c9e2a-5b7d-4c1e-9a3f-5a4b7c9e2d01|3d7a1c52-8e4b-4f0a-b6d2-0d1a7e5c9f02|a4e1c7d2-2f6b-4c8a-9e3d-1b7f5a9c0e11|b5f2d8e3-3a7c-4d9b-8f4e-2c8a6b0d1f22' "$f"; then
      mkdir -p "$CONF_DIR/backup"; mv "$f" "$CONF_DIR/backup/"
      ok "$(t '移走重复的配置文件' 'moved a clashing profile')" "$(basename "$f") → $(short "$CONF_DIR")/backup"
    fi
  done
  cp "$REPO_DIR/iterm/dusk.json" "$ITERM_DIR/dusk.json"
  ok "$(t 'iTerm2 配置文件' 'iTerm2 profiles')" "Dusk Light · Dusk Dark · Dusk Glass Light · Glass Dark"
  if [[ $MODE == split ]]; then ok "$(t '本机 / 远程' 'local / remote')" "$LOCAL_P → $REMOTE_P"
  else ok "$(t '统一配色' 'one look')" "$LOCAL_P"; fi
  [[ -d /Applications/iTerm.app ]] || warn "$(t '没找到 iTerm2，可在 https://iterm2.com 下载' 'iTerm2 not found — get it at https://iterm2.com')"
  NOTES+=("$(t "把 $LOCAL_P 设为默认：" "Make $LOCAL_P the default:")|iTerm2 → Settings → Profiles → Other Actions…")
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
      have "$c" || { warn "$(t "缺少 $c。安装需要管理员权限（不会替你输入 sudo 密码）：请让管理员装好，或用不需要 sudo 的方式装在自己目录下，然后重新运行。" "$c is missing. Installing it needs admin rights (this script never asks for a sudo password): ask your admin, or install it in your home folder, then rerun.")"; echo; exit 1; }
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
cp "$REPO_DIR/zsh/dusk.zsh" "$CONF_DIR/"
cp "$REPO_DIR"/zsh/modules/*.zsh "$CONF_DIR/modules/"
mkdir -p "$CONF_DIR/viewer" && cp "$REPO_DIR/viewer/dusk_view.py" "$CONF_DIR/viewer/"
if [[ $P10K_LAYOUT == 0 && $(cfg_get DUSK_P10K_LAYOUT) == 1 ]]; then
  P10K_LAYOUT=1   # keep the layout we set up on an earlier run
fi
cfg_line() { [[ -n $2 ]] && printf ": \${%s:='%s'}\n" "$1" "${2//\'/}"; return 0; }
{
  echo "# Dusk settings. install.sh, \`dusk theme\` and \`dusk tmux\` keep this file up to date."
  echo "typeset -ga DUSK_MODULES=(${MODULES//,/ })"
  cfg_line DUSK_ROLE "$ROLE"
  cfg_line DUSK_REPO "$REPO_DIR"
  cfg_line DUSK_P10K_LAYOUT "$P10K_LAYOUT"
  cfg_line DUSK_STYLE "$STYLE"
  cfg_line DUSK_MODE "$MODE"
  cfg_line DUSK_TMUX_HOST "${TMUX_HOST%% *}"
  cfg_line DUSK_TMUX_HOSTS "$TMUX_HOST"
  cfg_line DUSK_TMUX_SESSION "$TMUX_SESSION"
  cfg_line DUSK_TMUX_CMD "$TMUX_CMD"
  cfg_line DUSK_TMUX_PROFILE "$TMUX_PROFILE"
} > "$CONF_DIR/config.zsh"
ok "$(t 'zsh 模块' 'zsh modules')" "$(short "$CONF_DIR")"
if [[ -n $TAKEN ]] && { has_mod tools || has_mod remote; }; then
  first=1
  while IFS= read -r l; do
    if (( first )); then skip "$(t '保留你已有的命令' 'keeping your commands')" "$l"; first=0
    else printf '     %s  %s %s%s\n' "$MUTE" "$(pad "" 24)" "$l" "$N"; fi
  done < <(wrap 30 "$TAKEN")
  NOTES+=("$(t '这些命令保留了你原来的版本：' 'These kept your existing version:')|$TAKEN")
fi

touch "$ZSHRC"
cp "$ZSHRC" "$ZSHRC.bak-dusk"
# an older welcome banner would show up next to Dusk's Control Center: switch its call off
if grep -qE '^[[:space:]]*show_terminal_welcome[[:space:]]*$' "$ZSHRC"; then
  sed -i.tmp -E 's/^([[:space:]]*)show_terminal_welcome[[:space:]]*$/\1# show_terminal_welcome   # replaced by the Dusk Control Center (hud)/' "$ZSHRC" && rm -f "$ZSHRC.tmp"
  OLD_WELCOME=1
fi
awk -v b="$BEGIN" -v e="$END" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$ZSHRC.bak-dusk" > "$ZSHRC"
conf_ref="${CONF_DIR/#$HOME/\$HOME}"
{
  echo "$BEGIN"
  echo "[[ -f \"$conf_ref/dusk.zsh\" ]] && source \"$conf_ref/dusk.zsh\""
  echo "$END"
} >> "$ZSHRC"
ok "$(short "$ZSHRC")" "$(t '已接入，备份为 .zshrc.bak-dusk' 'hooked, backup at .zshrc.bak-dusk')"
[[ -n ${OLD_WELCOME:-} ]] && ok "$(t '旧的欢迎面板' 'old welcome banner')" "$(t '已停用，由控制中心代替' 'switched off, the Control Center replaces it')"
if [[ -n $TMUX_HOST ]]; then ok "${TMUX_CMD:-tm}" "tmux → $TMUX_HOST"; fi

# ─── 4. done ─────────────────────────────────────────────────────────────────
if has_mod shell && [[ $OS == Darwin ]] && ! ls "$HOME/Library/Fonts" /Library/Fonts 2>/dev/null | grep -qi nerdfont; then
  NOTES+=("$(t '图标需要 Nerd Font：' 'Icons need a Nerd Font:')|brew install --cask font-jetbrains-mono-nerd-font")
fi
if [[ "$(basename "${SHELL:-}")" != zsh ]] && have zsh && ! grep -qs 'exec .*zsh' "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.bashrc"; then
  NOTES+=("$(t '默认 shell 还不是 zsh，切换：' 'Your login shell is not zsh yet:')|chsh -s $(command -v zsh)")
fi

echo
card_top "$(t '✓ 完成' '✓ Done')"
card_line ""
cmdline() {  # cmdline <before> <command> <after>: command in pink
  card_line "$1$2$3" "$1$PINK$BOLD$2$N$3"
}
cmdline "$(t '新开一个终端，或运行 ' 'Open a new terminal, or run ')" "exec zsh" ""
cmdline "$(t '输入 ' 'Type ')" "dusk" "$(t '   打开命令面板，所有功能都在里面' '   for the command palette (everything)')"
cmdline "$(t '输入 ' 'Type ')" "hud" "$(t '    打开控制中心' '    for the Control Center')"
if (( ${#NOTES[@]} )); then
  card_line ""
  card_line "$(t '还差一步' 'One more thing')" "$SKY$BOLD$(t '还差一步' 'One more thing')$N"
  for n in "${NOTES[@]}"; do
    card_line "${n%%|*}"
    while IFS= read -r l; do card_line "  $l" "  $PINK$l$N"; done < <(wrap $(( WIDTH - 8 )) "${n#*|}")
  done
fi
card_line ""
card_bottom
echo
