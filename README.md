# 🐧 Dotfiles

My personal dotfiles and automation scripts for a consistent, reproducible development environment across Linux machines.

> ✨ Includes Zsh, Git, Docker, Espanso, Zathura, Mpv, custom shell scripts, and Zed editor config (via external repo).  
> VS Code settings are stored directly in this repo for manual syncing.

## 🗂️ Structure

```bash
dotfiles/
├── logs/                 # Centralized logs for all automation
│   ├── updates/          # System update history
│   ├── maintenance/      # Shutdown & cleanup diagnostics
│   └── storage/          # S.M.A.R.T. health & disk usage reports
├── install/              # Modular Bootstrap Tasks (Orchestrated by setup.sh)
│   ├── 00-core.sh        # Shared environment & global variables (Inherited)
│   ├── 01-system.sh      # Dependencies, logs, and fonts
│   ├── 02-links.sh       # Core dotfiles and .config/ app linking
│   ├── 03-zsh-config.sh  # .zshrc sourcing logic & function loader
│   ├── 04-git.sh         # Personal Git identity & GPG setup
│   ├── 05-zed-conf.sh    # External Zed editor configuration
│   └── 06-scripts.sh     # Automation scripts linking (~/scripts)
├── functions/            # Modular Zsh Functions (Auto-loaded)
│   ├── dckr              # Pro Docker manager
│   ├── matches           # Espanso search
│   ├── projtree          # Modern project tree
│   └── ...               # (One file per function)
├── config/               # App-specific configurations (Linked to ~/.config)
│   ├── alacritty/        # GPU terminal settings
│   ├── nvim/             # Neovim environment
│   └── ...               # (espanso, mpv, zathura, Code)
├── scripts/              # Internal automation scripts
│   ├── update.sh         # Smart update system
│   └── ...               # (shutdown, disk-report, get-info)
├── .zshrc                # Main Zsh entry point
├── .zsh_aliases          # Custom aliases
├── .zshenv               # Environment variables
├── .gitconfig            # Global git settings (UI, aliases)
├── setup.sh              # Main Orchestrator (Orchestrates /install scripts)
└── README.md             # This documentation
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

| Command    | Type     | Description                                                                                                                                                                                                                               |
| ---------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `dckr`     | Function | **Advanced Docker Management:** A modular CLI tool for rapid container workflows. Supports interactive image/container selection via `fzf`, automatic `.env` loading, port mapping, and `docker-compose` integration with smart defaults. |
| `projtree` | Function | Modern tree view with auto-ignores (`node_modules`, `.git`, `dist`). Supports `-p` for **path**, `-d` for **depth**, `-i` for **ignore patterns** with interactive tab-completion (multi-flag support & auto-strips path prefix).         |
| `fulltree` | Function | Advanced tree view all files. Supports `-p` for **path**, `-d` for **depth**, `-i` for **ignore patterns** with interactive tab-completion (multi-flag support & auto-strips path prefix).                                                |
| `matches`  | Function | Interactive Espanso trigger search using `fzf`.                                                                                                                                                                                           |
| `pdf`      | Function | Opens a PDF file using **Zathura** in the background. Redirects all output to `/dev/null` and uses `disown` to keep the process alive even after closing the terminal.                                                                    |

## ⚙️ Modular Setup

The `setup.sh` script follows a robust execution order to ensure system integrity:

1. **Infrastructure**: Creates localized log directories.
2. **Core Linking**: Symlinks shell (`.zshrc`) and Git configurations.
3. **Git Privacy**: Interactive setup for `.gitconfig.local` (keeps your email/name private).
4. **Validation**: Verifies Zsh sources and essential dependencies.
5. **Clean Install**: Installs apps (Alacritty, MPV, etc.) and manages config backups.
6. **Automation**: Links custom scripts and sets executable permissions.

Clone the repo:

```bash
git clone https://github.com/okanbatuk/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

##### **1. Interactive Mode (Default)**

Run the orchestrator to choose specific tasks or maintenance actions:

```bash
./setup.sh
```

##### **2. Automatic Mode**

For headless environments, use the `--auto` flag to bypass the menu:

```bash
./setup.sh --auto
```

##### **3. Standalone Execution**

Every script in `install/` can be run independently for targeted updates:

```bash
bash install/01.system.sh
```

This will:

- Symlink shell and Git configs to your home directory
- Set up **Alacritty, Zathura, and MPV** configurations under `~/.config/`.
- Set up Espanso configuration
- Clone and link [Zed config](https://github.com/okanbatuk/zed-config) from its own repository
- Link custom scripts to `~/scripts`

> 💡 **VS Code**: Settings and snippets are stored under `config/Code/`. To apply them, manually copy the contents to `~/.config/Code/User/` as needed.

## 🛠️ Prerequisites

- **Modern CLI Suite:**
  - `eza`: A modern replacement for `ls`, used by `projtree` and `fulltree`.
  - `bat`: A `cat` clone with syntax highlighting for better code reading.
  - `fzf`: Command-line fuzzy finder, essential for `dckr` and matches functions.
  - `fd`: Required for high-performance file cleanup.
  - `ripgrep`(rg): Ultra-fast text search within projects.
  - `jq`: Command-line JSON processor for handling API and config data.
  - `tldr`: Simplified and community-driven man pages.
- **Docker Ecosystem:**
  - `docker` & `docker-compose`: The core engine required for the `dckr` management function.
- **Viewers & Media:**
  - `zathura` & `zathura-pdf-mupdf`: Minimalist PDF viewing used by the `pdf` function.
  - `mpv` & `yt-dlp`: High-performance media playback and YouTube streaming.
- **System & Hardware:**
  - `smartmontools`: Required for S.M.A.R.T. disk health diagnostics and reporting.
  - `pacman-contrib`: Essential for system maintenance tasks like `paccache`.
- **Fonts & Symbols:**
  - `ttf-jetbrains-mono-nerd`: Developer-focused font with icons, required to correctly display symbols in the terminal.
  - `ttf-nerd-fonts-symbols-common`: Common symbols for Nerd Font users to ensure cross-app icon compatibility.
  - `noto-fonts-emoji`: Google Noto emoji fonts for full emoji support within the terminal and apps.
- **Operating System:** Optimized for **Arch Linux** or **Manjaro**.

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
- **Font & Symbols**: FiraCode Nerd Font (Retina)

## 📜 License

MIT — feel free to use, fork, or adapt.
