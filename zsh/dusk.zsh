# Dusk — loader
# https://github.com/liuxiaZzz/dusk-term
#
# Sourced at the end of ~/.zshrc (install.sh adds the line).
# Modules live next to this file in modules/; which ones load is set in config.zsh
# (written by install.sh) or by DUSK_MODULES in ~/.zshrc before the source line.

[[ -o interactive ]] || return 0

typeset -g DUSK_DIR=${${(%):-%x}:A:h}
[[ -f $DUSK_DIR/config.zsh ]] && source $DUSK_DIR/config.zsh

# Language: DUSK_LANG=zh|en, default from the system locale. Messages pick their text with
# ${${DUSK_ZH:+中文}:-English} (no subshell, so it costs nothing).
if [[ -z $DUSK_LANG ]]; then
  [[ ${LC_ALL:-${LC_MESSAGES:-$LANG}} == zh* ]] && DUSK_LANG=zh || DUSK_LANG=en
fi
typeset -g DUSK_ZH=; [[ $DUSK_LANG == zh ]] && DUSK_ZH=1
(( ${+DUSK_MODULES} )) || typeset -ga DUSK_MODULES=(shell theme tools remote)

# Public command names are bound with _dk_bind, which leaves a name alone when another tool
# (GCR, oh-my-zsh plugins, your own aliases) already defines it. DUSK_OVERRIDE=1 binds anyway.
typeset -ga DUSK_SKIPPED=()
_dk_bind() {   # _dk_bind <name> <alias value> [quiet]
  local name=$1 val=$2
  if (( ! ${DUSK_OVERRIDE:-0} )) && (( $+aliases[$name] || $+functions[$name] )); then
    [[ ${aliases[$name]} == "$val" || -n $3 ]] || DUSK_SKIPPED+=($name)
    return 1
  fi
  alias $name="$val"
}

# fixed load order: shell sets up oh-my-zsh/p10k first, theme recolors it, then helpers.
# Sourced at top level (not inside a function) so modules and oh-my-zsh define globals.
for _dusk_m in shell theme tools remote; do
  (( ${DUSK_MODULES[(Ie)$_dusk_m]} )) && [[ -f $DUSK_DIR/modules/$_dusk_m.zsh ]] && source $DUSK_DIR/modules/$_dusk_m.zsh
done
unset _dusk_m
source $DUSK_DIR/modules/center.zsh   # Control Center: `cc`, shown on new tabs
source $DUSK_DIR/modules/core.zsh
