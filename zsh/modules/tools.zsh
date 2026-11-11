# modules/tools.zsh — everyday shortcuts (macOS + Linux)
# Ideas adapted from GCR (https://github.com/gaojunbin/GCR, Apache-2.0); rewritten to be
# non-interactive-friendly and portable. See NOTICE.

: ${SAKURA_SAFE_RM:=1}   # 1 = `rm` moves files to the trash instead of deleting

# ─── trash instead of rm ─────────────────────────────────────────────────────
_sk_trash_dir() {
  if [[ $OSTYPE == darwin* ]]; then print -r -- $HOME/.Trash
  else print -r -- ${XDG_DATA_HOME:-$HOME/.local/share}/Trash; fi
}

# del <file>...   flags like -r -f -i are accepted and ignored (everything goes to the trash)
del() {
  local -a files; local a seen_dd=0
  for a in "$@"; do
    if (( seen_dd )) || [[ $a != -* ]]; then files+=("$a")
    elif [[ $a == -- ]]; then seen_dd=1; fi
  done
  (( $#files )) || { print "用法: del <文件或目录>...   （移到回收站，可恢复）"; return 1 }

  local f missing=0; local -a existing
  for f in "${files[@]}"; do         # plain test, no globbing: a file named '*' stays just that file
    if [[ -e $f || -L $f ]]; then existing+=("$f"); else print -u2 "del: 不存在: $f"; missing=1; fi
  done
  files=("${existing[@]}")
  (( $#files )) || return $missing

  # absolute paths: no '--' needed (macOS trash rejects it) and names starting with '-' are safe
  local -a abs=(${files:a})
  if [[ $OSTYPE == darwin* && -x /usr/bin/trash ]]; then
    /usr/bin/trash $abs                            # macOS 14+: Finder trash, "Put Back" works
  elif [[ $OSTYPE != darwin* ]] && (( $+commands[gio] )) && gio trash $abs 2>/dev/null; then
    :                                              # Linux desktop trash
  else
    local dir=$(_sk_trash_dir) name dest stamp=$(date +%Y%m%d-%H%M%S)
    if [[ $OSTYPE == darwin* ]]; then
      mkdir -p $dir
      for f in $files; do
        name=${f:t}; dest=$dir/$name
        [[ -e $dest ]] && dest=$dir/${name}.$stamp.$RANDOM
        command mv -- $f $dest
      done
    else
      mkdir -p $dir/files $dir/info
      for f in $files; do
        name=${f:t}; dest=$name
        [[ -e $dir/files/$dest ]] && dest=${name}.$stamp.$RANDOM
        command mv -- $f $dir/files/$dest &&
          printf '[Trash Info]\nPath=%s\nDeletionDate=%s\n' "${f:A}" "$(date +%Y-%m-%dT%H:%M:%S)" > $dir/info/$dest.trashinfo
      done
    fi
  fi
  return $missing
}

empty_trash() {
  local dir=$(_sk_trash_dir)
  _sk_ask "永久清空回收站 $dir ？" || return 1
  if [[ $OSTYPE == darwin* ]]; then
    osascript -e 'tell application "Finder" to empty trash' 2>/dev/null || command rm -rf -- $dir/*(DN)
  elif (( $+commands[gio] )) && gio trash --empty 2>/dev/null; then
    :
  else
    command rm -rf -- $dir/files/*(DN) $dir/info/*(DN)
  fi
}

if (( SAKURA_SAFE_RM )); then
  alias rm=del
  alias delf='command rm -rf'
fi

# ─── git shortcuts ───────────────────────────────────────────────────────────
alias gita='git add'
alias gitaa='git add .'
alias gitb='git branch'
alias gitst='git status -sb'
alias gitl='git log --oneline --graph --decorate -20'
alias gitr='git reset'
alias gitpl='git pull'
alias gitps='git push origin HEAD'          # push the current branch

gitc() {                                    # gitc fix typo   /   gitc  (asks)
  local msg="$*"
  [[ -n $msg ]] || read -r "msg?提交说明: "
  [[ -n $msg ]] && git commit -m "$msg"
}

gitch() {                                   # gitch dev   /   gitch  (pick a branch)
  if [[ -n $1 ]]; then git checkout "$1"; return; fi
  local b
  if (( $+commands[fzf] )); then
    b=$(git branch --all --format='%(refname:short)' | sed 's#^origin/##' | sort -u | fzf --prompt='branch> ') || return
  else
    git branch; read -r "b?切换到分支: "
  fi
  [[ -n $b ]] && git checkout "$b"
}

# ─── sizes ───────────────────────────────────────────────────────────────────
sz() {                                      # sz  →  disks   |   sz <path> [depth]
  if [[ -z $1 ]]; then
    df -h | awk 'NR==1 || $1 ~ "^/dev/"'
  else
    du -h -d ${2:-0} -- "$1" 2>/dev/null | sort -h
  fi
}
szn() {                                     # number of files under a folder
  local d=${1:-.}
  print "$(find -- "$d" -type f 2>/dev/null | wc -l | tr -d ' ') files in $d"
}

# ─── processes and ports ─────────────────────────────────────────────────────
pid() {                                     # pid python   /   pid  (GPU processes)
  if [[ -n $1 ]]; then
    ps -eo pid,user,%cpu,%mem,etime,command | awk -v q="$1" 'NR==1 || (tolower($0) ~ tolower(q) && $0 !~ / awk -v q=/)' \
      | cut -c1-${COLUMNS:-160}
  elif (( $+commands[nvidia-smi] )); then
    nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv
  else
    print "用法: pid <进程名关键词>"
  fi
}

port() {                                    # port 8080
  [[ -n $1 ]] || { print "用法: port <端口号>"; return 1 }
  if (( $+commands[lsof] )); then
    lsof -nP -iTCP:$1 -sTCP:LISTEN 2>/dev/null || print "没有进程在监听 $1"
  else
    ss -ltnp 2>/dev/null | awk -v p=":$1" 'NR==1 || $4 ~ p"$"'
  fi
}

# ─── PATH and permissions ────────────────────────────────────────────────────
pathadd() {                                 # pathadd ~/bin   /   pathadd ~/bin -s  (save to ~/.zshrc)
  [[ -n $1 ]] || { print "用法: pathadd <目录> [-s]"; return 1 }
  local d=${1:A}
  [[ -d $d ]] || { print "目录不存在: $d"; return 1 }
  path=($d $path)
  if [[ $2 == -s || $2 == --save ]]; then
    print "export PATH=\"$d:\$PATH\"   # added by pathadd" >> ${ZDOTDIR:-$HOME}/.zshrc
    print "已加入 PATH 并写入 ~/.zshrc"
  else
    print "已加入当前会话的 PATH（加 -s 永久保存）"
  fi
}

_sk_recursive() {                           # _sk_recursive chmod|chown <dir> <value>
  local cmd=$1 dir=$2 val=$3
  [[ -n $dir && -n $val ]] || { print "用法: my$cmd <目录> <值>"; return 1 }
  [[ -e $dir ]] || { print "不存在: $dir"; return 1 }
  _sk_ask "$cmd -R $val ${dir:A} ？" || return 1
  if [[ -w $dir && $cmd == chmod ]]; then command $cmd -R $val -- $dir
  else sudo $cmd -R $val -- $dir; fi
}
mychmod() { _sk_recursive chmod "$1" "$2" }  # mychmod ./data 755
mychown() { _sk_recursive chown "$1" "$2" }  # mychown ./data me:staff

# ─── listing and small things ────────────────────────────────────────────────
if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first'
  alias ll='eza -la --git --group-directories-first'
  alias la='eza -a --group-directories-first'
  alias l='eza --group-directories-first'
  alias tree='eza --tree'
else
  if [[ $OSTYPE == darwin* ]]; then alias ls='ls -G'; else alias ls='ls --color=auto'; fi
  alias ll='ls -alFh'
  alias la='ls -A'
  alias l='ls -CF'
fi
alias cl='clear'
alias sc='source ${ZDOTDIR:-$HOME}/.zshrc'
