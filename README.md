# Dotfiles

My personal dotfiles and automation scripts for a consistent, reproducible development environment across Linux machines.

> ✨ Includes Zsh, Git, Espanso, custom shell scripts, and Zed editor config (via external repo).  
> VS Code settings are stored directly in this repo for manual syncing.

## 🗂️ Structure

```bash
dotfiles/
├── .zshrc # Zsh configuration
├── .zsh_aliases # Custom shell aliases
├── .zshenv # Environment variables
├── .gitconfig # Git user settings and aliases
├── scripts/ # Custom Bash/Zsh utility scripts
├── config/
│ ├── espanso/ # Espanso text expansion config
│ └── Code/ # VS Code settings & snippets (manual sync)
├── external/ # External configs (e.g., Zed) – managed separately
├── setup.sh # Bootstrap script to symlink configs
└── README.md
```



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

## 🔒 Privacy

No secrets, tokens, or private data are included in this repository.  
All sensitive information should be managed outside of version control (e.g., via environment variables or local overrides).

## 🛠️ Tools Used

- **Shell**: Zsh  
- **OS**: Manjaro Linux  
- **Editors**:  
  - Primary: [Zed](https://zed.dev)  
  - Legacy/snippets: Visual Studio Code  
- **Automation**: Bash, symlinks

## 📜 License
MIT — feel free to use, fork, or adapt.
