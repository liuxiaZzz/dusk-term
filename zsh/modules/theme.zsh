# modules/theme.zsh — blue/pink colors, iTerm2 profile switching, `st`
# Part of Sakura Term: https://github.com/liuxiaZzz/sakura-term
# Settings can be overridden in ~/.zshrc before the sakura-term source line.

# ─── settings ────────────────────────────────────────────────────────────────
: ${SAKURA_LOCAL_PROFILE:="Mist Sakura"}    # fallback local profile when switching back
: ${SAKURA_REMOTE_PROFILE:="Sakura Glass"}  # profile used while in ssh / tssh / mosh
: ${SAKURA_AUTO_SWITCH:=1}                  # 1 = switch profile on remote sessions
: ${SAKURA_P10K_COLORS:=1}                  # 1 = recolor powerlevel10k segments
: ${SAKURA_TMUX_HOST:=}                     # host for `st` (e.g. "me@server"); empty = disabled
: ${SAKURA_TMUX_SESSION:=main}              # default tmux session name for `st`
                                            # SAKURA_TMUX_PROFILE: profile for `st` windows (default: remote profile)

_sakura_local_iterm() {
  [[ $TERM_PROGRAM == iTerm.app && -z $SSH_CONNECTION && -z $TMUX ]]
}

# ─── 1. powerlevel10k: six muted blue/pink tones ────────────────────────────
if (( SAKURA_P10K_COLORS )); then
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

# ─── 2. remote sessions use the dark theme, local keeps your default ────────
if (( SAKURA_AUTO_SWITCH )) && _sakura_local_iterm; then
  _sakura_set_profile() { printf '\e]1337;SetProfile=%s\a' "$1" }

  _sakura_remote() {
    _sakura_set_profile "$SAKURA_REMOTE_PROFILE"
    command "$@"
    local rc=$?
    _sakura_set_profile "${ITERM_PROFILE:-$SAKURA_LOCAL_PROFILE}"
    return $rc
  }
  # `function name` form so it still works when e.g. `tssh` is an alias
  function ssh  { _sakura_remote ssh  "$@" }
  function mosh { _sakura_remote mosh "$@" }
  (( $+commands[tssh] )) && function tssh { _sakura_remote tssh "$@" }
fi

# ─── 3. st: jump into a remote tmux session (iTerm2 tmux integration) ───────
# Opens a NEW window that already uses the dark profile: iTerm2's tmux windows inherit the
# profile of the session that connects, so starting from a local (light) tab would make them light.
: ${SAKURA_TMUX_PROFILE:=$SAKURA_REMOTE_PROFILE}
if [[ -n $SAKURA_TMUX_HOST ]] && _sakura_local_iterm; then
  function st {
    osascript - "$SAKURA_TMUX_PROFILE" "$SAKURA_TMUX_HOST" "${1:-$SAKURA_TMUX_SESSION}" <<'APPLESCRIPT'
on run argv
  tell application "iTerm2"
    create window with profile (item 1 of argv) command "ssh -t " & (item 2 of argv) & " \"tmux -CC new-session -A -s " & (item 3 of argv) & "\""
  end tell
end run
APPLESCRIPT
  }
fi
