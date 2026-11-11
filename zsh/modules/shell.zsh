# modules/shell.zsh — oh-my-zsh + powerlevel10k + plugins, fzf, zoxide
# If your ~/.zshrc already loads oh-my-zsh, this module leaves it alone and only adds fzf/zoxide.

typeset -U path
path=($HOME/.local/bin $HOME/.fzf/bin $path)

# ─── oh-my-zsh (only when not already loaded by ~/.zshrc) ───────────────────
if (( ! $+functions[omz] )) && [[ -d ${ZSH:-$HOME/.oh-my-zsh} ]]; then
  export ZSH=${ZSH:-$HOME/.oh-my-zsh}
  : ${ZSH_CUSTOM:=$ZSH/custom}
  DISABLE_AUTO_UPDATE=true
  [[ -d $ZSH_CUSTOM/themes/powerlevel10k ]] && ZSH_THEME=powerlevel10k/powerlevel10k

  plugins=(git extract sudo gitignore)
  (( $+commands[docker] )) && plugins+=(docker docker-compose)
  local _p
  for _p in zsh-autosuggestions zsh-syntax-highlighting; do   # syntax-highlighting must be last
    [[ -d $ZSH_CUSTOM/plugins/$_p ]] && plugins+=($_p)
  done
  unset _p
  source $ZSH/oh-my-zsh.sh
  [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
fi

# ─── prompt layout (set by install.sh when it created ~/.p10k.zsh) ──────────
if (( ${SAKURA_P10K_LAYOUT:-0} )); then
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon dir vcs ram disk_usage newline prompt_char)
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs
                                                  virtualenv anaconda cpu_arch time newline)
  typeset -g POWERLEVEL9K_PROMPT_CHAR_BACKGROUND=
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND='#e48bb4'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND='#d9647f'
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'
  typeset -g POWERLEVEL9K_ANACONDA_SHOW_PYTHON_VERSION=false
fi

# ─── fzf: Ctrl-R history, Ctrl-T files, Alt-C dirs ──────────────────────────
if (( $+commands[fzf] )); then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  elif [[ -f ~/.fzf.zsh ]]; then
    source ~/.fzf.zsh
  fi
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border \
--color=fg:-1,bg:-1,hl:#e48bb4,fg+:-1,bg+:-1,hl+:#e48bb4,pointer:#e48bb4,marker:#7aa2ff,prompt:#7aa2ff,info:8,border:8"
fi

# ─── zoxide as `j` (skipped if autojump already provides j) ─────────────────
if (( $+commands[zoxide] )) && (( ! $+functions[j] && ! $+aliases[j] )); then
  eval "$(zoxide init zsh --cmd j)"
fi

# ─── extract: short alias for oh-my-zsh's `extract` ─────────────────────────
(( $+functions[extract] )) && alias x=extract
