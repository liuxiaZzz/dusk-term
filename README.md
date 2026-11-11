# Dusk 🌸

English · [中文](README.zh-CN.md)

A blue-and-pink terminal kit for people who live on remote servers: four iTerm2 themes (light, dark and frosted glass), a ready-to-go zsh setup, a Control Center, one-command tmux on your servers, a QuPath-style viewer for huge images, and everyday shortcuts. macOS and Linux.

![preview](docs/preview.svg)

## Install

```bash
git clone https://github.com/liuxiaZzz/dusk-term.git ~/.dusk
~/.dusk/install.sh
```

The installer asks three questions (Enter takes the default):

| Question | Choices |
|---|---|
| Style | **Classic**: Dusk Light + Dusk Dark, 5% see-through · **Glass**: Dusk Glass Light + Glass Dark, frosted glass |
| Local and remote | **Split**: light here, dark automatically when you ssh somewhere · **Dark** everywhere · **Light** everywhere |
| tmux on a server | optional: your servers, so `tm` can open their tmux sessions |

Skip the questions with flags: `--style classic|glass`, `--mode split|dark|light`, `--tmux-host me@server`, or `-y` for defaults. Running it again keeps your earlier answers.

Then open a new terminal and type **`dusk`** — that's the only command you need to remember.

On macOS, set the default iTerm2 profile once: iTerm2 → **Settings → Profiles** → pick the profile the installer names → **Other Actions… → Set as Default**.

### Your computer and your servers

The same command works on both; the installer detects the role:

| | Your computer (macOS) | Server (Linux) |
|---|---|---|
| iTerm2 themes, auto-switch on ssh, `tm` | ✓ | – |
| Prompt colors, Control Center | ✓ | ✓ |
| zsh setup, shortcuts, `listen`, docker helpers | ✓ | ✓ |
| File transfer | `tssh` (drag and drop) | `trz` / `tsz`, `upload` / `download` |

### Living with GCR or your own setup

Dusk never takes a command name that something else already defines: if GCR, an oh-my-zsh plugin or your own alias already has `rm`, `pid`, `gitps` …, that version stays, and the installer and `dusk help` list them. Put `DUSK_OVERRIDE=1` before the dusk block in `~/.zshrc` to use Dusk's versions instead. Dusk lives in `~/.config/dusk`, so updates of other tools don't touch it.

### Only some parts

```bash
~/.dusk/install.sh --modules theme,tools      # pick modules: shell, theme, tools, remote
~/.dusk/install.sh --no-deps                  # don't download anything (offline servers)
~/.dusk/install.sh --themes-only              # only the iTerm2 themes
```

| Module | What it adds |
|---|---|
| `shell` | oh-my-zsh + powerlevel10k + autosuggestions + syntax highlighting, fzf, zoxide (`j`) |
| `theme` | the iTerm2 themes, prompt colors, typing colors, auto-switch on ssh, hostname watermark, `tm` |
| `tools` | trash-based `rm`, git shortcuts, disk / process / port / permission helpers |
| `remote` | `listen` (port forwarding), `peek` (huge images), trzsz file transfer, docker helpers |

## The one command: `dusk`

Type `dusk` for a command palette with everything. With fzf installed you can type a few letters to filter ("port", "theme", "tmux"), press Enter, and it asks for any argument it needs. Afterwards it tells you the short command for next time.

## Themes

| | |
|---|---|
| **Dusk Light** | misty pink-grey background, ink-blue text, pink commands, blue folders |
| **Dusk Dark** | sapphire background, cool white text, pink accents, 5% see-through |
| **Dusk Glass Light** | frosted cool-white glass, ~38% see-through with strong blur; prompt blocks stay solid, like iOS |
| **Dusk Glass Dark** | deep sapphire smoked glass, ~42% see-through |

- **Auto-switch:** `ssh` / `tssh` / `mosh` switch the window to your remote profile and back when you leave (iTerm2).
- **Prompt:** powerlevel10k segments in six muted blue/pink tones.
- **Typing colors:** valid commands turn blue, typos pink, as you type — also on servers without Dusk, because the palette's "green" slot is blue.
- **Hostname watermark:** while you're on a server, its name shows small and faint in the top-right corner.

Change any of it later with `dusk theme` (menus, or `dusk theme glass split`); the current tab switches right away.

## Control Center

New tabs show an iOS / macOS style Control Center; type `hud` to bring it back:

- a lock-screen clock with a blue-to-pink gradient, the date and a greeting
- CPU / memory / disk / battery tiles with sliders (GPU or uptime on servers)
- workspace (folder, git branch and changes, conda env) and system (host, IP, where you ssh'd from)
- a row of shortcut pills

It adapts to narrow windows; `hud -c` is a one-line version. `DUSK_WELCOME=2` shows only that on new tabs, `0` turns it off. It stays quiet inside tmux.

## tmux on your servers: `tm`

```bash
tm                  # list the tmux sessions on all your servers, pick one or start a new one
tm work             # session "work" on your default server
tm gpu1 train       # session "train" on gpu1 (any host from ~/.ssh/config)
```

The list shows each session's windows, whether it's attached, and when it was last used; "other servers…" lets you pick any host from `~/.ssh/config` and add it. Sessions open with iTerm2's native tmux integration in a window that already has your remote colors. Set servers, default session, the command's name and colors with `dusk tmux`.

For consistent colors in tmux windows, in iTerm2 → **Settings → General → tmux**: untick *Use "tmux" profile rather than profile of the connecting session*, and tick *Automatically bury the tmux client session after connecting*.

## Huge images: `peek`

Zoom into whole-slide images and other huge images on a server like in QuPath: **tiles are cut on the server, you look at them in your own browser.**

```bash
peek myserver:/data/slides        # browse a folder (thumbnail grid, click to open)
peek myserver:/data/a.ome.tif     # open one image
peek ~/Pictures                   # local images work too
```

Scroll to zoom, drag to pan, minimap in the corner, ←/→ for previous/next, Esc back to the folder, ⌘-click a thumbnail for a new tab. OME-TIFF and pyramidal TIFF, `.svs` `.ndpi` `.mrxs` `.scn` and plain PNG/JPEG/TIFF are supported, with µm per pixel and a scale bar for slides. Nothing is installed on the server: the viewer is sent over ssh and the right conda env is picked automatically (`peek --setup myserver` installs missing packages with `pip --user`).

> Want only this? There's a standalone, lighter version for colleagues: [liuxiaZzz/peek](https://github.com/liuxiaZzz/peek).

## Shortcuts

`dusk help` shows all of them.

**Everyday (tools)**

| Command | |
|---|---|
| `rm` / `del <file>` | move to the trash, recoverable (macOS Trash; `~/.local/share/Trash` on Linux) |
| `delf <file>` | really delete |
| `empty_trash` | empty the trash (asks first) |
| `gita` `gitaa` `gitb` `gitst` `gitl` `gitr` `gitpl` `gitps` | git add / add . / branch / status / log / reset / pull / push current branch |
| `gitc [message]` | commit (asks if no message) |
| `gitch [branch]` | switch branch (fzf picker if none given) |
| `sz` · `sz <path> [depth]` | disks · folder sizes, sorted |
| `szn [folder]` | count files |
| `pid <name>` | find processes; no name + NVIDIA: GPU processes |
| `port <port>` | who listens on a port |
| `pathadd <dir> [-s]` | add to PATH, `-s` to keep it |
| `mychmod` / `mychown <dir> <value>` | recursive chmod / chown (asks first, sudo if needed) |
| `ll` `la` `l` `cl` `sc` | listings (eza if installed) / clear / reload zsh |

**Remote**

| Command | |
|---|---|
| `listen` | interactive SSH port forwarding; or `listen L server 8888` (reach the server's 8888 locally) |
| `listen R server 3000` · `listen D server 1080` | remote forwarding · socks5 proxy |
| `tssh server` | ssh with drag-and-drop upload (trzsz) |
| `upload` · `download [file]` | on the server: upload from / download to your computer |
| `dps` · `dsh <container>` · `dlog <container>` | docker ps / shell into a container / follow logs |
| `dockeradd [user]` | use docker without sudo (Linux) |

**Shell**

| Key / command | |
|---|---|
| `j <keyword>` | jump to a folder you visit often |
| `Ctrl-R` · `Ctrl-T` · `Alt-C` | fzf: history · files · folders |
| `x <archive>` | extract anything |
| `Esc Esc` | prefix the last command with `sudo` |

**Managing Dusk**

| Command | |
|---|---|
| `dusk` | command palette |
| `hud` | Control Center |
| `dusk help` | cheat sheet |
| `dusk theme` · `dusk tmux` | change look · set up `tm` |
| `dusk update` | pull the latest version and reinstall (keeps your choices) |
| `dusk doctor` | check dependencies |

## Language

Messages follow your system language: Chinese on a Chinese system, English otherwise. Force one with `DUSK_LANG=en` or `DUSK_LANG=zh` before the dusk block in `~/.zshrc`. The `peek` viewer page follows your browser's language.

## Settings

Choices made by the installer, `dusk theme` and `dusk tmux` are stored in `~/.config/dusk/config.zsh`. Other switches go before the dusk block in `~/.zshrc`:

| Variable | Default | |
|---|---|---|
| `DUSK_LANG` | system | `en` or `zh` |
| `DUSK_MODULES` | as installed | e.g. `DUSK_MODULES=(theme tools)` |
| `DUSK_SAFE_RM` | `1` | `0` leaves `rm` alone |
| `DUSK_OVERRIDE` | `0` | `1` lets Dusk's commands replace same-named ones from other tools |
| `DUSK_P10K_COLORS` | `1` | `0` keeps your own prompt colors |
| `DUSK_SYNTAX_COLORS` | `1` | `0` keeps the default typing colors |
| `DUSK_BADGE` | `1` | `0` hides the hostname watermark |
| `DUSK_WELCOME` | `1` | Control Center on new tabs: `1` full, `2` one line, `0` off |

## What the installer does

- **shell:** clones oh-my-zsh, powerlevel10k and two plugins into `~/.oh-my-zsh`, fzf into `~/.fzf`, zoxide into `~/.local/bin`; installs zsh/git/curl with apt/dnf/yum/pacman if missing (needs sudo). If your `~/.zshrc` already loads oh-my-zsh it isn't loaded twice. Without a prompt config it copies powerlevel10k's rainbow style with Dusk's layout.
- **remote:** downloads tssh (your computer) or trz/tsz (servers) from GitHub releases into `~/.local/bin`.
- **theme (macOS):** puts the four themes into iTerm2's DynamicProfiles (live, your own profiles untouched). Old files defining the same profiles are moved to a backup that `uninstall.sh` restores.
- Copies the zsh modules to `~/.config/dusk` and adds a `# >>> dusk >>>` block at the end of `~/.zshrc` (backed up first).

It never changes your login shell; if it isn't zsh it shows the `chsh` command.

## Your own colors

Theme colors are at the top of [`build.py`](build.py):

```bash
python3 build.py && ./install.sh --themes-only
```

Prompt colors are in [`zsh/modules/theme.zsh`](zsh/modules/theme.zsh), section 1.

## Uninstall

```bash
~/.dusk/uninstall.sh
```

oh-my-zsh, fzf and the other tools are left in place; it tells you where they are.

## Credits

The everyday and remote commands started from ideas in [GCR](https://github.com/gaojunbin/GCR) (Apache-2.0), rewritten for macOS and Linux without the site-specific parts — see [NOTICE](NOTICE).

## License

[Apache-2.0](LICENSE)
