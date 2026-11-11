# Sakura Term 🌸

蓝粉配色的终端全家桶：一明一暗两个 iTerm2 主题、开箱即用的 zsh 环境，加上一套日常和远程快捷命令。macOS 和 Linux 通用。

A blue-and-pink terminal kit: light + dark iTerm2 themes, a ready-to-go zsh setup, and everyday / remote shortcuts. Works on macOS and Linux.

![preview](docs/preview.svg)

## 安装

```bash
git clone https://github.com/liuxiaZzz/sakura-term.git ~/.sakura-term
~/.sakura-term/install.sh
```

装完新开一个终端（或 `exec zsh`），输入 `sakura` 查看所有快捷命令。

macOS 上再做一步：iTerm2 → **Settings → Profiles** → 选 **Mist Sakura** → **Other Actions… → Set as Default**。

> 建议 clone 到 `~/.sakura-term`，以后 `sakura update` 就能一键更新。

### 本机和服务器

同一条命令在两边都能用，脚本会自动判断角色：

| | 本机（macOS） | 服务器（Linux） |
|---|---|---|
| iTerm2 主题、远程自动切主题、`st` | ✓ | – |
| p10k 蓝粉配色、欢迎面板 | ✓ | ✓ |
| shell 环境、日常命令、`listen`、docker 辅助 | ✓ | ✓ |
| 传文件 | `tssh`（拖拽上传） | `trz` / `tsz`、`upload` / `download` |

需要时可以手动指定：`--role local` 或 `--role server`。

### 只装一部分

四个模块可以自由组合：

```bash
~/.sakura-term/install.sh --modules theme,tools      # 只要主题和日常命令
~/.sakura-term/install.sh --no-deps                  # 不下载任何依赖（服务器离线时）
~/.sakura-term/install.sh --themes-only              # 只装 iTerm2 主题
~/.sakura-term/install.sh --tmux-host me@server      # 启用 st（一键进服务器 tmux）
```

| 模块 | 内容 |
|---|---|
| `shell` | oh-my-zsh + powerlevel10k + 自动补全建议 + 语法高亮，fzf，zoxide（`j` 跳目录） |
| `theme` | 两个 iTerm2 主题、p10k 蓝粉配色、远程自动切主题、欢迎面板、`st` |
| `tools` | 回收站式 `rm`、git 缩写、磁盘/进程/端口/权限等小工具 |
| `remote` | SSH 端口转发 `listen`、trzsz 拖拽传文件、docker 辅助 |

## 主题

| | |
|---|---|
| **Mist Sakura**（浅色） | 雾灰粉底 + 墨蓝字，粉色命令、蓝色目录。本地日常用。 |
| **Sakura Glass**（深色） | 宝石蓝底 + 冷白字，樱粉点缀，5% 透明 + 毛玻璃。远程用。 |

- 敲 `ssh` / `tssh` / `mosh` 时窗口自动切成 Sakura Glass，退出后切回原来的主题（iTerm2）。
- p10k 提示栏是六种低饱和蓝粉色块，Linux 上只要终端支持真彩色也一样。
- 色板里的"绿色"槽位换成了樱粉，所以命令高亮、`git status` 新文件都是粉色。

## 快捷命令

输入 `sakura` 随时查看。

**日常（tools）**

| 命令 | 作用 |
|---|---|
| `rm` / `del <文件>` | 移到回收站，可以恢复（macOS 用系统废纸篓，Linux 用 `~/.local/share/Trash`） |
| `delf <文件>` | 真正删除 |
| `empty_trash` | 清空回收站（会确认） |
| `gita` `gitaa` `gitb` `gitst` `gitl` `gitr` `gitpl` `gitps` | git add / add . / branch / status / log / reset / pull / push 当前分支 |
| `gitc [说明]` | 提交；不带参数会问你 |
| `gitch [分支]` | 切分支；不带参数用 fzf 选 |
| `sz` · `sz <路径> [深度]` | 看磁盘 · 看目录大小（按大小排序） |
| `szn [目录]` | 数文件个数 |
| `pid <关键词>` | 查进程；不带参数且有 NVIDIA 时显示 GPU 进程 |
| `port <端口>` | 谁在监听这个端口 |
| `pathadd <目录> [-s]` | 加到 PATH，`-s` 永久写入 |
| `mychmod` / `mychown <目录> <值>` | 递归改权限 / 所有者（会确认，必要时用 sudo） |
| `ll` `la` `l` `cl` `sc` | 列表（有 eza 时自动用 eza）/ 清屏 / 重新加载 zsh |

**远程（remote）**

| 命令 | 作用 |
|---|---|
| `listen` | 交互式 SSH 端口转发；也可以直接 `listen L 服务器 8888`（本机访问服务器的 8888） |
| `listen R 服务器 3000` · `listen D 服务器 1080` | 远程转发 · socks5 代理 |
| `tssh 服务器` | 带拖拽上传的 ssh（本机；服务器上装了 sakura-term 就有 trz） |
| `upload` · `download [文件]` | 在服务器上运行，弹出本地文件框上传 / 下载到本地 |
| `dps` · `dsh <容器>` · `dlog <容器>` | docker ps / 进容器 / 看日志 |
| `dockeradd [用户]` | Linux 上免 sudo 使用 docker |
| `st [会话名]` | 一键进服务器的 tmux（iTerm2 原生集成，需 `--tmux-host`） |

**shell**

| 按键 / 命令 | 作用 |
|---|---|
| `j <关键词>` | 跳到常去的目录 |
| `Ctrl-R` · `Ctrl-T` · `Alt-C` | fzf 搜历史 · 搜文件 · 跳目录 |
| `x <压缩包>` | 解压任意格式 |
| `Esc Esc` | 给上一条命令加 `sudo` |

**管理**

| 命令 | 作用 |
|---|---|
| `sakura` | 速查表 |
| `sakura update` | 拉取最新版并重新安装 |
| `sakura doctor` | 检查依赖是否齐全 |

## 设置

在 `~/.zshrc` 的 sakura-term 区块**之前**设置即可：

| 变量 | 默认 | 作用 |
|---|---|---|
| `SAKURA_MODULES` | 安装时选的 | 例如 `SAKURA_MODULES=(theme tools)` |
| `SAKURA_SAFE_RM` | `1` | `0` 让 `rm` 恢复原样 |
| `SAKURA_REMOTE_PROFILE` | `Sakura Glass` | 远程时切到哪个 iTerm2 配置文件 |
| `SAKURA_AUTO_SWITCH` | `1` | `0` 关闭远程自动切换 |
| `SAKURA_P10K_COLORS` | `1` | `0` 保留你自己的 p10k 配色 |
| `SAKURA_WELCOME` | `1` | `0` 关闭欢迎面板 |
| `SAKURA_TMUX_HOST` | 空 | `st` 连接的主机 |
| `SAKURA_TMUX_SESSION` | `main` | `st` 默认会话名 |

## 安装脚本做了什么

- **shell 模块**：把 oh-my-zsh、powerlevel10k、两个插件 clone 到 `~/.oh-my-zsh`；fzf 装到 `~/.fzf`；zoxide 装到 `~/.local/bin`。缺 zsh/git/curl 时会尝试用 apt/dnf/yum/pacman 安装（需要 sudo）。如果你的 `~/.zshrc` 已经加载了 oh-my-zsh，就不重复加载。
- 没有 `~/.p10k.zsh` 时，复制 powerlevel10k 自带的 rainbow 配置，并套上 Sakura 的布局。
- **remote 模块**：从 GitHub Releases 下载到 `~/.local/bin`：本机下载 tssh，服务器下载 trz / tsz。
- **theme 模块（macOS）**：把两个主题放进 iTerm2 的 DynamicProfiles，实时生效，不碰你已有的配置文件。
- 把 zsh 模块复制到 `~/.config/sakura-term/`，在 `~/.zshrc` 末尾加一个 `# >>> sakura-term >>>` 区块（先备份成 `.zshrc.bak-sakura-term`）。

重复运行是安全的。不会自动改你的登录 shell，如果不是 zsh 会提示你 `chsh` 命令。

## 自己调颜色

主题颜色在 [`build.py`](build.py) 顶部，改完运行：

```bash
python3 build.py && ./install.sh --themes-only
```

p10k 色块在 [`zsh/modules/theme.zsh`](zsh/modules/theme.zsh) 第 1 节。

## 卸载

```bash
~/.sakura-term/uninstall.sh
```

oh-my-zsh、fzf 等工具会保留，脚本会告诉你它们在哪。

## 致谢

日常与远程命令的思路来自 [GCR](https://github.com/gaojunbin/GCR)（Apache-2.0），这里做了跨平台重写，并去掉了站点专用的功能，详见 [NOTICE](NOTICE)。

## License

[Apache-2.0](LICENSE)
