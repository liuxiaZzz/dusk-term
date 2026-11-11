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
