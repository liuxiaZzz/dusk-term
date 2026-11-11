# modules/core.zsh — the `dusk` command (help, update, doctor). Always loaded.

_dk_pink()  { print -P "%F{#e48bb4}$*%f" }
_dk_blue()  { print -P "%F{#7aa2ff}$*%f" }
_dk_dim()   { print -P "%F{8}$*%f" }
_dk_ask()   { local r; read -r "r?$1 [y/N] "; [[ $r == [yY]* ]] }

_dusk_help() {
  _dk_pink "✻ Dusk"
  _dk_dim  "  ${DUSK_ROLE:-local} · modules: ${DUSK_MODULES[*]}"
  print
  local tm=$DUSK_TMUX_CMD hosts=${DUSK_TMUX_HOSTS:-$DUSK_TMUX_HOST}
  if [[ -n $DUSK_ZH ]]; then
    if (( ${DUSK_MODULES[(Ie)theme]} )) && [[ ${DUSK_ROLE:-local} == local ]]; then
      _dk_blue "  theme"
      print "    ssh / tssh / mosh  远程时自动切换到 ${DUSK_REMOTE_PROFILE:-Dusk Dark}（iTerm2）"
      [[ -n $hosts ]] && print "    $tm                 选一个服务器上的 tmux 会话进入（$tm 名字 直接进）"
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
  else
    if (( ${DUSK_MODULES[(Ie)theme]} )) && [[ ${DUSK_ROLE:-local} == local ]]; then
      _dk_blue "  theme"
      print "    ssh / tssh / mosh  switch to ${DUSK_REMOTE_PROFILE:-Dusk Dark} while on a remote host (iTerm2)"
      [[ -n $hosts ]] && print "    $tm                 pick a tmux session on your servers ($tm name: straight in)"
      print "    dusk theme         change style / local and remote look (applies right away)"
      print "    dusk tmux          set up one-command tmux (servers, session, command name, colors)"
    fi
    if (( ${DUSK_MODULES[(Ie)tools]} )); then
      _dk_blue "  tools"
      print "    rm / del <file>    move to the trash (recoverable)   delf  really delete   empty_trash"
      print "    gita gitaa gitb gitst gitl gitr gitpl gitps   git shortcuts"
      print "    gitc [message]     commit                  gitch [branch]  switch branch"
      print "    sz [path] [depth]  disk / folder sizes     szn [folder]    count files"
      print "    pid [name]         find processes (no name + NVIDIA: GPU processes)"
      print "    port <port>        who is listening on a port"
      print "    pathadd <dir> [-s] add to PATH (-s: save to ~/.zshrc)"
      print "    mychmod / mychown <dir> <value>   recursive chmod / chown"
      print "    ll la l cl sc      listings / clear / reload zsh"
    fi
    if (( ${DUSK_MODULES[(Ie)remote]} )); then
      _dk_blue "  remote"
      print "    listen             SSH port forwarding (L local / R remote / D socks5), interactive"
      print "    peek host:/path    zoom into huge images like QuPath (tiles cut on the server)"
      if [[ ${DUSK_ROLE:-local} == server ]]; then
        print "    upload [-d]        upload from your computer (trz)   download [file]  download (tsz)"
      else
        print "    tssh <host>        ssh with drag-and-drop upload (server needs trz; Dusk installs it)"
      fi
      print "    dps  dsh <ctr>  dlog <ctr>  dockeradd [user]      docker helpers"
    fi
    if (( ${DUSK_MODULES[(Ie)shell]} )); then
      _dk_blue "  shell"
      print "    j <keyword>        jump to a frequent folder (zoxide)   Ctrl-R / Ctrl-T  fzf history / files"
      print "    x <archive>        extract any archive                  Esc Esc  prefix last command with sudo"
    fi
    if (( $#DUSK_SKIPPED )); then
      print
      _dk_dim "  Kept as defined by another tool: ${DUSK_SKIPPED[*]}"
      _dk_dim "  To use Dusk's versions: put DUSK_OVERRIDE=1 before the dusk block in ~/.zshrc"
    fi
    print
    _dk_dim "  dusk  command palette (the one thing to remember)    hud  Control Center    dusk theme / tmux / update / doctor"
  fi
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
    local q; if [[ -n $DUSK_ZH ]]; then q="输入 1-$#，回车选 $def："; else q="Pick 1-$# (Enter = $def): "; fi
    read -r "ans?$(print -n "     $(_dk_c '228;139;180')❯\e[0m ")$q"
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
      *) print "${${DUSK_ZH:+不认识：}:-unknown: }$a ${${DUSK_ZH:+（风格 classic|glass，模式 split|dark|light）}:-(style: classic|glass, mode: split|dark|light)}"; return 1 ;;
    esac; done
  else
    _dk_choose "${${DUSK_ZH:+选择风格}:-Pick a style}" $([[ $style == glass ]] && echo 2 || echo 1) \
      "${${DUSK_ZH:+经典|Dusk Light + Dusk Dark，5% 透明}:-Classic|Dusk Light + Dusk Dark, 5% see-through}" "${${DUSK_ZH:+玻璃|Dusk Glass Light + Glass Dark，毛玻璃}:-Glass|Dusk Glass Light + Glass Dark, frosted glass}"
    style=$([[ $REPLY == 2 ]] && echo glass || echo classic)
    _dk_choose "${${DUSK_ZH:+本机和远程}:-Local and remote}" $(case $mode in dark) echo 2;; light) echo 3;; *) echo 1;; esac) \
      "${${DUSK_ZH:+分开|本机浅色，ssh 到服务器自动换深色}:-Split|light here, dark automatically on ssh}" "${${DUSK_ZH:+全深色|到处都用深色}:-Dark|dark everywhere}" "${${DUSK_ZH:+全浅色|到处都用浅色}:-Light|light everywhere}"
    case $REPLY in 2) mode=dark ;; 3) mode=light ;; *) mode=split ;; esac
  fi
  _dk_config_set DUSK_STYLE $style
  _dk_config_set DUSK_MODE $mode
  _dusk_profiles
  print
  if [[ $mode == split ]]; then _dk_pink "  ✓ ${${DUSK_ZH:+本机}:-local} $DUSK_LOCAL_PROFILE · ${${DUSK_ZH:+远程}:-remote} $DUSK_REMOTE_PROFILE"
  else _dk_pink "  ✓ ${${DUSK_ZH:+统一使用}:-everywhere:} $DUSK_LOCAL_PROFILE"; fi
  if _dusk_local_iterm; then
    _dusk_set_profile "$DUSK_LOCAL_PROFILE"
    _dk_dim "  ${${DUSK_ZH:+当前标签页已切换。新标签页：}:-This tab switched. For new tabs: }iTerm2 → Settings → Profiles → $DUSK_LOCAL_PROFILE → Other Actions… → Set as Default"
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
    _dk_config_set DUSK_TMUX_HOST ""; _dk_config_set DUSK_TMUX_HOSTS ""; _dk_dim "  ${${DUSK_ZH:+已关闭}:-turned off}"; return
  fi
  if (( $# )); then
    local -a hs=()
    while (( $# )); do
      case $1 in --cmd) cmd=$2; shift 2 ;; *) hs+=($1); shift ;; esac
    done
    (( $#hs )) && hosts="${hs[*]}"
  else
    print
    _dk_dim "  ${${DUSK_ZH:+服务器填 user@host 或 ~/.ssh/config 里的名字；可以填多个，用空格隔开，第一个是默认}:-Servers: user@host or names from ~/.ssh/config; several are fine, space separated, the first is the default}"
    local ans
    local none=${${DUSK_ZH:+无}:-none}
    read -r "ans?  ${${DUSK_ZH:+服务器}:-Servers} [${hosts:-$none}]: "; hosts=${ans:-$hosts}
    [[ -n $hosts ]] || { _dk_dim "  ${${DUSK_ZH:+没有填写服务器，已取消}:-no server given, cancelled}"; return 1 }
    read -r "ans?  ${${DUSK_ZH:+默认会话名}:-Default session} [$sess]: "; sess=${ans:-$sess}
    read -r "ans?  ${${DUSK_ZH:+命令叫什么}:-Command name} [$cmd]: ";   cmd=${ans:-$cmd}
    _dk_choose "${${DUSK_ZH:+tmux 窗口用哪个配色}:-Colors for the tmux windows}" 1 \
      "${${DUSK_ZH:+跟随远程|现在是 $DUSK_REMOTE_PROFILE，换主题会跟着变}:-Remote|now $DUSK_REMOTE_PROFILE, follows theme changes}" "Dark|Dusk Dark" "GlassDk|Dusk Glass Dark" "Light|Dusk Light" "GlassLt|Dusk Glass Light"
    case $REPLY in 2) prof="Dusk Dark";; 3) prof="Dusk Glass Dark";; 4) prof="Dusk Light";; 5) prof="Dusk Glass Light";; *) prof="";; esac
  fi
  [[ $cmd =~ '^[A-Za-z_][A-Za-z0-9_-]*$' ]] || { print "${${DUSK_ZH:+命令名只能用字母、数字、- 和 _}:-command names may only use letters, digits, - and _}"; return 1 }
  [[ -n $DUSK_TMUX_CMD && $DUSK_TMUX_CMD != $cmd ]] && (( $+functions[$DUSK_TMUX_CMD] )) && unfunction $DUSK_TMUX_CMD
  local -a hl=(${=hosts})
  _dk_config_set DUSK_TMUX_HOST "$hl[1]"
  _dk_config_set DUSK_TMUX_HOSTS "${hl[*]}"
  _dk_config_set DUSK_TMUX_SESSION "$sess"
  _dk_config_set DUSK_TMUX_CMD "$cmd"
  _dk_config_set DUSK_TMUX_PROFILE "$prof"
  _dusk_bind_tmux
  print
  if [[ -n $DUSK_ZH ]]; then
    _dk_pink "  ✓ $cmd → ${hl[*]} 上的 tmux（默认 $hl[1]，会话 $sess，配色 ${prof:-跟随远程}）"
    _dk_dim "  $cmd          列出所有服务器上的会话，选一个进入或新建"
    _dk_dim "  $cmd 名字     进默认服务器上的这个会话      $cmd 服务器 名字   进指定服务器"
  else
    _dk_pink "  ✓ $cmd → tmux on ${hl[*]} (default $hl[1], session $sess, colors ${prof:-follow remote})"
    _dk_dim "  $cmd          list the sessions on all servers, pick one or start a new one"
    _dk_dim "  $cmd name     that session on the default server      $cmd host name   on a given server"
  fi
}

_dusk_update() {
  [[ -n $DUSK_REPO && -d $DUSK_REPO/.git ]] || { print "${${DUSK_ZH:+找不到仓库目录}:-repository not found} (DUSK_REPO=$DUSK_REPO)${${DUSK_ZH:+，请重新 clone 后运行 install.sh}:- — clone it again and run install.sh}"; return 1 }
  git -C "$DUSK_REPO" pull --ff-only || return
  "$DUSK_REPO/install.sh" -y && _dk_pink "${${DUSK_ZH:+已更新，新开一个标签页生效（或运行 sc）}:-Updated — open a new tab (or run sc)}"
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
    print -P "  $( ls ~/Library/Fonts /Library/Fonts 2>/dev/null | grep -qi nerdfont && echo $ok || echo $no ) Nerd Font${${DUSK_ZH:+（图标需要）}:- (for icons)}"
  fi
  (( $#DUSK_SKIPPED )) && print -P "  %F{8}·%f ${${DUSK_ZH:+让给其他工具的命令：}:-kept for other tools: }${DUSK_SKIPPED[*]}"
}

# ─── dusk: one entry point — a command palette ───────────────────────────────
# Each entry: "icon|name|what it does|command|question to ask for an argument (optional)"
_dusk_entries() {
  reply=()
  local Z=$DUSK_ZH h=${${DUSK_TMUX_HOSTS:-$DUSK_TMUX_HOST}// /, }
  reply+=("󰕮|${${Z:+控制中心}:-Control Center}|${${Z:+时钟、CPU、内存、磁盘、电池一览}:-clock, CPU, memory, disk and battery at a glance}|hud|")
  (( $+functions[_dk_peek] )) && reply+=("󰋩|${${Z:+看大图}:-View big images}|${${Z:+像 QuPath 一样缩放浏览服务器上的切片和大图}:-zoom into slides and huge images like QuPath}|peek|${${Z:+路径（服务器:/路径 或 本机路径）}:-path (server:/path or a local path)}")
  if [[ -n $h ]] && (( $+functions[$DUSK_TMUX_CMD] )); then
    reply+=("|${${Z:+进服务器 tmux}:-Server tmux}|${${Z:+列出这些服务器上的会话，选一个进入：}:-pick a session on: }$h|$DUSK_TMUX_CMD|")
  fi
  (( $+functions[j] || $+aliases[j] )) && reply+=("|${${Z:+跳转目录}:-Jump to folder}|${${Z:+跳到常去的目录}:-a folder you visit often}|j|${${Z:+目录关键词}:-folder keyword}")
  (( $+functions[_dk_listen] )) && reply+=("󰛳|${${Z:+端口转发}:-Port forwarding}|${${Z:+SSH 转发远程端口到本机}:-forward a remote port over SSH}|listen|")
  (( $+functions[_dk_upload] )) && [[ ${DUSK_ROLE:-local} == server ]] && {
    reply+=("󰕒|${${Z:+上传文件}:-Upload}|${${Z:+从本机选文件传到这里}:-send files from your computer here}|upload|")
    reply+=("󰇚|${${Z:+下载文件}:-Download}|${${Z:+把这里的文件传回本机}:-send files from here to your computer}|download|${${Z:+文件名（回车 = 列表里选）}:-file (Enter = pick from a list)}")
  }
  (( $+functions[_dk_sz] ))   && reply+=("󰋊|${${Z:+磁盘和目录大小}:-Disk and folder sizes}|${${Z:+看磁盘，或某个目录有多大}:-disks, or how big a folder is}|sz|${${Z:+目录（回车 = 看磁盘）}:-folder (Enter = disks)}")
  (( $+functions[_dk_pid] ))  && reply+=("|${${Z:+查进程}:-Find processes}|${${Z:+按名字找进程（无 = GPU 进程）}:-by name (none = GPU processes)}|pid|${${Z:+进程名关键词}:-process name}")
  (( $+functions[_dk_port] )) && reply+=("󰈀|${${Z:+谁占用端口}:-Who uses a port}|${${Z:+查看某个端口被谁监听}:-which process listens on a port}|port|${${Z:+端口号}:-port number}")
  reply+=("󰏘|${${Z:+换主题}:-Change theme}|${${Z:+风格、本机和远程的配色}:-style, local and remote colors}|dusk theme|")
  reply+=("|${${Z:+设置一键进 tmux}:-Set up tmux}|${${Z:+服务器、会话、命令名、配色}:-servers, session, command name, colors}|dusk tmux|")
  reply+=("|${${Z:+全部快捷命令}:-All shortcuts}|${${Z:+速查表}:-cheat sheet}|dusk help|")
  reply+=("󰓦|${${Z:+检查依赖}:-Check dependencies}|${${Z:+看看缺什么}:-see what is missing}|dusk doctor|")
  reply+=("󰚰|${${Z:+更新 Dusk}:-Update Dusk}|${${Z:+拉取最新版并重新安装}:-pull the latest version and reinstall}|dusk update|")
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
      --prompt='dusk › ' --info=hidden --header="${${DUSK_ZH:+输入几个字筛选，回车执行，Esc 取消}:-type to filter, Enter to run, Esc to cancel}" \
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
  [[ $run == $cmd[(w)1] ]] && _dk_dim "\n  ${${DUSK_ZH:+下次可以直接输入：}:-Next time just type: }$cmd${arg:+ $arg}"
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
  read -r "ans?$(print -n "     $(_dk_c '228;139;180')❯\e[0m ")${${DUSK_ZH:+输入编号（回车取消）：}:-Number (Enter to cancel): }"
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
    *) print "${${DUSK_ZH:+未知命令：}:-unknown command: }$1"; _dusk_help; return 1 ;;
  esac
}
