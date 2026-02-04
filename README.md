# 🐧 Dotfiles

My personal dotfiles and automation scripts for a consistent, reproducible development environment across Linux machines.

> ✨ Includes Zsh, Git, Espanso, custom shell scripts, and Zed editor config (via external repo).  
> VS Code settings are stored directly in this repo for manual syncing.

## 🗂️ Structure

```bash
dotfiles/
├── logs/                # Centralized logs for all automation
│   ├── updates/         # System update history
│   ├── maintenance/     # Shutdown & cleanup diagnostics
│   └── storage/         # S.M.A.R.T. health & disk usage reports
├── scripts/             # Internal automation (Hidden scripts)
│   ├── .update.sh       # Smart update system (--light or --full)
│   ├── .shutdown.sh     # Deep cache cleanup before exit
│   ├── .disk-report.sh  # S.M.A.R.T. diagnostics & usage
│   ├── .get-info.sh     # Dynamic system info aggregator
│   └── ... (monitor, mount, and timer scripts)
├── config/              # Biome, Code, Espanso, Alacritty, and Neovim configs
├── .zshrc               # Zsh configuration
├── .zsh_aliases         # Custom aliases (up, upfull, get-info)
├── .zsh_functions       # Custom logic (Espanso search, etc.)
├── setup.sh             # Bootstrap script to symlink everything
└── README.md            # Documentation
```

## 🚀 Key Automation Scripts

I've implemented a robust maintenance system with automated logging and log rotation (7-30 days).

| Command       | Script          | Mode    | Description                                                        |
| ------------- | --------------- | ------- | ------------------------------------------------------------------ |
| `up`          | .update.sh      | --light | Fast daily update: Pacman, Yay, Flatpak, Bun, Rust.                |
| `upfull`      | .update.sh      | --full  | Deep maintenance: Mirror refresh, node_modules cleanup, deep info. |
| `get-info`    | .get-info.sh    | Mixed   | Comprehensive system status (Light/Full modes).                    |
| `disk-report` | .disk-report.sh | Manual  | S.M.A.R.T. disk health analysis & top directory usage.             |
| `shut`        | .shutdown.sh    | Y/y     | Deep-cleans system caches (JS/AUR/Flatpak) before poweroff.        |
| `shut`        | .shutdown.sh    | N/n     | ONLY deep-cleans system caches (JS/AUR/Flatpak).                   |

## ⚙️ Setup

Clone and run the setup script:

```bash
git clone https://github.com/okanbatuk/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

This will:

- Symlink shell and Git configs to your home directory
- Set up Espanso configuration
- Clone and link [Zed config](https://github.com/okanbatuk/zed-config) from its own repository
- Link custom scripts to `~/scripts`

> 💡 **VS Code**: Settings and snippets are stored under `config/Code/`. To apply them, manually copy the contents to `~/.config/Code/User/` as needed.

## 🛠️ Prerequisites

- `fd`: Required for high-performance file cleanup.
- `fzf`: Required for the advanced Espanso search function
- `smartmontools`: Required for disk health diagnostics.
- `pacman-contrib`: Required for `paccache` management.

## 📊 Logging & Maintenance

All scripts automatically generate logs in the `~/dotfiles/logs/` directory.

- **Auto-Rotation**: Maintenance scripts automatically use `fd` to remove logs older than 7 or 30 days to keep the repository slim.
- **Colorized Output**: All scripts provide enhanced terminal feedback using ANSI color coding for critical warnings (S.M.A.R.T. errors, failed services).

## 🔒 Privacy

No secrets, tokens, or private data are included in this repository.  
All sensitive information should be managed outside of version control (e.g., via environment variables or local overrides).

## 🛠️ Tools Used

- **OS**: Manjaro Linux
- **Shell**: Zsh (with custom WORDCHARS for better path navigation)
- **Terminal**: Alacritty (Configured with FiraCode Nerd Font)
- **Editors**:
  - Primary: Neovim (Custom visual paste & system clipboard integration)
  - Secondary: Zed
  - Legacy/snippets: Visual Studio Code
- **Font**: FiraCode Nerd Font (Retina)
- **Automation**: Bash, symlinks

## 📜 License

MIT — feel free to use, fork, or adapt.
