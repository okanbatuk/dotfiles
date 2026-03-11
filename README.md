# 🐧 Dotfiles

My personal dotfiles and automation scripts for a consistent, reproducible development environment across Linux machines.

> ✨ Includes Zsh, Git, Docker, Espanso, Zathura, Mpv, custom shell scripts, and Zed editor config (via external repo).  
> VS Code settings are stored directly in this repo for manual syncing.

## 🗂️ Structure

```bash
dotfiles/
├── logs/                 # Centralized logs for all automation
│   ├── custom/           # Logs for user-defined manual scripts
│   ├── setup/            # Detailed logs for each setup.sh execution session
│   ├── state/            # Persistence layer tracking completed installation tasks (.done files)
│   ├── updates/          # System update history
│   ├── maintenance/      # Shutdown & cleanup diagnostics
│   └── storage/          # S.M.A.R.T. health & disk usage reports
├── install/              # Modular Bootstrap Tasks (Orchestrated by setup.sh)
│   ├── 01-system.sh      # Core dependencies (base-devel, git, curl, unzip)
│   ├── 02-dev-env.sh     # FNM, Node.js (LTS), Bun, Global Shims (nopt, semver) & Editors
│   ├── 03-links.sh       # Core dotfiles and .config/ app linking
│   ├── 04-zsh-config.sh  # .zshrc sourcing logic & function loader
│   ├── 05-git.sh         # Personal Git identity & GPG setup
│   ├── 06-zed-conf.sh    # External Zed editor configuration
│   ├── 07-scripts.sh     # Automation scripts linking (~/scripts)
│   └── 08-local-env.sh   # Machine-specific tweaks
├── functions/            # Modular Zsh Functions (Auto-loaded)
│   ├── dckr              # Pro Docker manager
│   ├── matches           # Espanso search
│   ├── fnote             # Interactive Note Navigator (fzf + bat)
│   ├── jlog              # Smart log viewer (jlog)
│   ├── ilog              # Terminal session logger & cleaner
│   ├── projtree          # Modern project tree
│   ├── chmod             # Recursive permission guard
│   ├── chown             # Recursive ownership guard
│   ├── dprune            # Prune safety with container summary
│   ├── mv                # Overwrite protection for moving
│   ├── cp                # Overwrite protection for copies
│   ├── rm                # Safe 'rm' wrapper (strips -f, enforces interaction)
│   ├── gpush             # Safe 'git' wrapper (handles safe force pushing)
│   └── ...               # (One file per function)
├── config/               # App-specific configurations (Linked to ~/.config)
│   ├── alacritty/        # GPU terminal settings
│   ├── nvim/             # Neovim environment
│   └── systemd/          # System-level update & maintenance units (linked to /etc)
│   └── ...               # (espanso, mpv, zathura, Code)
├── scripts/              # Internal automation scripts
│   ├── guard.sh          # Security Interceptor for high-risk commands
│   └── update.sh         # Core update logic (invoked by systemd or manually)
│   ├── shutdown.sh       # Deep-cleans system caches and manages poweroff
│   ├── disk-report.sh    # S.M.A.R.T. health analysis & usage reports
│   └── ...               # (shutdown, disk-report, get-info)
├── .zshrc                # Main Zsh entry point
├── .zsh_aliases          # Custom aliases (including Guardian redirects)
├── .zsh_notes            # Knowledge base aliases
├── .zshenv               # Environment variables
├── .gitconfig            # Global git settings (UI, aliases)
├── core.sh               # Shared environment, global variables & colors (Source of Truth)
├── setup.sh              # Main Orchestrator (Orchestrates /install scripts)
└── README.md             # This documentation
```

## 🚀 Maintenance & System Automation

I've implemented a robust maintenance system with automated logging and log rotation (7-30 days).

| Command       | Target Script  | Description                                                                                                                       |
| ------------- | -------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| **GUARDIAN**  | guard.sh       | **Security Layer:** Intercepts high-risk commands (`npm -g`, `chmod 777`, etc.) to prevent root pollution and system instability. |
| `up`          | update.sh      | **Mode:** `--light` - Fast daily update: Pacman, Yay, Flatpak, Bun, Rust.                                                         |
| `upfull`      | update.sh      | **Mode:** `--full` - Deep maintenance: Mirror refresh, node_modules cleanup, deep info.                                           |
| `get-info`    | get-info.sh    | Comprehensive system status (Light/Full modes).                                                                                   |
| `disk-report` | disk-report.sh | S.M.A.R.T. disk health analysis & top directory usage.                                                                            |
| `shut`        | shutdown.sh    | Deep-cleans system caches. Prompts `Y/y` for poweroff, `N/n` for cleanup only.                                                    |

## 🤖 System Automation (systemd)

The system maintenance cycle is managed via **system-level** systemd units located in `config/systemd/`. These are symlinked to `/etc/systemd/system/` to ensure they can manage core system tasks without manual intervention.

### 🔄 Update Cycles

- **Update-Light (Daily)**: Performs routine package synchronization and updates core development runtimes (Rust, Node.js, Bun).
- **Update-Full (Weekly)**: Executes deep system maintenance, including mirror optimization, orphan package removal, and project-specific cleanup (e.g., recursive `node_modules` removal).

### 🛡️ Security & Privilege Management

To maintain high security while allowing automation:

- **Root Context**: The primary service runs as `root` to handle `pacman` and system-level operations.
- **User Context**: Sensitive tools like `yay` (AUR), `rustup`, and `fnm` are executed within the user's environment via a `run_as_user` wrapper to comply with AUR security policies.
- **Sudoers Integration**: Specific binaries (`yay`, `pacman`) are granted restricted `NOPASSWD` access in `/etc/sudoers.d/` to allow fully non-interactive background execution.

## 🛠️ Navigation & Config Tools

Modern CLI tools, custom functions, and quick-access configuration shortcuts.

| Command               | Type     | Description                                                                                                                                                                                                                               |
| --------------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `dckr`                | Function | **Advanced Docker Management:** A modular CLI tool for rapid container workflows. Supports interactive image/container selection via `fzf`, automatic `.env` loading, port mapping, and `docker-compose` integration with smart defaults. |
| `projtree`            | Function | Modern tree view with auto-ignores (`node_modules`, `.git`, `dist`). Supports `-p` for **path**, `-d` for **depth**, `-i` for **ignore patterns** with interactive tab-completion (multi-flag support & auto-strips path prefix).         |
| `fulltree`            | Function | Advanced tree view all files. Supports `-p` for **path**, `-d` for **depth**, `-i` for **ignore patterns** with interactive tab-completion (multi-flag support & auto-strips path prefix).                                                |
| `matches`             | Function | Interactive Espanso trigger search using `fzf`.                                                                                                                                                                                           |
| `jlog`                | Function | **Smart Journalctl Viewer:** Modern interface for systemd logs with shorthand support. Features real-time watching (`-n`), time-based filtering (e.g., `1h`, `10m`, `today`), and colored boot log inspection.                            |
| `ilog`                | Function | **Session Recording:** Use `-r` to start recording the current terminal session to a timestamped log file. Use `-c <file>` to clean ANSI escape codes from a log, converting it into a readable text format using `perl`.                 |
| `pdf`                 | Function | Opens a PDF file using **Zathura** in the background. Redirects all output to `/dev/null` and uses `disown` to keep the process alive even after closing the terminal.                                                                    |
| `fnote`               | Function | **Interactive Note Navigator:** `find` and `fzf` to search through your entire knowledge base. Supports instant bat previews for text files and opens `.pdf`, `.doc`, `.docx` via `handlr`.                                               |
| `cp` / `mv`           | Function | **Overwrite Protection:** Checks if the target exists and prompts for confirmation before replacing files.                                                                                                                                |
| `chmod` / `chown`     | Function | **Recursive Guard:** Requires explicit confirmation when using the `-R` flag to prevent mass permission drifts.                                                                                                                           |
| `rm -f`               | Function | **Safety Wrapper:** Automatically strips `-f` / `--force` flags in interactive mode to prevent accidental mass deletions.                                                                                                                 |
| `git push -f`         | Function | **Force-With-Lease:** Intercepts force push to use `--force-with-lease`, protecting remote history from accidental overwrites.                                                                                                            |
| `docker system prune` | Function | **Prune Safety:** Displays a summary of all containers before cleanup to prevent data loss.                                                                                                                                               |

> ### **⚙️ Function Loading Strategy**
>
> Currently using a **Source-on-Startup** strategy for interactive wrappers (`rm`, `gpush`, etc.) to ensure global command interception.
>
> - **Next Milestone**: Migrating non-wrapper utilities to `autoload -Uz` (Lazy Loading) to maintain sub-50ms shell startup times as the function library grows.

## ⚙️ Modular Setup

The `setup.sh` script follows a robust execution order to ensure system integrity:

1. **Infrastructure**: Creates localized log directories.
2. **Core Runtimes & Editors**: Installs **FNM**, **Node.js LTS**, and **Bun** first. Then, installs global shims (`nopt`, `semver`, `node-gyp`) to satisfy dependencies before installing system-level editors (**Zed**, **Neovim**).
3. **Smart Path Management**: All JS tools are isolated in `~/.local/share/fnm`. The `.zshenv` ensures these user-space binaries always take precedence over `/usr/bin/node` to prevent root pollution.
4. **Core Linking**: Symlinks shell (`.zshrc`) and Git configurations.
5. **Git Privacy**: Interactive setup for `.gitconfig.local` (keeps your email/name private).
6. **Validation**: Verifies Zsh sources and essential dependencies.
7. **Clean Install**: Installs apps (Alacritty, MPV, etc.) and manages config backups.
8. **Automation**: Links custom scripts and sets executable permissions.
9. **Security & Guards**: Activates `guard.sh` for package managers and deploys **Protective Wrappers** for high-risk operations (`rm`, `git push`, `chmod`, `chown`, `cp`, `mv`, `docker`) to enforce safe development practices.

## ⚙️ Key Infrastructure Updates:

- **Core Env**: All scripts now source `core.sh` to resolve `$REAL_USER` and colors dynamically.
- **Node.js Management**: Migrated from system-wide Node.js to **fnm (Fast Node Manager)** for lightning-fast, isolated version switching.
- **Runtime Diversity**: Native support for **Bun** alongside Node.js for high-performance streaming-aware projects.
- **Isolated Environments**: Global NPM packages are now stored within FNM's user-space directories, eliminating the need for `sudo` and preventing permission conflicts.
- **Privilege Safety**: All runtime installations (FNM, Bun, Rust) use `run_as_user` to prevent `$HOME` directory pollution and permission drifts.
- **Bulletproof Heredoc Execution**: Install scripts utilize absolute path execution for initial runtime setups to bypass shell hashing delays during the bootstrap process.
- **Zero-Sudo Node Workflow**: Global NPM packages are installed without `sudo`, ensuring the `$HOME` directory permissions remain intact.
- **Modern Tooling**: Transitioned from Prettier to **Biome** for lightning-fast formatting and linting, integrated directly into the Zed and Neovim LSP workflows.

## 🚀 Installation

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

> ✨ Now features a robust menu with a `case` statement to handle numeric selections, automatic runs (`a`), and clean exits (`q`).

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

> 🧪 **Docker Testing**: The repository includes a standardized Docker workflow to verify the "Zero Root Pollution" architecture in a clean Arch Linux environment before deploying to production machines.

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
  - `handlr`: A smarter alternative to `xdg-utils` for opening files and managing default apps.
  - `fastfetch`: Migrated from neofetch for near-instant reporting and this tool use by the `:ff` expansion.
  - `unzip` & `zip`: Required for Bun and FNM installation scripts.
- **Docker Ecosystem:**
  - `docker` & `docker-compose`: The core engine required for the `dckr` management function.
- **JavaScript/TypeScript Ecosystem:**
  - `Fast Node Manager (FNM)`: Now the central engine for Node.js management (replaces system node).
  - `Bun`: High-performance JavaScript runtime, package manager, and bundler.
  - `Biome`: Unified, ultra-fast toolchain for linting and formatting, replacing Prettier in the modern workflow.
  - `typescript-language-server`: Industry-standard LSP for professional TS development.
- **Editors & IDEs:**
  - `neovim`: Extensible text editor, configured with `lazy.nvim`, `telescope`, and `oil.nvim`.
  - `zed`: High-performance, multiplayer code editor for rapid development.
- **Viewers & Media:**
  - `drawing`: Simple image editor and drawing application for GNOME.
  - `tesseract-data-eng/tur`: OCR support for Zathura PDF engine.
  - `zathura` & `zathura-pdf-mupdf`: Minimalist PDF viewing used by the `pdf` function.
  - `mpv` & `yt-dlp`: High-performance media playback and YouTube streaming.
- **Security & Identity:**
  - `gnupg(GPG2)`: Secure communication and commit signing to achieve **Verified** status on GitHub.
  - `pinentry`: A collection of simple PIN or passphrase entry dialogs required for GPG operations.
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
- **GPG Persistence:** The maintenance suite ensures GPG agents are handled correctly during system cleanups to prevent "signing failed" errors in Git workflows.
- **Proactive Health Checks**: Maintenance scripts parse `smartctl` output and provide visual ANSI alerts if reallocated sectors or pending defects are detected, preventing silent data loss.

## 🛡️ Security Guardian & Command Safety

> ### ⚠️ CRITICAL PRIVILEGE ADVISORY
>
> To ensure these safety nets are **never bypassed**, the alias `alias sudo='sudo '` is active in `.zsh_aliases`. This forces Zsh to resolve the command following `sudo`, ensuring that our **Guardian Functions** (`rm`, `chmod`, `gpush`, etc.) are triggered even with elevated privileges.
>
> **Failing to use this alias or bypassing it with `command sudo` may lead to irreversible system damage.**

To maintain a "Clean OS" philosophy, I've implemented a robust Command Interceptor (Guardian):

1. **Passive Guards (`.guard.sh`)**: Intercepts package manager commands (e.g., `npm -g`, `pip`) to prevent root pollution in `$HOME`. It blocks execution if certain blacklist criteria are met.
2. **Interactive Guards (Functions)**: High-risk system commands are wrapped in Zsh functions that enforce safety logic before execution:
   - **Git Safe Push**: Automatically converts `git push -f` to `--force-with-lease`. It also blocks direct pushes to `main`/`master` without explicit `y/n` confirmation.
   - **Recursive Safety**: Commands like `chmod -R` and `chown -R` trigger a Guardian warning, requiring manual confirmation to prevent mass permission drifts.
   - **Data Integrity**: `cp` and `mv` commands check if the target destination already exists and prompt for overwrite confirmation.
   - **Docker Cleanup**: `docker system prune` displays a summary of active containers and images before performing a destructive cleanup.
3. **GPG TTY Integration**: Automatically exports `export GPG_TTY=$(tty)` in `.zshenv` to ensure `pinentry` correctly prompts for passphrases during Git operations, even in nested or multiplexed terminal sessions.

> 💡 **Pro Tip: Bypassing the Guardian**
>
> If you need to execute the original system binary without Guardian interference (e.g., inside a non-interactive script), simply prefix the command with `command`.
>
> - Example: `command rm -rf ./tmp` or `command git push -f origin main`.

> 🛡️ **Shadow Dependency Injection**
>
> To keep the system root directory (`/usr/bin`) clean, we proactively install common Node.js dependencies (`nopt`, `semver`, `node-gyp`) in the user-space global directory.
>
> - **Mechanism**: When `pacman` installs a package like `zed`, it may pull `nodejs` as a hard dependency. Our architecture renders these system-wide binaries inactive by prioritizing the **FNM-managed** binaries in the `$PATH`.
> - **Benefit**: You get the latest Node.js/NPM versions while satisfying the OS's package manager requirements without actually using the outdated system node.

## 🔒 Privacy & Git Configuration

No secrets, tokens, or private data are included in this repository.  
All sensitive information should be managed outside of version control (e.g., via environment variables or local overrides).
This repository uses a **Local Include** strategy for Git identity.

- **`.gitconfig`**: Contains global aliases and UI settings (shared).
- **`.gitconfig.local`**: Contains your personal `name` and `email` (local only).

When you run `setup.sh`, it will check if `~/.gitconfig.local` exists. If not, it will prompt you for your details. This ensures your personal info is never committed to the repository history.

> 💡 **Pro Tip**: To get the green **Verified** badge on your commits, the `setup.sh` orchestrator ensures `gnupg` and `pinentry` are configured. It automates the link between your local GPG key and Git identity by setting `signingkey` and `gpgsign = true` in your `~/.gitconfig.local`.

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
  - Secondary: Zed
  - Legacy/snippets: Visual Studio Code
- **Automation**: Bash, symlinks, and Espanso for text expansion.
- **Font & Symbols**: FiraCode Nerd Font (Retina)

## 📜 License

MIT — feel free to use, fork, or adapt.
