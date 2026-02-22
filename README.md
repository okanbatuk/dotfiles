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
│   ├── 07-local-env.sh   # Local environment tweaks
│   └── 08-java.sh        # Java (Temurin) & SDKMAN normalization
├── functions/            # Modular Zsh Functions (Auto-loaded)
│   ├── dckr              # Pro Docker manager
│   ├── matches           # Espanso search
│   ├── jlog              # Smart log viewer (jlog)
│   ├── ilog              # Terminal session logger & cleaner
│   ├── projtree          # Modern project tree
│   └── ...               # (One file per function)
├── config/               # App-specific configurations (Linked to ~/.config)
│   ├── alacritty/        # GPU terminal settings
│   ├── nvim/             # Neovim environment
│   ├── jetbrains/        # IntelliJ IDEA & IdeaVim settings
│   │   ├── settings/     # Exported XML configurations (Keymaps, Editor, etc.)
│   │   └── ideavimrc     # Centralized IdeaVim configuration
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
| `jlog`     | Function | **Smart Journalctl Viewer:** Modern interface for systemd logs with shorthand support. Features real-time watching (`-n`), time-based filtering (e.g., `1h`, `10m`, `today`), and colored boot log inspection.                            |
| `ilog`     | Function | **Session Recording:** Use `-r` to start recording the current terminal session to a timestamped log file. Use `-c <file>` to clean ANSI escape codes from a log, converting it into a readable text format using `perl`.                 |
| `pdf`      | Function | Opens a PDF file using **Zathura** in the background. Redirects all output to `/dev/null` and uses `disown` to keep the process alive even after closing the terminal.                                                                    |

## ⚙️ Modular Setup

The `setup.sh` script follows a robust execution order to ensure system integrity:

1. **Infrastructure**: Creates localized log directories.
2. **Core Linking**: Symlinks shell (`.zshrc`) and Git configurations.
3. **Git Privacy**: Interactive setup for `.gitconfig.local` (keeps your email/name private).
4. **Validation**: Verifies Zsh sources and essential dependencies.
5. **Clean Install**: Installs apps (Alacritty, MPV, etc.) and manages config backups.
6. **Automation**: Links custom scripts and sets executable permissions.
7. **Java Environment**: Normalizes Java versions using SDKMAN, installs Temurin JDKs, and sets up IntelliJ IDEA.

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

> 💡 **IntelliJ IDEA**: Keymaps and editor settings are stored under `config/jetbrains/settings/`. To apply them, use `File > Manage IDE Settings > Import Settings` and point to the `settings/` folder.

## 🛠️ Prerequisites

- **Modern CLI Suite:**
  - `eza`: A modern replacement for `ls`, used by `projtree` and `fulltree`.
  - `bat`: A `cat` clone with syntax highlighting for better code reading.
  - `fzf`: Command-line fuzzy finder, essential for `dckr` and matches functions.
  - `fd`: Required for high-performance file cleanup.
  - `ripgrep`(rg): Ultra-fast text search within projects.
  - `jq`: Command-line JSON processor for handling API and config data.
  - `tldr`: Simplified and community-driven man pages.
  - `handlr`: A smarter alternative to `xdg-utils` for opening files and managing default apps.
  - `neofetch`: CLI system information tool used by the `:neo` expansion.
- **Docker Ecosystem:**
  - `docker` & `docker-compose`: The core engine required for the `dckr` management function.
- **Java Ecosystem:**
  - `SDKMAN!`: Primary manager for Java versions, Maven, and Gradle.
  - `Temurin JDK (17, 21)`: Standardized OpenJDK distributions used via SDKMAN.
  - `IntelliJ IDEA Community`: Primary IDE for Java/Kotlin development.
- **Editors & IDEs:**
  - `neovim`: Extensible text editor, configured with `lazy.nvim`, `telescope`, and `oil.nvim`.
  - `zed`: High-performance, multiplayer code editor for rapid development.
- **Viewers & Media:**
  - `drawing`: Simple image editor and drawing application for GNOME.
  - `zathura` & `zathura-pdf-mupdf`: Minimalist PDF viewing used by the `pdf` function.
  - `mpv` & `yt-dlp`: High-performance media playback and YouTube streaming.
- **System & Hardware:**
  - `smartmontools`: Required for S.M.A.R.T. disk health diagnostics and reporting.
  - `util-linux`: Required for the `script` command (used by `rec` alias and `ilog`).
  - `perl`: Required for regex-based log cleaning in `ilog`.
  - `pacman-contrib`: Essential for system maintenance tasks like `paccache`.
- **Fonts & Symbols:**
  - `ttf-jetbrains-mono-nerd`: Developer-focused font with icons, required to correctly display symbols in the terminal.
  - `ttf-nerd-fonts-symbols-common`: Common symbols for Nerd Font users to ensure cross-app icon compatibility.
  - `noto-fonts-emoji`: Google Noto emoji fonts for full emoji support within the terminal and apps.
- **Operating System:** Optimized for **Arch Linux** or **Manjaro**.

## 📊 Logging & Maintenance

All scripts automatically generate logs in the `~/dotfiles/logs/` directory.

- **Smart Cleanup**: The automation suite goes beyond simple updates by performing deep multi-layer cleanup:
  - **Development Caches**: Clears heavy caches from `npm`, `yarn`, `bun`, `pnpm`, and `node_modules` to reclaim gigabytes of space.
  - **Package Management**: Automated cleanup of `pacman` (paccache), `yay`/`paru` AUR caches, and unused `Flatpak` runtimes.
  - **System Internals**: Performs filesystem cache flushing (`sync` & `drop_caches`), vacuums systemd journal logs to the last 2 days, and wipes `/tmp` and thumbnail caches.
- **Auto-Rotation**: Maintenance scripts automatically use `fd` to remove logs older than 7 or 30 days to keep the repository slim.
- **Colorized Output**: All scripts provide enhanced terminal feedback using ANSI color coding for critical warnings (S.M.A.R.T. errors, failed services).
- **Service Hygiene**: Maintenance scripts now automatically detect and report failed system and user-level services. After reporting, they perform a `reset-failed` to clear transient errors, ensuring a clean state for the next run.

## 🔒 Privacy & Git Configuration

No secrets, tokens, or private data are included in this repository.  
All sensitive information should be managed outside of version control (e.g., via environment variables or local overrides).
This repository uses a **Local Include** strategy for Git identity.

- **`.gitconfig`**: Contains global aliases and UI settings (shared).
- **`.gitconfig.local`**: Contains your personal `name` and `email` (local only).

When you run `setup.sh`, it will check if `~/.gitconfig.local` exists. If not, it will prompt you for your details. This ensures your personal info is never committed to the repository history.

> 💡 **Pro Tip**: To get the green Verified badge on your commits, generate a GPG key and add `signingkey = YOUR_KEY_ID` and `gpgsign = true` to your `~/.gitconfig.local`.

## 🛠️ Tools Used

- **OS**: Manjaro Linux
- **Shell**: Zsh (with custom sources for aliases, functions, and env)
- **Terminal**: Alacritty (Configured with FiraCode Nerd Font)
- **Viewers & Players**:
  - **Drawing**: Image editing application for creating and modifying bitmap image.
  - **Zathura**: Minimalist PDF viewer with auto-fit logic.
  - **MPV**: High-performance media player with `yt-dlp` integration.
- **Editors**:
  - Primary: Neovim (Custom visual paste & system clipboard integration)
  - Secondary: Zed, IntelliJ IDEA
  - Legacy/snippets: Visual Studio Code
- **Automation**: Bash, symlinks, and Espanso for text expansion.
- **Font & Symbols**: FiraCode Nerd Font (Retina)

## 📜 License

MIT — feel free to use, fork, or adapt.
