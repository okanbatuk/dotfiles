#!/bin/bash

clear

# 0) HANDLE FLAGS
MODE="light"
INFO_MODE="--light"
[[ "$1" == "--full" ]] && INFO_MODE="--full" && MODE="full"

# === Enable logging ===
LOG_DIR="$HOME/dotfiles/logs/updates"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/update-$(date +%Y-%m-%d)-$MODE.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "\n===== UPDATE STARTED AT $(date) [Mode: $MODE] ====="

# 1) SYSTEM UPDATE
if [[ "$INFO_MODE" == "--full" ]]; then
    echo -e "\n\033[1;34m>>> [$MODE] Deep maintenance in progress...\033[0m"

    # Mirror & Database Sync
    sudo pacman-mirrors --fasttrack 10
fi

echo -e "\n\033[1;32m>>> Updating system packages (Pacman & Yay)...\033[0m"
sudo pacman -Syyu --noconfirm
command -v yay >/dev/null 2>&1 && yay -Syu --noconfirm

echo -e "\n\033[1;32m>>> Updating Flatpak...\033[0m"
flatpak update -y

# 2) TOOLING (Bun & Rust)
echo -e "\n\033[1;32m>>> Updating Bun...\033[0m"
command -v bun >/dev/null 2>&1 && bun upgrade

echo -e "\n\033[1;32m>>> Updating Rustup & Toolchain...\033[0m"
if command -v rustup >/dev/null 2>&1; then
    rustup self update
    rustup update stable
    rustup default stable
    echo -e "  \033[1;32m✅ Rust updated.\033[0m"
fi

if command -v npm >/dev/null 2>&1; then
    echo -e "\n\033[1;32m>>> Updating user-global npm packages...\033[0m"
    npm install -g npm@latest --silent
    npm update -g
    npm cache verify
fi

# 3) CLEANUP
if [[ "$INFO_MODE" == "--full" ]]; then
    echo -e "\n\033[1;34m>>> [$MODE] Deep cleanup (~/.cache, flatpak, node_modules) in progress...\033[0m"

    # 1. Package Cache Cleanup
    echo -e "\n\033[1;36m>>> Cleaning package cache...\033[0m"
    du -sh ~/.cache 2>/dev/null || echo "0    ~/.cache"
    rm -rf ~/.cache/*
    sudo paccache -rk 2

    # 2. Unused Flatpaks
    echo -e "\n\033[1;36m>>> Removing unused Flatpak runtimes...\033[0m"
    flatpak uninstall --unused -y 2>/dev/null

    # 3. Heavy Dir Cleanup (node_modules)
    echo -e "\n\033[1;36m>>> Removing node_modules...\033[0m"
    if command -v fd >/dev/null 2>&1; then
        fd -H -t d node_modules "$HOME/Desktop/Projects" -x rm -rf
    else
        find "$HOME/Desktop/Projects" -name "node_modules" -type d -prune -exec rm -rf {} + 2>/dev/null
    fi

    # 4. Failed Services check
    echo -e "\n\033[1;36m>>> Checking for failed system services...\033[0m"
    systemctl --failed --no-legend

    echo -e "\n\033[1;32m🗑️  Deep cleanup completed.\033[0m"
else
    echo -e "\n\033[1;32m>>> [LIGHT] Skipping deep cleanup.\033[0m"
fi

# Orphaned Packages Check
orphans=$(pacman -Qdtq)
if [[ -n "$orphans" ]]; then
  echo -e "\n\033[1;33m⚠️  Orphaned packages detected:\033[0m"
  pacman -Qdt
  echo -e "\n\033[1;36mRemove them? [Y/n]\033[0m"
  read -r ans
  [[ $ans != "n" && $ans != "N" ]] && sudo pacman -Rs $orphans
fi

# 4) SECURITY CONTROLS
echo -e "\n\033[1;36m>>> Security Checks\033[0m"

# AppArmor
if command -v aa-status >/dev/null 2>&1; then
    enforce=$(aa-status 2>/dev/null | grep -c enforce || true)
    enforce=${enforce:-0}
    [ "$enforce" -gt 0 ] && echo "  ✅ AppArmor enforce count: $enforce" || echo "  ⚠️  AppArmor no enforce profile"
else
    echo "  ⚠️  AppArmor tools not found"
fi

# UFW & USBGuard
systemctl is-active -q ufw && echo "  ✅ UFW active" || echo "  ⚠️  UFW not active"
systemctl is-active -q usbguard && echo "  ✅ USBGuard active" || echo "  ⚠️  USBGuard not active"

# SSH
systemctl is-enabled sshd 2>/dev/null | grep -q masked && echo "  ✅ SSH service masked" || echo "  ⚠️  SSH service NOT masked"

# Get available space on root partition
root_available=$(df -h / | awk 'NR==2 {print $4}')
echo -e "\n\033[1;34m🗂️  Available space on '/' partition:\033[0m \033[1;32m$root_available\033[0m\n"

# === End of log ===
echo -e "\n===== UPDATE ENDED AT $(date) ====="

echo -e "\n\033[1;37;44m🎉 Update Process Completed! Logs: $LOG_FILE\033[0m\n"

# === Delete log files older than 30 days ===
find "$LOG_DIR" -type f -name "*.log" -mtime +30 -print -exec rm -f {} \;
