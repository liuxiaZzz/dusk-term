# modules/remote.zsh — SSH port forwarding, trzsz file transfer, docker helpers (macOS + Linux)
# Ideas adapted from GCR (https://github.com/gaojunbin/GCR, Apache-2.0); rewritten. See NOTICE.

# ─── listen: SSH port forwarding ─────────────────────────────────────────────
#   listen L <host> <remote_port> [local_port]   use a remote service at localhost:<local_port>
#   listen R <host> <local_port> [remote_port]   expose a local service on the remote host
#   listen D <host> <local_port>                 SOCKS5 proxy through <host>
#   listen                                       interactive
_dk_listen() {
  local mode=$1 host=$2 a=$3 b=$4
  if [[ -z $mode ]]; then
    print "  [L] 本地转发：在本机访问远程端口"
    print "  [R] 远程转发：让远程访问本机端口"
    print "  [D] 动态转发：通过远程做 socks5 代理"
    read -r "mode?模式 (L/R/D，默认 L): "; mode=${mode:-L}
    local hosts=$(awk 'tolower($1)=="host" {for (i=2;i<=NF;i++) if ($i !~ /[*?]/) printf "%s ", $i}' ~/.ssh/config 2>/dev/null)
    [[ -n $hosts ]] && _dk_dim "已知主机: $hosts"
    read -r "host?主机: "
    case ${mode:u} in
      L) read -r "a?远程端口: "; read -r "b?本地端口 (默认同远程): " ;;
      R) read -r "a?本地端口: "; read -r "b?远程端口 (默认同本地): " ;;
      D) read -r "a?本地 socks5 端口: " ;;
    esac
  fi
  [[ -n $host && -n $a ]] || { print "用法: listen L|R|D <主机> <端口> [端口]"; return 1 }
  b=${b:-$a}
  case ${mode:u} in
    L) _dk_blue "→ http://localhost:$b   (Ctrl-C 结束)"
       print "$ ssh -N -L localhost:$b:localhost:$a $host"
       command ssh -N -L localhost:$b:localhost:$a $host ;;
    R) print "$ ssh -N -R localhost:$b:localhost:$a $host"
       command ssh -N -R localhost:$b:localhost:$a $host ;;
    D) _dk_blue "→ socks5://localhost:$a   (Ctrl-C 结束)"
       print "$ ssh -N -D $a $host"
       command ssh -N -D $a $host ;;
    *) print "模式只能是 L / R / D"; return 1 ;;
  esac
}

_dk_bind listen _dk_listen

# ─── trzsz: drag-and-drop upload / download over ssh ────────────────────────
(( $+commands[tssh] )) && _dk_bind tssh 'tssh --dragfile'

_dk_upload() {                                  # run on the server: upload  /  upload -d (folder)
  (( $+commands[trz] )) || { print "需要 trzsz（install.sh 的 remote 模块会安装）"; return 1 }
  if [[ $1 == -d ]]; then trz -d; else trz "$@"; fi
}
_dk_download() {                                # run on the server: download file...  /  download (pick)
  (( $+commands[tsz] )) || { print "需要 trzsz（install.sh 的 remote 模块会安装）"; return 1 }
  if (( $# )); then tsz -d "$@"; return; fi
  local f
  if (( $+commands[fzf] )); then f=$(command ls -A | fzf --prompt='download> ') || return
  else select f in *(N); do break; done; fi
  [[ -n $f ]] && tsz -d "$f"
}

_dk_bind upload _dk_upload
_dk_bind download _dk_download

# ─── docker ──────────────────────────────────────────────────────────────────
if (( $+commands[docker] )); then
  _dk_bind dps 'docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
  _dk_dsh() {                                   # dsh web   /   dsh web zsh
    [[ -n $1 ]] || { print "用法: dsh <容器> [shell]"; return 1 }
    if [[ -n $2 ]]; then docker exec -it "$1" "$2"
    else docker exec -it "$1" sh -c 'command -v bash >/dev/null && exec bash || exec sh'; fi
  }
  _dk_dlog() { [[ -n $1 ]] || { print "用法: dlog <容器>"; return 1 }; docker logs -f --tail 200 "$1" }
  _dk_dockeradd() {                             # Linux: let a user run docker without sudo
    [[ $OSTYPE == linux* ]] || { print "只在 Linux 上需要（macOS 的 Docker Desktop 不用）"; return 0 }
    local u=${1:-$USER}
    sudo usermod -aG docker "$u" && print "已把 $u 加入 docker 组，重新登录后生效"
  }
  _dk_bind dsh _dk_dsh; _dk_bind dlog _dk_dlog; _dk_bind dockeradd _dk_dockeradd
fi

# ─── peek: zoom into huge images like QuPath; tiles are cut where the files are ──
#   peek host:/data/slides      browse a folder on a server in your local browser
#   peek host:/data/a.svs       open one image (whole-slide .svs .ndpi .mrxs …, or png/jpg/tif)
#   peek ~/Pictures             a local folder or file
#   peek --setup [host]         install what it needs there (pip --user: pillow, openslide)
# Needs nothing installed on the server beyond Python + those packages: the viewer is sent
# over ssh. DUSK_VIEW_PYTHON picks a specific interpreter.
: ${DUSK_VIEW_PYTHON:=}

# shell snippet that sets $PY to a Python with Pillow (preferring one that also has openslide)
_dk_view_pick_py() {
  # score each candidate: Pillow is required; tifffile+zarr (OME-TIFF pyramids) and openslide
  # (.svs/.ndpi/...) add points. conda envs are included, so an existing env is reused.
  REPLY='PY=$DVP; if [ -z "$PY" ]; then best=-1; for p in "$HOME"/miniconda3/envs/*/bin/python "$HOME"/anaconda3/envs/*/bin/python "$HOME"/miniforge3/envs/*/bin/python "$HOME"/mambaforge/envs/*/bin/python "$HOME/miniconda3/bin/python3" "$HOME/anaconda3/bin/python3" "$HOME/miniforge3/bin/python3" "$HOME/mambaforge/bin/python3" "$(command -v python3)"; do [ -x "$p" ] || continue; sc=$("$p" -c "import importlib.util as u; f=u.find_spec; print((f(\"PIL\") is not None) * (1 + 4*(f(\"tifffile\") is not None and f(\"zarr\") is not None and f(\"numpy\") is not None) + 2*(f(\"openslide\") is not None)))" 2>/dev/null) || continue; [ "$sc" -gt "$best" ] && { best=$sc; PY=$p; }; [ "$sc" -ge 7 ] && break; done; fi; [ -n "$PY" ] || { echo "DUSK_VIEW_ERROR 找不到 python3"; exit 2; }'
}

_dk_free_port() {
  local p
  local n
  for n in {1..30}; do
    p=$(( 20000 + RANDOM % 20000 ))
    (( $+commands[lsof] )) && lsof -nP -iTCP:$p -sTCP:LISTEN >/dev/null 2>&1 && continue
    REPLY=$p; return 0
  done
  return 1
}

_dk_peek_setup() {   # _dk_peek_setup [host]
  local host=$1; _dk_view_pick_py
  local cmd="DVP=${(qq)DUSK_VIEW_PYTHON}; $REPLY; echo \"→ \$PY\"; \"\$PY\" -m pip install --user --upgrade pillow openslide-python openslide-bin"
  _dk_pink "  安装看图需要的 Python 包（pillow、openslide、tifffile）到 ${host:-本机}，只装在你的用户目录"
  if [[ -n $host ]]; then command ssh -o ClearAllForwardings=yes "$host" "$cmd"
  else sh -c "$cmd"; fi
}

_dk_peek() {
  if [[ -z $1 || $1 == -h || $1 == --help ]]; then
    print "用法: peek 服务器:/路径      在本机浏览器里看服务器上的大图或文件夹"
    print "      peek ~/本机路径        看本机的图"
    print "      peek --setup [服务器]  安装需要的 Python 包"
    return 0
  fi
  [[ $1 == --setup ]] && { _dk_peek_setup "$2"; return }
  local script=$DUSK_DIR/viewer/dusk_view.py
  [[ -f $script ]] || { print "找不到看图程序，先运行 dusk update"; return 1 }

  local target=$1 host="" tpath=$1
  if [[ ! -e $target && $target == *:* && ${target%%:*} != */* ]]; then
    host=${target%%:*}; tpath=${target#*:}; [[ -z $tpath ]] && tpath=.
  fi
  if [[ -z $host && -n $SSH_CONNECTION ]]; then      # on a server: the browser lives on your Mac
    print "这里是服务器，浏览器在你的电脑上。在你的 Mac 上运行："
    _dk_pink "  peek ${HOST%%.*}:${tpath:A}"
    _dk_dim  "  （${HOST%%.*} 换成你 ~/.ssh/config 里这台服务器的名字）"
    return 0
  fi
  [[ -n $host || -e $tpath ]] || { print "没有这个文件或文件夹：$tpath"; return 1 }

  setopt local_options local_traps no_monitor no_notify
  local attempt log err pid state port
  # closing the terminal tab (HUP) or killing the shell must not leave the ssh tunnel behind
  trap '[[ -n $pid ]] && kill $pid 2>/dev/null; exit 129' HUP
  trap '[[ -n $pid ]] && kill $pid 2>/dev/null; exit 143' TERM
  for attempt in 1 2; do
    _dk_free_port || { print "找不到空闲端口"; return 1 }; port=$REPLY
    log=$(mktemp) err=$(mktemp)
    if [[ -n $host ]]; then
      _dk_view_pick_py
      local b64=$(base64 < $script | tr -d '\n')
      local cmd="DVP=${(qq)DUSK_VIEW_PYTHON}; $REPLY; exec \"\$PY\" -u -c \"import base64;exec(compile(base64.b64decode('$b64'),'dusk_view','exec'))\" --port $port --path ${(qq)tpath}"
      # -tt: a terminal on the server, so the viewer gets hung up on when this connection ends
      command ssh -tt -o ServerAliveInterval=30 -o LogLevel=ERROR -L $port:127.0.0.1:$port "$host" "$cmd" >$log 2>$err </dev/null &
    else
      ${DUSK_VIEW_PYTHON:-python3} -u $script --port $port --path "$tpath" >$log 2>$err &
    fi
    pid=$!
    local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0; state=""
    while (( i < 600 )); do                          # up to ~60 s (first ssh + loading a big image)
      state=$(tr -d '\r' < $log 2>/dev/null | grep -m1 -oE '^DUSK_VIEW_(READY|MISSING|ERROR).*')
      [[ -n $state ]] && break
      kill -0 $pid 2>/dev/null || break
      printf '\r  \e[38;2;228;139;180m%s\e[0m 正在 %s 上启动看图服务…' "${frames:$(( i++ % 10 )):1}" "${host:-本机}"
      sleep 0.1
    done
    printf '\r\e[K'
    if [[ $state == DUSK_VIEW_ERROR*端口* && $attempt == 1 ]]; then kill $pid 2>/dev/null; command rm -f $log $err; continue; fi
    break
  done

  {
    case $state in
      DUSK_VIEW_READY*)
        local url="http://localhost:$port/"
        _dk_pink "  ✓ 正在浏览 ${host:+$host:}$tpath"
        print "    $url"
        grep -q DUSK_VIEW_NO_OPENSLIDE $log && \
          _dk_dim "    （${host:-本机}没有 openslide：普通图片能看，.svs 等切片需要先 peek --setup ${host}）"
        _dk_dim "    滚轮缩放 · 拖动平移 · ←/→ 上一张/下一张 · Esc 回文件夹 · 这里按 Ctrl-C 结束"
        (( ${DUSK_VIEW_NO_OPEN:-0} )) || { (( $+commands[open] )) && open "$url" }
        wait $pid ;;
      DUSK_VIEW_MISSING*)
        print "  ${host:-本机}缺少 Python 包：${state#DUSK_VIEW_MISSING }"
        if _dk_ask "  现在装上吗？（pip --user，只装在你的用户目录）"; then
          _dk_peek_setup "$host" && _dk_peek "$@"
        fi ;;
      DUSK_VIEW_ERROR*)
        print "  ${state#DUSK_VIEW_ERROR }" ;;
      *)
        print "  看图服务没有启动起来："
        grep -vE 'Address already in use|cannot listen to port|Could not request local forwarding|^bind' $err | tail -n 6 | sed 's/^/    /' ;;
    esac
  } always {
    kill $pid 2>/dev/null
    command rm -f $log $err
  }
}
_dk_bind peek _dk_peek
