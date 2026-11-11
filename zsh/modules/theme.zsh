# modules/theme.zsh — blue/pink colors, iTerm2 profile switching, `st`
# Part of Dusk: https://github.com/liuxiaZzz/dusk-term
# Settings can be overridden in ~/.zshrc before the dusk source line.

# ─── settings (written by install.sh / `dusk theme` / `dusk tmux` into config.zsh) ─
: ${DUSK_STYLE:=classic}          # classic | glass
: ${DUSK_MODE:=split}             # split (light here, dark on remote) | dark | light
: ${DUSK_P10K_COLORS:=1}          # 1 = recolor powerlevel10k segments
: ${DUSK_TMUX_HOST:=}             # host for the tmux command, e.g. me@server; empty = off
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

# ─── 2. remote sessions use the remote profile, then switch back ────────────
_dusk_set_profile() { printf '\e]1337;SetProfile=%s\a' "$1" }
if _dusk_local_iterm; then
  _dusk_remote() {
    (( DUSK_AUTO_SWITCH )) || { command "$@"; return }
    _dusk_set_profile "$DUSK_REMOTE_PROFILE"
    command "$@"
    local rc=$?
    _dusk_set_profile "${ITERM_PROFILE:-$DUSK_LOCAL_PROFILE}"
    return $rc
  }
  # `function name` form so it still works when e.g. `tssh` is an alias
  function ssh  { _dusk_remote ssh  "$@" }
  function mosh { _dusk_remote mosh "$@" }
  (( $+commands[tssh] )) && function tssh { _dusk_remote tssh "$@" }
fi

# ─── 3. tmux on a server in one command (iTerm2 tmux integration) ───────────
# Opens a NEW window that already uses the right profile: iTerm2's tmux windows inherit the
# profile of the session that connects, so starting from a local (light) tab would make them light.
#   st            session $DUSK_TMUX_SESSION     st work      another session
# The command name is $DUSK_TMUX_CMD (set with `dusk tmux`).
_dusk_tmux() {
  [[ -n $DUSK_TMUX_HOST ]] || { print "还没设置服务器：运行 dusk tmux"; return 1 }
  osascript - "${DUSK_TMUX_PROFILE:-$DUSK_REMOTE_PROFILE}" "$DUSK_TMUX_HOST" "${1:-$DUSK_TMUX_SESSION}" <<'APPLESCRIPT'
on run argv
  tell application "iTerm2"
    create window with profile (item 1 of argv) command "ssh -t " & (item 2 of argv) & " \"tmux -CC new-session -A -s " & (item 3 of argv) & "\""
  end tell
end run
APPLESCRIPT
}
_dusk_bind_tmux() {   # (re)define the user's chosen command name
  [[ -n $DUSK_TMUX_HOST && -n $DUSK_TMUX_CMD ]] && _dusk_local_iterm || return 0
  (( $+aliases[$DUSK_TMUX_CMD] )) && unalias $DUSK_TMUX_CMD
  functions[$DUSK_TMUX_CMD]='_dusk_tmux "$@"'
}
_dusk_bind_tmux
