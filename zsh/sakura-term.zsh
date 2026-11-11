# Sakura Term — loader
# https://github.com/liuxiaZzz/sakura-term
#
# Sourced at the end of ~/.zshrc (install.sh adds the line).
# Modules live next to this file in modules/; which ones load is set in config.zsh
# (written by install.sh) or by SAKURA_MODULES in ~/.zshrc before the source line.

[[ -o interactive ]] || return 0

typeset -g SAKURA_DIR=${${(%):-%x}:A:h}
[[ -f $SAKURA_DIR/config.zsh ]] && source $SAKURA_DIR/config.zsh
(( ${+SAKURA_MODULES} )) || typeset -ga SAKURA_MODULES=(shell theme tools remote)

# fixed load order: shell sets up oh-my-zsh/p10k first, theme recolors it, then helpers.
# Sourced at top level (not inside a function) so modules and oh-my-zsh define globals.
for _sakura_m in shell theme tools remote; do
  (( ${SAKURA_MODULES[(Ie)$_sakura_m]} )) && [[ -f $SAKURA_DIR/modules/$_sakura_m.zsh ]] && source $SAKURA_DIR/modules/$_sakura_m.zsh
done
unset _sakura_m
source $SAKURA_DIR/modules/center.zsh   # Control Center: `cc`, shown on new tabs
source $SAKURA_DIR/modules/core.zsh
