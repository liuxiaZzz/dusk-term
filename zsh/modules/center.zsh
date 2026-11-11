# modules/center.zsh — Dusk Control Center (macOS + Linux)
# A lock-screen style clock and Control Center style tiles, shown once per new tab.
#   hud           show it again any time
#   hud -c        compact one-liner
# DUSK_WELCOME=1 full (default) · 2 compact · 0 off   (never automatic inside tmux)
# Colors are ANSI theme colors, so it follows whichever iTerm2 profile is active.

: ${DUSK_WELCOME:=1}
zmodload -F zsh/datetime b:strftime p:EPOCHSECONDS 2>/dev/null

# ─── look ────────────────────────────────────────────────────────────────────
typeset -gA _CC_GLYPH=(
  0 '█▀█|█ █|▀▀▀'  1 '▄█ | █ |▀▀▀'  2 '▀▀█|█▀▀|▀▀▀'  3 '▀▀█|▀▀█|▀▀▀'  4 '█ █|▀▀█|  ▀'
  5 '█▀▀|▀▀█|▀▀▀'  6 '█▀▀|█▀█|▀▀▀'  7 '▀▀█|  █|  ▀'  8 '█▀█|█▀█|▀▀▀'  9 '█▀█|▀▀█|▀▀▀'
  : '▄|▄| '
)
typeset -ga _CC_ROWCOLOR=(4 13 5)          # clock gradient: blue → light pink → pink
typeset -gA _CC_ICON=(
  cpu '' mem '󰍛' disk '󰋊' bat '󰁹' chg '󰂄'
  gpu '󰢮' up '󰅐' dir '' git '' py ''
  net '󰖩' host '󰒋' ssh '󰌘'
)
typeset -ga _CC_QUOTES_ZH=(
  "保持冷静，保持锋利。" "先锁定目标，再击穿问题。" "终端已就绪，思路开始加速。"
  "今天的主线任务交给你了。" "少一点噪音，多一点执行。" "一次只做一件事。"
)
typeset -ga _CC_QUOTES_EN=(
  "Stay calm, stay sharp." "Pick the target, then break the problem." "Terminal ready. Let's go."
  "Today's main quest is yours." "Less noise, more doing." "One thing at a time."
)

# visible width of a prompt-escaped string (%F{..} %K{..} %f %k %B %b removed).
# Nerd Font icons (private-use area) are drawn 1 cell wide, whatever wcwidth says.
_cc_w() {
  local s=${1//\%[fkbBu]/}
  s=${(S)s//\%[FK]\{*\}/}
  s=${s//\%\%/%}
  local t=${s//[$'\ue000'-$'\uf8ff'$'\U000f0000'-$'\U000ffffd']/}
  REPLY=$(( ${(m)#t} + ${#s} - ${#t} ))
}
# keep the end of a plain string so it fits in $2 cells: "…/scratch/project"
_cc_fit() {
  local s=$1
  _cc_w "$s"; (( REPLY <= $2 )) && { REPLY=$s; return }
  while _cc_w "…$s" && (( REPLY > $2 )); do s=${s:1}; done
  REPLY="…$s"
}
# pad a prompt-escaped string to width $2
_cc_pad() { _cc_w "$1"; local n=$(( $2 - REPLY )); (( n < 0 )) && n=0; REPLY="$1${(l:n:: :)}" }
_cc_esc() { REPLY=${1//\%/%%} }

# a rounded card: _cc_card <width> <title> <line>...   → reply=(lines)
_cc_card() {
  local w=$1 title=$2; shift 2
  local inner=$(( w - 4 )) l
  _cc_w "$title"
  local -a out=("%F{8}╭─%f $title %F{8}${(l:$(( w - 5 - REPLY ))::─:)}╮%f")
  for l in "$@"; do _cc_pad "$l" $inner; out+=("%F{8}│%f $REPLY %F{8}│%f"); done
  out+=("%F{8}╰${(l:$(( w - 2 ))::─:)}╯%f")
  reply=("${out[@]}")
}
# a slider bar like iOS: _cc_bar <percent> <width>
_cc_bar() {
  local p=$1 w=$2 n c=5
  (( p > 100 )) && p=100; (( p < 0 )) && p=0
  n=$(( (p * w + 50) / 100 )); (( p > 0 && n == 0 )) && n=1
  (( p >= 85 )) && c=1
  REPLY="%F{$c}${(l:$n::━:)}%f%F{8}${(l:$(( w - n ))::━:)}%f"
}

# ─── data (fast: a handful of cheap commands) ────────────────────────────────
_cc_collect() {
  typeset -gA CC=()
  local line
  if [[ $OSTYPE == darwin* ]]; then
    local -a s=("${(@f)$(/usr/sbin/sysctl -n vm.loadavg hw.ncpu hw.memsize kern.boottime 2>/dev/null)}")
    local -a la=(${=s[1]//[\{\}]/})
    CC[cpu]=${$(( la[1] * 100.0 / ${s[2]:-1} ))%.*}
    local pg=16384 act=0 wir=0 cmp=0
    for line in "${(@f)$(/usr/bin/vm_stat 2>/dev/null)}"; do
      case $line in
        *"page size of"*)            pg=${${line##*of }%% *} ;;
        "Pages active:"*)            act=${${${line##*:}// /}%.} ;;
        "Pages wired down:"*)        wir=${${${line##*:}// /}%.} ;;
        "Pages occupied by compressor:"*) cmp=${${${line##*:}// /}%.} ;;
      esac
    done
    if [[ ${s[3]} == <1-> ]]; then
      CC[mem]=$(( (act + wir + cmp) * pg * 100 / s[3] ))
      CC[memtot]=$(( s[3] / 1073741824 ))G
    fi
    local boot=${${s[4]#*sec = }%%,*}
    [[ $boot == <1-> ]] && CC[up]=$(( EPOCHSECONDS - boot ))
    CC[disk]=${${(s: :)${(f)"$(df -P /System/Volumes/Data 2>/dev/null || df -P /)"}[-1]}[5]%\%}
    line=$(/usr/bin/pmset -g batt 2>/dev/null)
    if [[ $line == *InternalBattery* ]]; then
      CC[bat]=${${line##*InternalBattery*$'\t'}%%\%*}
      if [[ $line == *"; charging;"* ]]; then CC[chg]=${${DUSK_ZH:+充电中}:-charging}
      elif [[ $line == *"AC attached"* ]]; then CC[chg]=${${DUSK_ZH:+已接电源}:-plugged in}; fi
      [[ $line == *[0-9]:[0-9][0-9]\ remaining* ]] && CC[left]=${${line%% remaining*}##* }
    fi
    CC[ip]=$(/usr/sbin/ipconfig getifaddr en0 2>/dev/null || /usr/sbin/ipconfig getifaddr en1 2>/dev/null)
    CC[os]="macOS $(/usr/bin/sw_vers -productVersion 2>/dev/null)"
  else
    local -a la=(${=$(</proc/loadavg)})
    CC[cpu]=${$(( la[1] * 100.0 / $(nproc 2>/dev/null || echo 1) ))%.*}
    local tot=0 avail=0
    for line in "${(@f)$(</proc/meminfo)}"; do
      case $line in MemTotal:*) tot=${${line//[^0-9]/}} ;; MemAvailable:*) avail=${${line//[^0-9]/}} ;; esac
    done
    (( tot )) && CC[mem]=$(( (tot - avail) * 100 / tot )) && CC[memtot]=$(( tot / 1048576 ))G
    CC[up]=${${(s: :)$(</proc/uptime)}[1]%.*}
    CC[disk]=${${(s: :)${(f)"$(df -P / 2>/dev/null)"}[-1]}[5]%\%}
    local b; for b in /sys/class/power_supply/BAT*(N[1]); do
      CC[bat]=$(<$b/capacity)
      case $(<$b/status) in Charging) CC[chg]=${${DUSK_ZH:+充电中}:-charging} ;; Full|"Not charging") CC[chg]=${${DUSK_ZH:+已接电源}:-plugged in} ;; esac
    done
    if (( $+commands[nvidia-smi] )); then
      local g=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
      [[ -n $g ]] && CC[gpu]=${${g%%,*}// /} CC[gpumem]="${$(( ${${(s:,:)g}[2]} / 1024 ))}/${$(( ${${(s:,:)g}[3]} / 1024 ))}G"
    fi
    CC[ip]=${${=$(hostname -I 2>/dev/null)}[1]}
    [[ -r /etc/os-release ]] && CC[os]=${${(M)${(f)"$(</etc/os-release)"}:#PRETTY_NAME=*}#PRETTY_NAME=}
    CC[os]=${CC[os]//\"/}
  fi
  (( ${CC[cpu]:-0} > 100 )) && CC[cpu]=100
  # workspace
  CC[dir]=${PWD/#$HOME/\~}
  if CC[branch]=$(git symbolic-ref --short -q HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null); then
    CC[dirty]=$(git status --porcelain -uno 2>/dev/null | wc -l | tr -d ' ')
  else CC[branch]=""; fi
  CC[env]=${CONDA_DEFAULT_ENV:-${VIRTUAL_ENV:t}}
  [[ -n $SSH_CONNECTION ]] && CC[from]=${${=SSH_CONNECTION}[1]}
}

_cc_uptime() {
  local s=$1
  local d=$(( s / 86400 )) h=$(( s % 86400 / 3600 )) m=$(( s % 3600 / 60 ))
  if [[ -n $DUSK_ZH ]]; then
    if (( d )); then REPLY="${d}天 ${h}小时"; elif (( h )); then REPLY="${h}小时 ${m}分"; else REPLY="${m}分钟"; fi
  else
    if (( d )); then REPLY="${d}d ${h}h"; elif (( h )); then REPLY="${h}h ${m}m"; else REPLY="${m} min"; fi
  fi
}

# ─── render ──────────────────────────────────────────────────────────────────
_cc_greeting() {
  local h=${(%):-%D{%H}}
  if   (( 10#$h < 6  )); then REPLY=${${DUSK_ZH:+夜深了}:-Up late}
  elif (( 10#$h < 12 )); then REPLY=${${DUSK_ZH:+早上好}:-Good morning}
  elif (( 10#$h < 18 )); then REPLY=${${DUSK_ZH:+下午好}:-Good afternoon}
  else                         REPLY=${${DUSK_ZH:+晚上好}:-Good evening}; fi
}

_cc_compact() {
  _cc_collect; _cc_greeting
  local g=$REPLY t=${(%):-%D{%H:%M}}
  print -rP -- "  %F{5}✻%f %B%F{4}$t%f%b  %F{5}$g%f  %F{8}·%f $_CC_ICON[cpu] ${CC[cpu]}%%  $_CC_ICON[mem] ${CC[mem]}%%  $_CC_ICON[disk] ${CC[disk]}%%${CC[bat]:+  $_CC_ICON[bat] ${CC[bat]}%%}"
}

_cc_full() {
  _cc_collect; _cc_greeting
  local greet=$REPLY
  local cols=${COLUMNS:-80}
  local W=$(( cols - 4 )); (( W > 100 )) && W=100
  local per=4; (( W < 76 )) && per=2
  local tw=$(( (W - (per - 1)) / per ))
  W=$(( tw * per + per - 1 ))
  local -a lines=() r

  # 1. clock card
  local t=${(%):-%D{%H:%M}} i ch
  local -a clock=("" "" "")
  for (( i = 1; i <= $#t; i++ )); do
    ch=$t[i]
    local -a g=("${(@s:|:)_CC_GLYPH[$ch]}")
    clock[1]+="${g[1]} "; clock[2]+="${g[2]} "; clock[3]+="${g[3]} "
  done
  local -a wd=(星期一 星期二 星期三 星期四 星期五 星期六 星期日)
  local -a wde=(Mon Tue Wed Thu Fri Sat Sun) mon=(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
  local Y M D U
  strftime -s Y %Y $EPOCHSECONDS; strftime -s M %m $EPOCHSECONDS
  strftime -s D %d $EPOCHSECONDS; strftime -s U %u $EPOCHSECONDS
  local date
  if [[ -n $DUSK_ZH ]]; then date="${Y}年$(( 10#$M ))月$(( 10#$D ))日  ${wd[U]}"
  else date="${wde[U]}, ${mon[10#$M]} $(( 10#$D )) $Y"; fi
  local -a qs; if [[ -n $DUSK_ZH ]]; then qs=($_CC_QUOTES_ZH); else qs=($_CC_QUOTES_EN); fi
  local quote=${qs[RANDOM % $#qs + 1]}
  local -a right=("%B$date%b" "%F{5}✻ $greet%f" "%F{8}$quote%f")
  local -a cl=("")
  for i in 1 2 3; do cl+=("  %B%F{${_CC_ROWCOLOR[i]}}${clock[i]}%f%b   ${right[i]}"); done
  cl+=("")
  _cc_card $W "%F{4}Dusk%f %F{5}Control Center%f" "${cl[@]}"; lines+=("${reply[@]}")

  # 2. tiles
  local bw=$(( tw - 4 ))
  local -a tiles=() tl
  _cc_tile() {  # _cc_tile <icon> <title> <value> <extra> <percent|"">
    local v="%B$3%b"; [[ -n $4 ]] && v+="  %F{8}$4%f"
    local bar=""; [[ -n $5 ]] && { _cc_bar $5 $bw; bar=$REPLY; }
    _cc_card $tw "%F{4}$1 $2%f" "$v" "$bar"
  }
  _cc_tile $_CC_ICON[cpu]  CPU  "${CC[cpu]:---}%%" "${${DUSK_ZH:+负载}:-load}" ${CC[cpu]:-0};          local -a t1=("${reply[@]}")
  _cc_tile $_CC_ICON[mem]  ${${DUSK_ZH:+内存}:-Memory} "${CC[mem]:---}%%" "${CC[memtot]}" ${CC[mem]:-0}; local -a t2=("${reply[@]}")
  _cc_tile $_CC_ICON[disk] ${${DUSK_ZH:+磁盘}:-Disk} "${CC[disk]:---}%%" "${${DUSK_ZH:+已用}:-used}" ${CC[disk]:-0};       local -a t3=("${reply[@]}")
  if [[ -n ${CC[gpu]} ]]; then
    _cc_tile $_CC_ICON[gpu] GPU "${CC[gpu]}%%" "${CC[gpumem]}" ${CC[gpu]}
  elif [[ -n ${CC[bat]} ]]; then
    local left_word=${${DUSK_ZH:+剩}:-left}
    local extra=${CC[chg]:-${CC[left]:+${CC[left]} $left_word}}
    _cc_tile ${${CC[chg]:+$_CC_ICON[chg]}:-$_CC_ICON[bat]} ${${DUSK_ZH:+电池}:-Battery} "${CC[bat]}%%" "$extra" ${CC[bat]}
    # battery bar: pink when fine, rose when low
    (( CC[bat] <= 20 )) && reply=("${(@)reply//\%F\{5\}━/%F{1}━}")
  else
    _cc_uptime ${CC[up]:-0}; _cc_tile $_CC_ICON[up] ${${DUSK_ZH:+运行}:-Uptime} "$REPLY" "" ""
  fi
  local -a t4=("${reply[@]}")
  local -a row
  if (( per == 4 )); then
    for i in {1..$#t1}; do lines+=("${t1[i]} ${t2[i]} ${t3[i]} ${t4[i]}"); done
  else
    for i in {1..$#t1}; do lines+=("${t1[i]} ${t2[i]}"); done
    for i in {1..$#t3}; do lines+=("${t3[i]} ${t4[i]}"); done
  fi

  # 3. workspace + system cards
  local hw=$(( (W - 1) / 2 )) hw2=$(( W - 1 - (W - 1) / 2 ))
  local cw=$(( (per == 4 ? (W - 1) / 2 : W) - 6 ))      # text room inside a half card
  local x
  _cc_fit "${CC[dir]}" $cw; _cc_esc "$REPLY"
  local -a ws=("%F{4}$_CC_ICON[dir]%f $REPLY")
  if [[ -n ${CC[branch]} ]]; then
    _cc_esc ${CC[branch]}; x="%F{5}$_CC_ICON[git]%f $REPLY"
    [[ ${CC[dirty]:-0} != 0 ]] && x+="  %F{8}${CC[dirty]} ${${DUSK_ZH:+处改动}:-changed}%f"
    ws+=("$x")
  else ws+=("%F{8}$_CC_ICON[git] ${${DUSK_ZH:+不在 git 仓库}:-not a git repo}%f"); fi
  if [[ -n ${CC[env]} ]]; then ws+=("%F{4}$_CC_ICON[py]%f ${CC[env]}")
  else ws+=("%F{8}$_CC_ICON[py] ${${DUSK_ZH:+无 Python 环境}:-no Python env}%f"); fi
  _cc_uptime ${CC[up]:-0}; local up=$REPLY
  _cc_fit "${(%):-%m}" $cw; _cc_esc "$REPLY"
  local -a sy=("%F{4}$_CC_ICON[host]%f $REPLY")
  local offline=${${DUSK_ZH:+离线}:-offline}
  x="%F{5}$_CC_ICON[net]%f ${CC[ip]:-$offline}"
  [[ -n ${CC[from]} ]] && x+="  %F{8}$_CC_ICON[ssh] ${${DUSK_ZH:+来自}:-from} ${CC[from]}%f"
  sy+=("$x" "%F{4}$_CC_ICON[up]%f ${${DUSK_ZH:+已运行}:-up} $up  %F{8}${CC[os]}%f")
  if (( per == 4 )); then
    _cc_card $hw "%F{4}${${DUSK_ZH:+工作区}:-Workspace}%f" "${ws[@]}"; local -a c1=("${reply[@]}")
    _cc_card $hw2 "%F{4}${${DUSK_ZH:+系统}:-System}%f" "${sy[@]}"; local -a c2=("${reply[@]}")
    for i in {1..$#c1}; do lines+=("${c1[i]} ${c2[i]}"); done
  else
    _cc_card $W "%F{4}${${DUSK_ZH:+工作区}:-Workspace}%f" "${ws[@]}"; lines+=("${reply[@]}")
    _cc_card $W "%F{4}${${DUSK_ZH:+系统}:-System}%f" "${sy[@]}"; lines+=("${reply[@]}")
  fi

  # 4. quick actions, like Control Center buttons
  local -a pills=()
  (( $+functions[j] || $+aliases[j] )) && pills+=("j ${${DUSK_ZH:+跳转}:-jump}")
  pills+=("⌃R ${${DUSK_ZH:+历史}:-history}" "⌃T ${${DUSK_ZH:+找文件}:-files}")
  (( $+aliases[x] )) && pills+=("x ${${DUSK_ZH:+解压}:-extract}")
  (( $+functions[dusk] )) && pills+=("dusk ${${DUSK_ZH:+全部功能}:-everything}")
  local p bar="" k=0
  for p in $pills; do
    (( k++ % 2 )) && bar+="%K{5}%F{0} $p %f%k " || bar+="%K{4}%F{0} $p %f%k "
  done
  lines+=(" $bar")

  print
  for i in $lines; do print -rP -- "  $i"; done
  print
}

hud() {   # not `cc`: that name belongs to the C compiler
  export DUSK_WELCOME_SHOWN=1                  # counts as this tab's welcome
  (( $+functions[add-zsh-hook] )) && add-zsh-hook -d precmd _dusk_welcome 2>/dev/null
  if [[ $1 == -c ]]; then _cc_compact; else _cc_full; fi
}

# ─── show once per new tab ──────────────────────────────────────────────────
_dusk_welcome() {
  add-zsh-hook -d precmd _dusk_welcome
  [[ -t 1 && -z $DUSK_WELCOME_SHOWN ]] || return
  [[ -n $TMUX ]] && return                       # every tmux pane is a new shell: stay quiet, `hud` on demand
  export DUSK_WELCOME_SHOWN=1
  if (( DUSK_WELCOME == 2 || ${COLUMNS:-80} < 50 )); then _cc_compact; else _cc_full; fi
}
if (( DUSK_WELCOME )) && [[ -o interactive ]]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _dusk_welcome
fi
