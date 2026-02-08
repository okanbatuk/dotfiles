# 🐧 Dotfiles

My personal dotfiles and automation scripts for a consistent, reproducible development environment across Linux machines.

> ✨ Includes Zsh, Git, Espanso, Zathura, Mpv, custom shell scripts, and Zed editor config (via external repo).  
> VS Code settings are stored directly in this repo for manual syncing.

## 🗂️ Structure

```bash
dotfiles/
├── logs/                 # Centralized logs for all automation
│   ├── updates/          # System update history
│   ├── maintenance/      # Shutdown & cleanup diagnostics
│   └── storage/          # S.M.A.R.T. health & disk usage reports
├── config/               # App-specific configurations (Linked to ~/.config)
│   ├── alacritty/        # GPU-accelerated terminal emulator settings
│   ├── biome/            # Web toolchain (linting & formatting) configs
│   ├── Code/             # VS Code keybindings, settings, and snippets
│   ├── espanso/          # Text expander configuration and matches
│   ├── mpv/              # Media player configs
│   ├── nvim/             # Neovim (Lua/Vimrc) development environment
│   └── zathura/          # Minimalist PDF viewer
├── scripts/              # Internal automation (Hidden scripts)
│   ├── .update.sh        # Smart update system (--light or --full)
│   ├── .shutdown.sh      # Deep cache cleanup before exit
│   ├── .disk-report.sh   # S.M.A.R.T. diagnostics & usage
│   ├── .get-info.sh      # Dynamic system info aggregator
│   ├── .camera-off/on.sh # Privacy & peripheral toggles
│   └── ... (monitor, mount, and timer scripts)
├── .zshrc                # Zsh configuration
├── .zsh_aliases          # Custom aliases (up, upfull, get-info)
├── .zsh_functions        # Custom logic (Espanso search, etc.)
├── setup.sh              # Bootstrap script to symlink everything
└── README.md             # Documentation
```

## 🚀 Maintenance & System Automation

I've implemented a robust maintenance system with automated logging and log rotation (7-30 days).

| Command       | Target Script   | Description                                                                             |
| ------------- | --------------- | --------------------------------------------------------------------------------------- |
| `up`          | .update.sh      | **Mode:** `--light` - Fast daily update: Pacman, Yay, Flatpak, Bun, Rust.               |
| `upfull`      | .update.sh      | **Mode:** `--full` - Deep maintenance: Mirror refresh, node_modules cleanup, deep info. |
| `get-info`    | .get-info.sh    | Comprehensive system status (Light/Full modes).                                         |
| `disk-report` | .disk-report.sh | S.M.A.R.T. disk health analysis & top directory usage.                                  |
| `shut`        | .shutdown.sh    | Deep-cleans system caches. Prompts `Y/y` for poweroff, `N/n` for cleanup only.          |

## 🛠️ Navigation & Config Tools

Modern CLI tools, custom functions, and quick-access configuration shortcuts.

| Command    | Type     | Description                                                                                                                                                                                                                       |
| ---------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `projtree` | Function | Modern tree view with auto-ignores (`node_modules`, `.git`, `dist`). Supports `-p` for **path**, `-d` for **depth**, `-i` for **ignore patterns** with interactive tab-completion (multi-flag support & auto-strips path prefix). |
| `fulltree` | Function | Advanced tree view all files. Supports `-p` for **path**, `-d` for **depth**, `-i` for **ignore patterns** with interactive tab-completion (multi-flag support & auto-strips path prefix).                                        |
| `matches`  | Function | Interactive Espanso trigger search using `fzf`.                                                                                                                                                                                   |
| `pdf`      | Function | Opens a PDF file using **Zathura** in the background. Redirects all output to `/dev/null` and uses `disown` to keep the process alive even after closing the terminal.                                                            |

## ⚙️ Setup

The `setup.sh` script follows a robust execution order to ensure system integrity:

1. **Infrastructure**: Creates localized log directories.
2. **Core Linking**: Symlinks shell (`.zshrc`) and Git configurations.
3. **Git Privacy**: Interactive setup for `.gitconfig.local` (keeps your email/name private).
4. **Validation**: Verifies Zsh sources and essential dependencies.
5. **Clean Install**: Installs apps (Alacritty, MPV, etc.) and manages config backups.
6. **Automation**: Links custom scripts and sets executable permissions.

Clone and run the setup script:

```bash
git clone https://github.com/okanbatuk/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

This will:

- Symlink shell and Git configs to your home directory
- Set up **Alacritty, Zathura, and MPV** configurations under `~/.config/`.
- Set up Espanso configuration
- Clone and link [Zed config](https://github.com/okanbatuk/zed-config) from its own repository
- Link custom scripts to `~/scripts`

> 💡 **VS Code**: Settings and snippets are stored under `config/Code/`. To apply them, manually copy the contents to `~/.config/Code/User/` as needed.

## 🛠️ Prerequisites

- `eza`: Required for `projtree` and `fulltree` (high-performance `tree` replacement).
- `fd`: Required for high-performance file cleanup.
- `fzf`: Required for the advanced Espanso search function
- `zathura` & `zathura-pdf-mupdf`: Required for the `pdf` function and minimalist document viewing.
- `mpv` & `yt-dlp`: Required for terminal-based video streaming and YouTube playback.
- `smartmontools`: Required for disk health diagnostics.
- `pacman-contrib`: Required for `paccache` management.

## 📊 Logging & Maintenance

All scripts automatically generate logs in the `~/dotfiles/logs/` directory.

- **Auto-Rotation**: Maintenance scripts automatically use `fd` to remove logs older than 7 or 30 days to keep the repository slim.
- **Colorized Output**: All scripts provide enhanced terminal feedback using ANSI color coding for critical warnings (S.M.A.R.T. errors, failed services).

## 🔒 Privacy & Git Configuration

No secrets, tokens, or private data are included in this repository.  
All sensitive information should be managed outside of version control (e.g., via environment variables or local overrides).
This repository uses a **Local Include** strategy for Git identity.

- **`.gitconfig`**: Contains global aliases and UI settings (shared).
- **`.gitconfig.local`**: Contains your personal `name` and `email` (local only).

When you run `setup.sh`, it will check if `~/.gitconfig.local` exists. If not, it will prompt you for your details. This ensures your personal info is never committed to the repository history.

> 💡 **Pro Tip**: To get the green Verified badge on your commits, generate a GPG key and add 1`signingkey = YOUR_KEY_ID` and `gpgsign = true` to your `~/.gitconfig.local`.

## 🛠️ Tools Used

- **OS**: Manjaro Linux
- **Shell**: Zsh (with custom sources for aliases, functions, and env)
- **Terminal**: Alacritty (Configured with FiraCode Nerd Font)
- **Viewers & Players**:
  - **Zathura**: Minimalist PDF viewer with auto-fit logic.
  - **MPV**: High-performance media player with `yt-dlp` integration.
- **Editors**:
  - Primary: Neovim (Custom visual paste & system clipboard integration)
  - Secondary: Zed
  - Legacy/snippets: Visual Studio Code
- **Automation**: Bash, symlinks, and Espanso for text expansion.
- **Font**: FiraCode Nerd Font (Retina)

## 📜 License

MIT — feel free to use, fork, or adapt.
