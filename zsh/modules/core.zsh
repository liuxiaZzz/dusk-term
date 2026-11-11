# modules/core.zsh — the `dusk` command (help, update, doctor). Always loaded.

_dk_pink()  { print -P "%F{#e48bb4}$*%f" }
_dk_blue()  { print -P "%F{#7aa2ff}$*%f" }
_dk_dim()   { print -P "%F{8}$*%f" }
_dk_ask()   { local r; read -r "r?$1 [y/N] "; [[ $r == [yY]* ]] }

_dusk_help() {
  _dk_pink "✻ Dusk"
  _dk_dim  "  ${DUSK_ROLE:-local} · modules: ${DUSK_MODULES[*]}"
  print
  if (( ${DUSK_MODULES[(Ie)theme]} )) && [[ ${DUSK_ROLE:-local} == local ]]; then
    _dk_blue "  theme"
    print "    ssh / tssh / mosh  远程时自动切换到 ${DUSK_REMOTE_PROFILE:-Dusk Dark}（iTerm2）"
    [[ -n ${DUSK_TMUX_HOSTS:-$DUSK_TMUX_HOST} ]] && print "    $DUSK_TMUX_CMD               选一个服务器上的 tmux 会话进入（$DUSK_TMUX_CMD 名字 直接进）"
    print "    dusk theme         换风格 / 本机远程配色（立即生效）"
    print "    dusk tmux          设置一键进服务器 tmux（服务器、会话、命令名、配色）"
  fi
  if (( ${DUSK_MODULES[(Ie)tools]} )); then
    _dk_blue "  tools"
    print "    rm / del <文件>     移到回收站（可恢复）   delf  真正删除   empty_trash  清空回收站"
    print "    gita gitaa gitb gitst gitl gitr gitpl gitps   git 缩写"
    print "    gitc [说明]        提交                   gitch [分支]  切换分支"
    print "    sz [路径] [深度]   磁盘/目录大小           szn [目录]    文件数量"
    print "    pid [名字]         查进程（无参数且有 NVIDIA 时显示 GPU 进程）"
    print "    port <端口>        谁在监听这个端口"
    print "    pathadd <目录> [-s]  加入 PATH（-s 写入 ~/.zshrc）"
    print "    mychmod / mychown <目录> <值>   递归改权限 / 所有者"
    print "    ll la l cl sc      列表 / 清屏 / 重新加载 zsh"
  fi
  if (( ${DUSK_MODULES[(Ie)remote]} )); then
    _dk_blue "  remote"
    print "    listen             SSH 端口转发（L 本地 / R 远程 / D socks5），可交互"
    print "    peek 服务器:/路径   像 QuPath 一样看大图和切片（服务器切图，本机浏览器看）"
    if [[ ${DUSK_ROLE:-local} == server ]]; then
      print "    upload [-d]        从本机上传文件（trz）   download [文件]  下载到本机（tsz）"
    else
      print "    tssh <主机>        带拖拽上传的 ssh（服务器端需要 trz，装 dusk 即有）"
    fi
    print "    dps  dsh <容器>  dlog <容器>  dockeradd [用户]      docker 辅助"
  fi
  if (( ${DUSK_MODULES[(Ie)shell]} )); then
    _dk_blue "  shell"
    print "    j <关键词>          跳到常去的目录（zoxide）    Ctrl-R / Ctrl-T  fzf 搜索历史 / 文件"
    print "    x <压缩包>          解压任意格式               Esc Esc  给上一条命令加 sudo"
  fi
  if (( $#DUSK_SKIPPED )); then
    print
    _dk_dim "  已被其他工具占用、保留原样：${DUSK_SKIPPED[*]}"
    _dk_dim "  想改用 dusk 的版本：在 ~/.zshrc 的 dusk 区块前加 DUSK_OVERRIDE=1"
  fi
  print
  _dk_dim "  dusk  命令面板（记这一个就够）    hud  控制中心    dusk theme / tmux / update / doctor"
}

# ─── config.zsh: one ": ${KEY:='value'}" line per setting ────────────────────
_dk_config_set() {   # _dk_config_set KEY VALUE   (empty VALUE removes the line)
  local f=$DUSK_DIR/config.zsh key=$1 val=$2
  touch $f
  local -a lines=("${(@f)$(<$f)}")
  lines=("${(@)lines:#: \$\{$key:=*}")
  [[ -n $val ]] && lines+=(": \${$key:='${val//\'/}'}")
  print -rl -- "${lines[@]}" > $f
  typeset -g $key="$val"
}

# ─── pink/blue menu, same look as the installer ────────────────────────────────
_dk_c() { print -n "\e[38;2;${1}m" }
_dk_choose() {   # _dk_choose <title> <default> "label|description" ...   → REPLY
  local title=$1 def=$2 i=1 o ans; shift 2
  print -n "\n  \e[48;2;74;98;173m\e[38;2;246;247;252m\e[1m ? \e[0m $(_dk_c '122;162;255')\e[1m$title\e[0m\n"
  for o in "$@"; do
    if (( i == def )); then print -n "     $(_dk_c '228;139;180')\e[1m$i\e[0m  \e[1m${(r:6:)${o%%|*}}\e[0m  $(_dk_c '127;132;163')${o#*|}\e[0m\n"
    else print -n "     $(_dk_c '122;162;255')$i\e[0m  ${(r:6:)${o%%|*}}  $(_dk_c '127;132;163')${o#*|}\e[0m\n"; fi
    (( i++ ))
  done
  while :; do
    read -r "ans?$(print -n "     $(_dk_c '228;139;180')❯\e[0m ")输入 1-$#，回车选 ${def}："
    [[ -z $ans ]] && ans=$def
    [[ $ans == <-> ]] && (( ans >= 1 && ans <= $# )) && break
  done
  REPLY=$ans
}

# ─── dusk theme ───────────────────────────────────────────────────────────────
#   dusk theme                    pick with menus
#   dusk theme glass split        or say it: classic|glass  split|dark|light (any order)
_dusk_theme() {
  local style=$DUSK_STYLE mode=$DUSK_MODE a
  if (( $# )); then
    for a in "$@"; do case $a in
      classic|glass) style=$a ;; split|dark|light) mode=$a ;;
      *) print "不认识：$a（风格 classic|glass，模式 split|dark|light）"; return 1 ;;
    esac; done
  else
    _dk_choose "选择风格" $([[ $style == glass ]] && echo 2 || echo 1) \
      "经典|Dusk Light + Dusk Dark，5% 透明" "玻璃|Dusk Glass Light + Glass Dark，毛玻璃"
    style=$([[ $REPLY == 2 ]] && echo glass || echo classic)
    _dk_choose "本机和远程" $(case $mode in dark) echo 2;; light) echo 3;; *) echo 1;; esac) \
      "分开|本机浅色，ssh 到服务器自动换深色" "全深色|到处都用深色" "全浅色|到处都用浅色"
    case $REPLY in 2) mode=dark ;; 3) mode=light ;; *) mode=split ;; esac
  fi
  _dk_config_set DUSK_STYLE $style
  _dk_config_set DUSK_MODE $mode
  _dusk_profiles
  print
  if [[ $mode == split ]]; then _dk_pink "  ✓ 本机 $DUSK_LOCAL_PROFILE · 远程 $DUSK_REMOTE_PROFILE"
  else _dk_pink "  ✓ 统一使用 $DUSK_LOCAL_PROFILE"; fi
  if _dusk_local_iterm; then
    _dusk_set_profile "$DUSK_LOCAL_PROFILE"
    _dk_dim "  当前标签页已切换。新标签页：iTerm2 → Settings → Profiles → $DUSK_LOCAL_PROFILE → Other Actions… → Set as Default"
  fi
}

# ─── dusk tmux ────────────────────────────────────────────────────────────────
#   dusk tmux                         set it up with questions
#   dusk tmux host1 host2 [--cmd jt]  or directly (the first host is the default)
#   dusk tmux off                     remove it
_dusk_tmux_setup() {
  local hosts="${DUSK_TMUX_HOSTS:-$DUSK_TMUX_HOST}" sess=$DUSK_TMUX_SESSION cmd=$DUSK_TMUX_CMD prof=$DUSK_TMUX_PROFILE
  if [[ $1 == off ]]; then
    [[ -n $DUSK_TMUX_CMD ]] && (( $+functions[$DUSK_TMUX_CMD] )) && unfunction $DUSK_TMUX_CMD
    _dk_config_set DUSK_TMUX_HOST ""; _dk_config_set DUSK_TMUX_HOSTS ""; _dk_dim "  已关闭"; return
  fi
  if (( $# )); then
    local -a hs=()
    while (( $# )); do
      case $1 in --cmd) cmd=$2; shift 2 ;; *) hs+=($1); shift ;; esac
    done
    (( $#hs )) && hosts="${hs[*]}"
  else
    print
    _dk_dim "  服务器填 user@host 或 ~/.ssh/config 里的名字；可以填多个，用空格隔开，第一个是默认"
    local ans
    read -r "ans?  服务器 [${hosts:-无}]: "; hosts=${ans:-$hosts}
    [[ -n $hosts ]] || { _dk_dim "  没有填写服务器，已取消"; return 1 }
    read -r "ans?  默认会话名 [${sess}]: "; sess=${ans:-$sess}
    read -r "ans?  命令叫什么 [${cmd}]: ";   cmd=${ans:-$cmd}
    _dk_choose "tmux 窗口用哪个配色" 1 \
      "跟随远程|现在是 $DUSK_REMOTE_PROFILE，换主题会跟着变" "Dark|Dusk Dark" "GlassDk|Dusk Glass Dark" "Light|Dusk Light" "GlassLt|Dusk Glass Light"
    case $REPLY in 2) prof="Dusk Dark";; 3) prof="Dusk Glass Dark";; 4) prof="Dusk Light";; 5) prof="Dusk Glass Light";; *) prof="";; esac
  fi
  [[ $cmd =~ '^[A-Za-z_][A-Za-z0-9_-]*$' ]] || { print "命令名只能用字母、数字、- 和 _"; return 1 }
  [[ -n $DUSK_TMUX_CMD && $DUSK_TMUX_CMD != $cmd ]] && (( $+functions[$DUSK_TMUX_CMD] )) && unfunction $DUSK_TMUX_CMD
  local -a hl=(${=hosts})
  _dk_config_set DUSK_TMUX_HOST "$hl[1]"
  _dk_config_set DUSK_TMUX_HOSTS "${hl[*]}"
  _dk_config_set DUSK_TMUX_SESSION "$sess"
  _dk_config_set DUSK_TMUX_CMD "$cmd"
  _dk_config_set DUSK_TMUX_PROFILE "$prof"
  _dusk_bind_tmux
  print; _dk_pink "  ✓ $cmd → ${hl[*]} 上的 tmux（默认 $hl[1]，会话 $sess，配色 ${prof:-跟随远程}）"
  _dk_dim "  $cmd          列出所有服务器上的会话，选一个进入或新建"
  _dk_dim "  $cmd 名字     进默认服务器上的这个会话      $cmd 服务器 名字   进指定服务器"
}

_dusk_update() {
  [[ -n $DUSK_REPO && -d $DUSK_REPO/.git ]] || { print "找不到仓库目录（DUSK_REPO=$DUSK_REPO），请重新 clone 后运行 install.sh"; return 1 }
  git -C "$DUSK_REPO" pull --ff-only || return
  "$DUSK_REPO/install.sh" -y && _dk_pink "已更新，新开一个标签页生效（或运行 sc）"
}

_dusk_doctor() {
  local c ok='%F{#a3cbe6}✓%f' no='%F{#d9647f}✗%f'
  print -P "  $( [[ -n $ZSH_VERSION ]] && echo $ok || echo $no ) zsh $ZSH_VERSION"
  print -P "  $( [[ -d ${ZSH:-$HOME/.oh-my-zsh} ]] && echo $ok || echo $no ) oh-my-zsh"
  print -P "  $( (( $+functions[p10k] )) && echo $ok || echo $no ) powerlevel10k"
  for c in git fzf zoxide tssh trz tsz eza; do
    print -P "  $( (( $+commands[$c] )) && echo $ok || echo $no ) $c"
  done
  if [[ $OSTYPE == darwin* ]]; then
    print -P "  $( ls ~/Library/Fonts /Library/Fonts 2>/dev/null | grep -qi nerdfont && echo $ok || echo $no ) Nerd Font（图标需要）"
  fi
  (( $#DUSK_SKIPPED )) && print -P "  %F{8}·%f 让给其他工具的命令：${DUSK_SKIPPED[*]}"
}

# ─── dusk: one entry point — a command palette ───────────────────────────────
# Each entry: "icon|name|what it does|command|question to ask for an argument (optional)"
_dusk_entries() {
  reply=()
  reply+=("󰕮|控制中心|时钟、CPU、内存、磁盘、电池一览|hud|")
  (( $+functions[_dk_peek] )) && reply+=("󰋩|看大图|像 QuPath 一样缩放浏览服务器上的切片和大图|peek|路径（服务器:/路径 或 本机路径）")
  if [[ -n ${DUSK_TMUX_HOSTS:-$DUSK_TMUX_HOST} ]] && (( $+functions[$DUSK_TMUX_CMD] )); then
    reply+=("|进服务器 tmux|列出 ${${DUSK_TMUX_HOSTS:-$DUSK_TMUX_HOST}// /、} 上的会话，选一个进入|$DUSK_TMUX_CMD|")
  fi
  (( $+functions[j] || $+aliases[j] )) && reply+=("|跳转目录|跳到常去的目录|j|目录关键词")
  (( $+functions[_dk_listen] )) && reply+=("󰛳|端口转发|SSH 转发远程端口到本机|listen|")
  (( $+functions[_dk_upload] )) && [[ ${DUSK_ROLE:-local} == server ]] && {
    reply+=("󰕒|上传文件|从本机选文件传到这里|upload|")
    reply+=("󰇚|下载文件|把这里的文件传回本机|download|文件名（回车 = 列表里选）")
  }
  (( $+functions[_dk_sz] ))   && reply+=("󰋊|磁盘和目录大小|看磁盘，或某个目录有多大|sz|目录（回车 = 看磁盘）")
  (( $+functions[_dk_pid] ))  && reply+=("|查进程|按名字找进程（无 = GPU 进程）|pid|进程名关键词")
  (( $+functions[_dk_port] )) && reply+=("󰈀|谁占用端口|查看某个端口被谁监听|port|端口号")
  reply+=("󰏘|换主题|风格、本机和远程的配色|dusk theme|")
  reply+=("|设置一键进 tmux|服务器、会话、命令名、配色|dusk tmux|")
  reply+=("|全部快捷命令|速查表|dusk help|")
  reply+=("󰓦|检查依赖|看看缺什么|dusk doctor|")
  reply+=("󰚰|更新 Dusk|拉取最新版并重新安装|dusk update|")
}

_dusk_menu() {
  _dusk_entries; local -a entries=("${reply[@]}")
  local e pick idx=0 i=1
  if (( $+commands[fzf] )) && [[ -t 0 && -t 1 ]]; then
    local -a rows=()
    for e in $entries; do
      local -a f=("${(@s:|:)e}")
      rows+=("$(printf '%2d  \e[38;2;228;139;180m%s\e[0m  %s  \e[38;2;127;132;163m%s\e[0m' $i "$f[1]" "${(mr:16:)f[2]}" "$f[3]")")
      (( i++ ))
    done
    pick=$(print -rl -- $rows | fzf --ansi --height=60% --layout=reverse --border=rounded \
      --prompt='dusk › ' --info=hidden --header='输入几个字筛选，回车执行，Esc 取消' \
      --color='border:#e48bb4,prompt:#7aa2ff,pointer:#e48bb4,hl:#e48bb4,hl+:#e48bb4,header:8' ) || return 0
    idx=${${=pick}[1]}
  else
    local -a opts=()
    for e in $entries; do local -a f=("${(@s:|:)e}"); opts+=("$f[1] $f[2]|$f[3]"); done
    _dk_choose_wide "dusk" 1 $opts || return 0
    idx=$REPLY
  fi
  [[ $idx == <-> ]] && (( idx >= 1 && idx <= $#entries )) || return 0
  local -a f=("${(@s:|:)entries[idx]}")
  local cmd=$f[4] ask=$f[5] arg=""
  if [[ -n $ask ]]; then
    read -r "arg?$(print -n "  \e[38;2;228;139;180m❯\e[0m $ask：")"
  fi
  # run Dusk's own implementation even if the short name belongs to another tool (e.g. GCR)
  local run=${cmd%% *}
  local rest=${cmd#$run}
  (( $+functions[_dk_$run] )) && [[ ${aliases[$run]} != _dk_$run ]] && run=_dk_$run
  print
  eval "$run$rest ${arg:+${(q)arg}}"
  local rc=$?
  [[ $run == $cmd[(w)1] ]] && _dk_dim "\n  下次可以直接输入：$cmd${arg:+ $arg}"
  return $rc
}

# numbered menu that fits longer labels (used when fzf isn't installed)
_dk_choose_wide() {
  local title=$1 def=$2 i=1 o ans; shift 2
  print -n "\n  \e[48;2;74;98;173m\e[38;2;246;247;252m\e[1m ? \e[0m $(_dk_c '122;162;255')\e[1m$title\e[0m\n"
  for o in "$@"; do
    print -n "    $(_dk_c '122;162;255')${(l:2:)i}\e[0m  ${(mr:20:)${o%%|*}}  $(_dk_c '127;132;163')${o#*|}\e[0m\n"
    (( i++ ))
  done
  read -r "ans?$(print -n "     $(_dk_c '228;139;180')❯\e[0m ")输入编号（回车取消）："
  [[ $ans == <-> ]] && (( ans >= 1 && ans <= $# )) || return 1
  REPLY=$ans
}

dusk() {
  case $1 in
    update) _dusk_update ;;
    theme)  shift; _dusk_theme "$@" ;;
    tmux)   shift; _dusk_tmux_setup "$@" ;;
    doctor) _dusk_doctor ;;
    "") _dusk_menu ;;
    help|-h|--help) _dusk_help ;;
    *) print "未知命令：$1"; _dusk_help; return 1 ;;
  esac
}
