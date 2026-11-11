# modules/theme.zsh — blue/pink colors, iTerm2 profile switching, `st`
# Part of Dusk: https://github.com/liuxiaZzz/dusk-term
# Settings can be overridden in ~/.zshrc before the dusk source line.

# ─── settings (written by install.sh / `dusk theme` / `dusk tmux` into config.zsh) ─
: ${DUSK_STYLE:=classic}          # classic | glass
: ${DUSK_MODE:=split}             # split (light here, dark on remote) | dark | light
: ${DUSK_P10K_COLORS:=1}          # 1 = recolor powerlevel10k segments
: ${DUSK_SYNTAX_COLORS:=1}        # 1 = while typing: valid commands blue, typos pink
: ${DUSK_TMUX_HOST:=}             # default host for the tmux command, e.g. me@server; empty = off
: ${DUSK_TMUX_HOSTS:=}            # all hosts the tmux picker looks at (space separated); default: DUSK_TMUX_HOST
: ${DUSK_BADGE:=1}                # 1 = small hostname watermark while on a server
: ${DUSK_TMUX_SESSION:=main}      # default tmux session
: ${DUSK_TMUX_CMD:=st}            # name of the tmux command (st, jt, ...)
: ${DUSK_TMUX_PROFILE:=}          # iTerm2 profile for tmux windows; empty = the remote profile

# style + mode → which iTerm2 profile is used where (recomputed by `dusk theme`)
_dusk_profiles() {
  local light dark
  if [[ $DUSK_STYLE == glass ]]; then light="Dusk Glass Light"; dark="Dusk Glass Dark"
  else light="Dusk Light"; dark="Dusk Dark"; fi
  case $DUSK_MODE in
    dark)  typeset -g DUSK_LOCAL_PROFILE=$dark  DUSK_REMOTE_PROFILE=$dark  DUSK_AUTO_SWITCH=0 ;;
    light) typeset -g DUSK_LOCAL_PROFILE=$light DUSK_REMOTE_PROFILE=$light DUSK_AUTO_SWITCH=0 ;;
    *)     typeset -g DUSK_LOCAL_PROFILE=$light DUSK_REMOTE_PROFILE=$dark  DUSK_AUTO_SWITCH=1 ;;
  esac
}
_dusk_profiles

_dusk_local_iterm() {
  [[ $TERM_PROGRAM == iTerm.app && -z $SSH_CONNECTION && -z $TMUX ]]
}

# ─── 1. powerlevel10k: six muted blue/pink tones ────────────────────────────
if (( DUSK_P10K_COLORS )); then
  () {
    local hot='#e48bb4' pastel='#efc6db' sapphire='#4a62ad'
    local sky='#a3cbe6' peri='#b7c0e6'   navy='#1d2a4c'
    local ink='#18213f' white='#f6f7fc'  rose='#d9647f'

    typeset -g POWERLEVEL9K_OS_ICON_BACKGROUND=$hot   POWERLEVEL9K_OS_ICON_FOREGROUND=$white
    typeset -g POWERLEVEL9K_DIR_BACKGROUND=$sapphire  POWERLEVEL9K_DIR_FOREGROUND=$white
    typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND='#c6cfea' POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=$white

    typeset -g POWERLEVEL9K_VCS_CLEAN_BACKGROUND=$pastel
    typeset -g POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND='#f3d5e5'
    typeset -g POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='#e3a3c3'
    typeset -g POWERLEVEL9K_VCS_CONFLICTED_BACKGROUND=$rose
    typeset -g POWERLEVEL9K_VCS_LOADING_BACKGROUND='#5f7099'

    typeset -g POWERLEVEL9K_RAM_BACKGROUND=$sky       POWERLEVEL9K_RAM_FOREGROUND=$ink
    typeset -g POWERLEVEL9K_DISK_USAGE_NORMAL_BACKGROUND=$navy    POWERLEVEL9K_DISK_USAGE_NORMAL_FOREGROUND='#e9aecb'
    typeset -g POWERLEVEL9K_DISK_USAGE_WARNING_BACKGROUND=$pastel POWERLEVEL9K_DISK_USAGE_WARNING_FOREGROUND=$ink
    typeset -g POWERLEVEL9K_DISK_USAGE_CRITICAL_BACKGROUND=$rose  POWERLEVEL9K_DISK_USAGE_CRITICAL_FOREGROUND=$white

    local s
    for s in OK OK_PIPE; do
      typeset -g POWERLEVEL9K_STATUS_${s}_BACKGROUND=$navy POWERLEVEL9K_STATUS_${s}_FOREGROUND=$sky
    done
    for s in ERROR ERROR_PIPE ERROR_SIGNAL; do
      typeset -g POWERLEVEL9K_STATUS_${s}_BACKGROUND=$rose POWERLEVEL9K_STATUS_${s}_FOREGROUND=$white
    done

    typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND=$pastel POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$ink
    typeset -g POWERLEVEL9K_BACKGROUND_JOBS_BACKGROUND=$navy POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=$sky
    typeset -g POWERLEVEL9K_ANACONDA_BACKGROUND=$sapphire    POWERLEVEL9K_ANACONDA_FOREGROUND=$white
    typeset -g POWERLEVEL9K_VIRTUALENV_BACKGROUND=$sapphire  POWERLEVEL9K_VIRTUALENV_FOREGROUND=$white
    typeset -g POWERLEVEL9K_CPU_ARCH_BACKGROUND=$hot         POWERLEVEL9K_CPU_ARCH_FOREGROUND=$white
    typeset -g POWERLEVEL9K_TIME_BACKGROUND=$peri            POWERLEVEL9K_TIME_FOREGROUND=$ink
  }
  (( ! $+functions[p10k] )) || p10k reload
fi

# ─── 1b. typing colors (zsh-syntax-highlighting): right = blue, typo = pink ──
# Uses the theme's own ANSI blue (4) and pink (5), so it fits all four themes.
if (( DUSK_SYNTAX_COLORS )); then
  typeset -gA ZSH_HIGHLIGHT_STYLES
  () {
    local k
    for k in command builtin alias suffix-alias global-alias function precommand \
             hashed-command reserved-word arg0 autodirectory; do
      ZSH_HIGHLIGHT_STYLES[$k]='fg=4,bold'
    done
    ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=5'
    ZSH_HIGHLIGHT_STYLES[path]='underline'
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=3'
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=3'
  }
fi

# ─── 2. remote sessions use the remote profile, then switch back ────────────
_dusk_set_profile() { printf '\e]1337;SetProfile=%s\a' "$1" }
# the hostname watermark: iTerm2 profiles show the user variable duskHost as a badge
_dusk_badge() { (( DUSK_BADGE )) && printf '\e]1337;SetUserVar=duskHost=%s\a' "$(print -rn -- "$1" | base64 | tr -d '\n')" }

# host from ssh-style arguments: the first word that isn't an option or an option's value
_dusk_ssh_host() {
  local a skip=0
  for a in "$@"; do
    if (( skip )); then skip=0; continue; fi
    case $a in
      -[bcDEeFIiJLlmOopQRSWw]) skip=1 ;;
      -*) ;;
      *) a=${a#*@}; print -r -- ${a%%:*}; return ;;
    esac
  done
}

if _dusk_local_iterm; then
  _dusk_remote() {
    local host=$(_dusk_ssh_host "${@:2}")
    (( DUSK_AUTO_SWITCH )) && _dusk_set_profile "$DUSK_REMOTE_PROFILE"
    [[ -n $host ]] && _dusk_badge "$host"
    command "$@"
    local rc=$?
    _dusk_badge ""
    (( DUSK_AUTO_SWITCH )) && _dusk_set_profile "${ITERM_PROFILE:-$DUSK_LOCAL_PROFILE}"
    return $rc
  }
  # `function name` form so it still works when e.g. `tssh` is an alias
  function ssh  { _dusk_remote ssh  "$@" }
  function mosh { _dusk_remote mosh "$@" }
  (( $+commands[tssh] )) && function tssh { _dusk_remote tssh "$@" }
elif [[ -n $SSH_CONNECTION ]] && (( DUSK_BADGE )); then
  # on a server (also inside iTerm2's tmux windows): name this machine in the watermark,
  # once, at the first prompt
  _dusk_badge_once() { add-zsh-hook -d precmd _dusk_badge_once; _dusk_badge "${HOST%%.*}" }
  autoload -Uz add-zsh-hook; add-zsh-hook precmd _dusk_badge_once
fi

# ─── 3. tmux on servers in one command (iTerm2 tmux integration) ────────────
#   jt               pick from the tmux sessions on all your servers, or start a new one
#   jt work          session "work" on the default server
#   jt host work     session "work" on that server
#   jt host          session $DUSK_TMUX_SESSION on any host from ~/.ssh/config
# The command name is $DUSK_TMUX_CMD (set with `dusk tmux`). Windows open in a NEW iTerm2
# window that already uses the right profile, so the tmux windows inherit it.
_dusk_tmux_hosts() { reply=(${=DUSK_TMUX_HOSTS:-$DUSK_TMUX_HOST}) }
# every concrete Host name in ~/.ssh/config (wildcards skipped)
_dusk_ssh_config_hosts() {
  reply=(${(f)"$(awk 'tolower($1)=="host" {for (i=2;i<=NF;i++) if ($i !~ /[*?!]/) print $i}' ~/.ssh/config 2>/dev/null)"})
}

_dusk_tmux_open() {   # _dusk_tmux_open <host> <session>
  osascript - "${DUSK_TMUX_PROFILE:-$DUSK_REMOTE_PROFILE}" "$1" "$2" <<'APPLESCRIPT'
on run argv
  tell application "iTerm2"
    create window with profile (item 1 of argv) command "ssh -t " & (item 2 of argv) & " \"tmux -CC new-session -A -s " & (item 3 of argv) & "\""
  end tell
end run
APPLESCRIPT
}

_dusk_ago() {
  local s=$1
  if   (( s < 60 ));    then REPLY="刚刚"
  elif (( s < 3600 ));  then REPLY="$(( s / 60 )) 分钟前"
  elif (( s < 86400 )); then REPLY="$(( s / 3600 )) 小时前"
  else REPLY="$(( s / 86400 )) 天前"; fi
}

_dusk_tmux_pick() {
  setopt local_options no_monitor no_notify
  _dusk_tmux_hosts; local -a hosts=($reply)
  local tmp=$(mktemp -d) h p
  local -a pids=()
  for h in $hosts; do
    ( command ssh -o BatchMode=yes -o ConnectTimeout=4 -o ClearAllForwardings=yes "$h" \
        'echo "now $(date +%s)"; tmux ls -F "s #{session_name}|#{session_windows}|#{session_attached}|#{session_activity}" 2>/dev/null' \
        >"$tmp/${h//\//_}" 2>/dev/null || echo fail >"$tmp/${h//\//_}" ) &
    pids+=($!)
  done
  local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0 alive
  while :; do
    alive=0; for p in $pids; do kill -0 $p 2>/dev/null && alive=1; done
    (( alive && i < 100 )) || break                 # all answered, or ~8 s passed
    (( i >= 99 )) && kill $pids 2>/dev/null
    printf '\r  \e[38;2;228;139;180m%s\e[0m 正在查看 %s 台服务器上的 tmux 会话…' "${frames:$(( i++ % 10 )):1}" $#hosts
    sleep 0.08
  done
  printf '\r\e[K'

  local -a rows=() keys=() lines
  local line now name win att act host_ok
  for h in $hosts; do
    lines=("${(@f)$(<$tmp/${h//\//_} 2>/dev/null)}")
    if [[ -z $lines[1] || $lines[1] == fail* ]]; then
      rows+=("$(printf '\e[38;2;127;132;163m%-16s  连不上（需要密码或网络不通），仍可新建\e[0m' $h)"); keys+=("$h|")
    else
      now=${${(M)lines:#now *}#now }
      for line in ${(M)lines:#s *}; do
        line=${line#s }
        name=${line%%|*}; line=${line#*|}; win=${line%%|*}; line=${line#*|}; att=${line%%|*}; act=${line#*|}
        _dusk_ago $(( ${now:-0} - ${act:-0} ))
        rows+=("$(printf '\e[38;2;122;162;255m%-16s\e[0m  \e[1m%-14s\e[0m %2s 个窗口  %s  \e[38;2;127;132;163m%s\e[0m' \
          $h $name $win "$( (( att > 0 )) && print -n '\e[38;2;228;139;180m● 已连接\e[0m' || print -n '○ 未连接')" "$REPLY")")
        keys+=("$h|$name")
      done
    fi
    rows+=("$(printf '\e[38;2;122;162;255m%-16s\e[0m  \e[38;2;228;139;180m＋ 新建会话\e[0m' $h)"); keys+=("$h|+")
  done
  command rm -rf "$tmp"
  _dusk_ssh_config_hosts; local -a others=(${reply:|hosts})
  if (( $#others )); then
    rows+=("$(printf '\e[38;2;228;139;180m＋ 其他服务器…\e[0m  \e[38;2;127;132;163m~/.ssh/config 里还有 %s 台\e[0m' $#others)"); keys+=("|other")
  fi

  local idx
  if (( $+commands[fzf] )) && [[ -t 0 && -t 1 ]]; then
    local n=0 pick
    pick=$(for line in $rows; do (( n++ )); printf '%3d  %s\n' $n "$line"; done | \
      fzf --ansi --height=50% --layout=reverse --border=rounded --prompt='tmux › ' --info=hidden \
          --header='选一个会话回车进入；Esc 取消' \
          --color='border:#e48bb4,prompt:#7aa2ff,pointer:#e48bb4,hl:#e48bb4,hl+:#e48bb4,header:8') || return 0
    idx=${${=pick}[1]}
  else
    print
    local n=0; for line in $rows; do (( n++ )); printf '  \e[38;2;122;162;255m%2d\e[0m  %s\n' $n "$line"; done
    read -r "idx?$(print -n '  \e[38;2;228;139;180m❯\e[0m ')输入编号（回车取消）："
  fi
  [[ $idx == <-> ]] && (( idx >= 1 && idx <= $#keys )) || return 0
  h=${keys[idx]%%|*}; name=${keys[idx]#*|}
  if [[ $name == other ]]; then
    _dusk_pick_other_host "${others[@]}" || return 0
    h=$REPLY; name=+
  fi
  if [[ -z $name || $name == + ]]; then
    read -r "name?$(print -n '  \e[38;2;228;139;180m❯\e[0m ')在 $h 上新建的会话名 [${DUSK_TMUX_SESSION}]："
    name=${name:-$DUSK_TMUX_SESSION}
  fi
  _dusk_tmux_open "$h" "$name"
}

# choose one of the given hosts (fzf or numbered); offers to add it to the tmux list → REPLY
_dusk_pick_other_host() {
  local -a list=("$@"); local pick idx n=0 h
  if (( $+commands[fzf] )) && [[ -t 0 && -t 1 ]]; then
    pick=$(for h in $list; do (( n++ )); printf '%3d  \e[38;2;122;162;255m%s\e[0m\n' $n $h; done | \
      fzf --ansi --height=50% --layout=reverse --border=rounded --prompt='服务器 › ' --info=hidden \
          --header='~/.ssh/config 里的服务器；回车选择，Esc 返回' \
          --color='border:#e48bb4,prompt:#7aa2ff,pointer:#e48bb4,hl:#e48bb4,hl+:#e48bb4,header:8') || return 1
    idx=${${=pick}[1]}
  else
    print; for h in $list; do (( n++ )); printf '  \e[38;2;122;162;255m%2d\e[0m  %s\n' $n $h; done
    read -r "idx?$(print -n '  \e[38;2;228;139;180m❯\e[0m ')选服务器编号（回车取消）："
  fi
  [[ $idx == <-> ]] && (( idx >= 1 && idx <= $#list )) || return 1
  h=$list[idx]
  local yn
  read -r "yn?$(print -n '  \e[38;2;228;139;180m❯\e[0m ')把 $h 加入 $DUSK_TMUX_CMD 的常用列表，以后每次都显示它的会话？[Y/n] "
  if [[ $yn != [nN]* ]] && (( $+functions[_dk_config_set] )); then
    _dusk_tmux_hosts; local -a merged=(${(u)reply} $h)
    _dk_config_set DUSK_TMUX_HOSTS "${merged[*]}"
    [[ -z $DUSK_TMUX_HOST ]] && _dk_config_set DUSK_TMUX_HOST "$h"
  fi
  REPLY=$h
}

_dusk_tmux() {
  _dusk_tmux_hosts; local -a hosts=($reply)
  (( $#hosts )) || { print "还没设置服务器：运行 dusk tmux"; return 1 }
  if (( $# == 0 )); then _dusk_tmux_pick; return; fi
  _dusk_ssh_config_hosts; local -a known=($reply)
  if (( $# >= 2 )) || (( ${hosts[(Ie)$1]} || ${known[(Ie)$1]} )); then _dusk_tmux_open "$1" "${2:-$DUSK_TMUX_SESSION}"
  else _dusk_tmux_open "$hosts[1]" "$1"; fi
}

_dusk_bind_tmux() {   # (re)define the user's chosen command name
  [[ -n ${DUSK_TMUX_HOSTS:-$DUSK_TMUX_HOST} && -n $DUSK_TMUX_CMD ]] && _dusk_local_iterm || return 0
  (( $+aliases[$DUSK_TMUX_CMD] )) && unalias $DUSK_TMUX_CMD
  functions[$DUSK_TMUX_CMD]='_dusk_tmux "$@"'
}
_dusk_bind_tmux
