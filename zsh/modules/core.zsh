# modules/core.zsh — the `sakura` command (help, update, doctor). Always loaded.

_sk_pink()  { print -P "%F{#e48bb4}$*%f" }
_sk_blue()  { print -P "%F{#7aa2ff}$*%f" }
_sk_dim()   { print -P "%F{8}$*%f" }
_sk_ask()   { local r; read -r "r?$1 [y/N] "; [[ $r == [yY]* ]] }

_sakura_help() {
  _sk_pink "✻ Sakura Term"
  _sk_dim  "  modules: ${SAKURA_MODULES[*]}"
  print
  if (( ${SAKURA_MODULES[(Ie)theme]} )); then
    _sk_blue "  theme"
    print "    ssh / tssh / mosh  远程时自动切换到 ${SAKURA_REMOTE_PROFILE:-Sakura Glass}（iTerm2）"
    [[ -n $SAKURA_TMUX_HOST ]] && print "    st [会话名]        连接 $SAKURA_TMUX_HOST 上的 tmux（iTerm2 -CC）"
  fi
  if (( ${SAKURA_MODULES[(Ie)tools]} )); then
    _sk_blue "  tools"
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
  if (( ${SAKURA_MODULES[(Ie)remote]} )); then
    _sk_blue "  remote"
    print "    listen             SSH 端口转发（L 本地 / R 远程 / D socks5），可交互"
    print "    upload [-d]        上传文件（trz，在服务器上运行）   download [文件]  下载（tsz）"
    print "    dps  dsh <容器>  dlog <容器>  dockeradd [用户]      docker 辅助"
  fi
  if (( ${SAKURA_MODULES[(Ie)shell]} )); then
    _sk_blue "  shell"
    print "    j <关键词>          跳到常去的目录（zoxide）    Ctrl-R / Ctrl-T  fzf 搜索历史 / 文件"
    print "    x <压缩包>          解压任意格式               Esc Esc  给上一条命令加 sudo"
  fi
  print
  _sk_dim "  sakura update   更新    sakura doctor   检查依赖    sakura help   本帮助"
}

_sakura_update() {
  [[ -n $SAKURA_REPO && -d $SAKURA_REPO/.git ]] || { print "找不到仓库目录（SAKURA_REPO=$SAKURA_REPO），请重新 clone 后运行 install.sh"; return 1 }
  git -C "$SAKURA_REPO" pull --ff-only || return
  "$SAKURA_REPO/install.sh" ${(z)SAKURA_INSTALL_ARGS} && _sk_pink "已更新，新开一个标签页生效（或运行 sc）"
}

_sakura_doctor() {
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
}

sakura() {
  case $1 in
    update) _sakura_update ;;
    doctor) _sakura_doctor ;;
    ""|help|-h|--help) _sakura_help ;;
    *) print "未知命令：$1"; _sakura_help; return 1 ;;
  esac
}
