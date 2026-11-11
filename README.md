# Sakura Term 🌸

一套蓝粉配色的 iTerm2 + zsh 配置：一明一暗两个主题，本地用浅色、连远程自动切深色，外加 powerlevel10k 配色和几个顺手的小工具。

A blue-and-pink iTerm2 + zsh setup: a light and a dark theme, automatic switching to the dark one on ssh, matching powerlevel10k colors, and a few small shell helpers.

![preview](docs/preview.svg)

## 包含什么

| | 说明 |
|---|---|
| **Mist Sakura**（浅色） | 雾灰粉底 + 墨蓝字，粉色命令、蓝色目录。适合本地日常。 |
| **Sakura Glass**（深色） | 宝石蓝底 + 冷白字，樱粉点缀，5% 透明 + 毛玻璃。用于远程。 |
| **自动切换** | 敲 `ssh` / `tssh` / `mosh` 时窗口切成 Sakura Glass，退出后切回原来的主题。 |
| **p10k 配色** | powerlevel10k 提示栏换成六种低饱和蓝粉色块（没装 p10k 也不影响）。 |
| **欢迎面板** | 新标签页显示一个小的 "Command Center"，颜色跟随主题，明暗都协调。 |
| **`st` 命令** | 一键 ssh 到你的服务器并进入 tmux（iTerm2 原生 tmux 集成 `-CC`）。 |

## 安装

需要 macOS + [iTerm2](https://iterm2.com) + zsh。

```bash
git clone https://github.com/liuxiaZzz/sakura-term.git
cd sakura-term
./install.sh
```

想顺便启用 `st`（连到服务器的 tmux）：

```bash
./install.sh --tmux-host me@my-server
```

只要 iTerm2 主题、不动 zsh：

```bash
./install.sh --themes-only
```

装完之后：

1. iTerm2 → **Settings → Profiles** → 选 **Mist Sakura** → **Other Actions… → Set as Default**
2. 新开一个标签页即可。

图标需要 Nerd Font，没有的话：

```bash
brew install --cask font-jetbrains-mono-nerd-font
```

## 安装脚本做了什么

- 把 `iterm/sakura-term.json` 复制到 `~/Library/Application Support/iTerm2/DynamicProfiles/`（iTerm2 动态配置，实时生效，不改你已有的配置文件）
- 把 `zsh/sakura-term.zsh` 复制到 `~/.config/sakura-term/`
- 在 `~/.zshrc` 末尾加一个 `# >>> sakura-term >>>` 区块来加载它（会先备份成 `.zshrc.bak-sakura-term`）

重复运行是安全的，只会替换自己的文件和区块。

## 配置

在 `~/.zshrc` 的 sakura-term 区块里、`source` 那一行**之前**设置即可：

| 变量 | 默认 | 作用 |
|---|---|---|
| `SAKURA_REMOTE_PROFILE` | `Sakura Glass` | 远程时切到哪个 iTerm2 配置文件 |
| `SAKURA_LOCAL_PROFILE` | `Mist Sakura` | 切回本地时的后备配置文件（默认切回该标签页原本的配置文件） |
| `SAKURA_AUTO_SWITCH` | `1` | `0` 关闭远程自动切换 |
| `SAKURA_P10K_COLORS` | `1` | `0` 保留你自己的 p10k 配色 |
| `SAKURA_WELCOME` | `1` | `0` 关闭欢迎面板 |
| `SAKURA_TMUX_HOST` | 空 | `st` 连接的主机，例如 `me@server` |
| `SAKURA_TMUX_SESSION` | `main` | `st` 默认的 tmux 会话名；`st work` 可指定别的 |

例如：

```zsh
# >>> sakura-term >>>
SAKURA_TMUX_HOST="me@my-server"
SAKURA_WELCOME=0
[[ -f "$HOME/.config/sakura-term/sakura-term.zsh" ]] && source "$HOME/.config/sakura-term/sakura-term.zsh"
# <<< sakura-term <<<
```

## 自己调颜色

所有颜色都在 [`build.py`](build.py) 顶部。改完运行：

```bash
python3 build.py && ./install.sh --themes-only
```

`colors/` 里的 `.itermcolors` 也可以单独导入：iTerm2 → Profiles → Colors → Color Presets → Import。

p10k 色块的颜色在 [`zsh/sakura-term.zsh`](zsh/sakura-term.zsh) 第 1 节。

## 小贴士

- 色板里的 "绿色" 槽位被换成了樱粉色，所以 zsh 语法高亮里的命令、`git status` 里的新文件都会是粉色。
- 浅色主题遵循 light theme 惯例：ANSI 白色（7/15）是深色，避免程序输出 "白字" 时在浅底上看不见。
- iTerm2 的 tmux 集成窗口用的是名为 `tmux` 的配置文件（Settings → General → tmux）。想让 tmux 窗口也是粉蓝：Profiles → tmux → Colors → Color Presets → 导入 `colors/Sakura Glass.itermcolors`。

## 卸载

```bash
./uninstall.sh
```

## License

MIT
