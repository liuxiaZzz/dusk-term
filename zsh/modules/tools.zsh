# modules/tools.zsh — everyday shortcuts (macOS + Linux)
# Ideas adapted from GCR (https://github.com/gaojunbin/GCR, Apache-2.0); rewritten to be
# non-interactive-friendly and portable. See NOTICE.

: ${DUSK_SAFE_RM:=1}   # 1 = `rm` moves files to the trash instead of deleting

# ─── trash instead of rm ─────────────────────────────────────────────────────
_dk_trash_dir() {
  if [[ $OSTYPE == darwin* ]]; then print -r -- $HOME/.Trash
  else print -r -- ${XDG_DATA_HOME:-$HOME/.local/share}/Trash; fi
}

# del <file>...   flags like -r -f -i are accepted and ignored (everything goes to the trash)
_dk_del() {
  local -a files; local a seen_dd=0
  for a in "$@"; do
    if (( seen_dd )) || [[ $a != -* ]]; then files+=("$a")
    elif [[ $a == -- ]]; then seen_dd=1; fi
  done
  (( $#files )) || { print "${${DUSK_ZH:+用法: del <文件或目录>...   （移到回收站，可恢复）}:-usage: del <file or folder>...   (moves to the trash, recoverable)}"; return 1 }

  local f missing=0; local -a existing
  for f in "${files[@]}"; do         # plain test, no globbing: a file named '*' stays just that file
    if [[ -e $f || -L $f ]]; then existing+=("$f"); else print -u2 "del: ${${DUSK_ZH:+不存在}:-not found}: $f"; missing=1; fi
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
    local dir=$(_dk_trash_dir) name dest stamp=$(date +%Y%m%d-%H%M%S)
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

_dk_empty_trash() {
  local dir=$(_dk_trash_dir)
  _dk_ask "${${DUSK_ZH:+永久清空回收站}:-Permanently empty the trash} $dir ?" || return 1
  if [[ $OSTYPE == darwin* ]]; then
    osascript -e 'tell application "Finder" to empty trash' 2>/dev/null || command rm -rf -- $dir/*(DN)
  elif (( $+commands[gio] )) && gio trash --empty 2>/dev/null; then
    :
  else
    command rm -rf -- $dir/files/*(DN) $dir/info/*(DN)
  fi
}

_dk_bind del _dk_del
_dk_bind empty_trash _dk_empty_trash
if (( DUSK_SAFE_RM )); then
  _dk_bind rm _dk_del
  _dk_bind delf 'command rm -rf'
fi

# ─── git shortcuts ───────────────────────────────────────────────────────────
_dk_bind gita  'git add'
_dk_bind gitaa 'git add .'
_dk_bind gitb  'git branch'
_dk_bind gitst 'git status -sb'
_dk_bind gitl  'git log --oneline --graph --decorate -20'
_dk_bind gitr  'git reset'
_dk_bind gitpl 'git pull'
_dk_bind gitps 'git push origin HEAD'       # push the current branch

_dk_gitc() {                                    # gitc fix typo   /   gitc  (asks)
  local msg="$*"
  [[ -n $msg ]] || read -r "msg?${${DUSK_ZH:+提交说明}:-Commit message}: "
  [[ -n $msg ]] && git commit -m "$msg"
}

_dk_gitch() {                                   # gitch dev   /   gitch  (pick a branch)
  if [[ -n $1 ]]; then git checkout "$1"; return; fi
  local b
  if (( $+commands[fzf] )); then
    b=$(git branch --all --format='%(refname:short)' | sed 's#^origin/##' | sort -u | fzf --prompt='branch> ') || return
  else
    git branch; read -r "b?${${DUSK_ZH:+切换到分支}:-Switch to branch}: "
  fi
  [[ -n $b ]] && git checkout "$b"
}

# ─── sizes ───────────────────────────────────────────────────────────────────
_dk_sz() {                                      # sz  →  disks   |   sz <path> [depth]
  if [[ -z $1 ]]; then
    df -h | awk 'NR==1 || $1 ~ "^/dev/"'
  else
    du -h -d ${2:-0} -- "$1" 2>/dev/null | sort -h
  fi
}
_dk_szn() {                                     # number of files under a folder
  local d=${1:-.}
  print "$(find -- "$d" -type f 2>/dev/null | wc -l | tr -d ' ') files in $d"
}

# ─── processes and ports ─────────────────────────────────────────────────────
_dk_pid() {                                     # pid python   /   pid  (GPU processes)
  if [[ -n $1 ]]; then
    ps -eo pid,user,%cpu,%mem,etime,command | awk -v q="$1" 'NR==1 || (tolower($0) ~ tolower(q) && $0 !~ / awk -v q=/)' \
      | cut -c1-${COLUMNS:-160}
  elif (( $+commands[nvidia-smi] )); then
    nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv
  else
    print "${${DUSK_ZH:+用法: pid <进程名关键词>}:-usage: pid <process name>}"
  fi
}

_dk_port() {                                    # port 8080
  [[ -n $1 ]] || { print "${${DUSK_ZH:+用法: port <端口号>}:-usage: port <port number>}"; return 1 }
  if (( $+commands[lsof] )); then
    lsof -nP -iTCP:$1 -sTCP:LISTEN 2>/dev/null || print "${${DUSK_ZH:+没有进程在监听}:-nothing is listening on} $1"
  else
    ss -ltnp 2>/dev/null | awk -v p=":$1" 'NR==1 || $4 ~ p"$"'
  fi
}

# ─── PATH and permissions ────────────────────────────────────────────────────
_dk_pathadd() {                                 # pathadd ~/bin   /   pathadd ~/bin -s  (save to ~/.zshrc)
  [[ -n $1 ]] || { print "${${DUSK_ZH:+用法: pathadd <目录> [-s]}:-usage: pathadd <folder> [-s]}"; return 1 }
  local d=${1:A}
  [[ -d $d ]] || { print "${${DUSK_ZH:+目录不存在}:-no such folder}: $d"; return 1 }
  path=($d $path)
  if [[ $2 == -s || $2 == --save ]]; then
    print "export PATH=\"$d:\$PATH\"   # added by pathadd" >> ${ZDOTDIR:-$HOME}/.zshrc
    print "${${DUSK_ZH:+已加入 PATH 并写入 ~/.zshrc}:-added to PATH and saved in ~/.zshrc}"
  else
    print "${${DUSK_ZH:+已加入当前会话的 PATH（加 -s 永久保存）}:-added to PATH for this session (-s to keep it)}"
  fi
}

_dk_recursive() {                           # _dk_recursive chmod|chown <dir> <value>
  local cmd=$1 dir=$2 val=$3
  [[ -n $dir && -n $val ]] || { print "${${DUSK_ZH:+用法}:-usage}: my$cmd <dir> <value>"; return 1 }
  [[ -e $dir ]] || { print "${${DUSK_ZH:+不存在}:-not found}: $dir"; return 1 }
  _dk_ask "$cmd -R $val ${dir:A} ？" || return 1
  if [[ -w $dir && $cmd == chmod ]]; then command $cmd -R $val -- $dir
  else sudo $cmd -R $val -- $dir; fi
}
_dk_mychmod() { _dk_recursive chmod "$1" "$2" }  # mychmod ./data 755
_dk_mychown() { _dk_recursive chown "$1" "$2" }  # mychown ./data me:staff

for _dk_n in gitc gitch sz szn pid port pathadd mychmod mychown; do _dk_bind $_dk_n _dk_$_dk_n; done
unset _dk_n

# ─── listing and small things ────────────────────────────────────────────────
# cosmetic: with eza installed take over the ls family; otherwise only fill in missing ones, quietly
if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first'
  alias ll='eza -la --git --group-directories-first'
  alias la='eza -a --group-directories-first'
  alias l='eza --group-directories-first'
  alias tree='eza --tree'
else
  _dk_bind ll 'ls -alFh' quiet; _dk_bind la 'ls -A' quiet; _dk_bind l 'ls -CF' quiet
fi
_dk_bind cl 'clear'
_dk_bind sc 'source ${ZDOTDIR:-$HOME}/.zshrc'
