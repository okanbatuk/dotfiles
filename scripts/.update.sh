#!/bin/sh

# ----------------------------------------------------------
#  Script for Manjaro Update + Security
# ----------------------------------------------------------
#
# CLEAR ALL LINES
clear

# === Enable logging to a file ===
LOG_DIR=~/Desktop/.update-logs
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/update-$(date +%Y-%m-%d).log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo -e "\n\n===== UPDATE STARTED AT $(date) =====\n"

# ----------------------------------------------------------
# 1) SYSTEM UPDATE
# ----------------------------------------------------------
echo -e "\n>>> Updating mirrors and system packages..."
sudo pacman-mirrors --fasttrack 10
sudo pacman -Syyu --noconfirm
command -v yay >/dev/null 2>&1 && yay -Syu --noconfirm

# Flatpak & Snap
echo -e "\n>>> Updating Flatpak & Snap packages..."
flatpak update -y
command -v snap >/dev/null 2>&1 && sudo snap refresh

# ----------------------------------------------------------
# 2) JS / .NET TOOLING
# ----------------------------------------------------------
echo -e "\n>>> Installed .NET SDK versions:"
dotnet --list-sdks 2>/dev/null || echo "  .NET SDK not found"

echo -e "\n>>> Updating global bun..."
command -v bun >/dev/null 2>&1 && sudo bun upgrade

# ---------- user-global npm tooling ----------
if command -v npm >/dev/null 2>&1; then
  echo -e "\n>>> Updating user-global npm packages..."
  npm update -g
  npm cache clean --force --silent

  echo -e "\n>>> Checking for outdated user-global npm packages..."
  outdated=$(npm outdated -g --depth=0 | tail -n +2)
  if [ -n "$outdated" ]; then
    echo -e "\n\033[1;33m⚠️  Outdated user-global npm packages:\033[0m"
    echo "$outdated" | awk '{print "• " $1 " (Current: " $2 ", Latest: " $4 ")"}'
    echo -e "\n\033[1;36mTo update individually, run:\033[0m"
    echo "$outdated" | awk '{print "  npm install -g " $1"@"$4}'
  else
    echo -e "\033[1;32m✅ All user-global npm packages are up to date.\033[0m"
  fi
fi
# ----------------------------------------------------------
# 2-a) RUST TOOLING
# ----------------------------------------------------------
echo -e "\n>>> Updating rustup & Rust toolchain..."
if command -v rustup >/dev/null 2>&1; then
  rustup self update
  rustup update stable 2>&1 | tee -a "$LOG_FILE"
  rustup default stable
  echo -e "  \033[1;32m✅ Rust/Cargo versions:\033[0m $(rustc --version)  |  $(cargo --version)"
else
  echo -e "  \033[1;33m⚠️  rustup not found – skipping Rust update\033[0m"
fi

# ----------------------------------------------------------
# 3) CLEANUP
# ----------------------------------------------------------
echo -e "\n>>> Cleaning ~/.cache..."
du -sh ~/.cache 2>/dev/null || echo "0    ~/.cache"
rm -rf ~/.cache/*
sudo paccache -ruk0
flatpak uninstall --unused -y 2>/dev/null

# Projects node_modules
PROJECTS_DIR="$HOME/Desktop/Projects"
echo -e "\n>>> Removing all node_modules inside $PROJECTS_DIR (following symlinks)..."

time find -L "$HOME/Desktop/Projects" -type d -name node_modules -exec rm -rf {} + 2>/dev/null
echo -e "\033[1;32m🗑️  All node_modules under $PROJECTS_DIR have been removed.\033[0m"

orphans=$(pacman -Qdtq)
if [[ -n "$orphans" ]]; then
  echo -e "\n\033[1;33m⚠️  Orphaned packages detected:\033[0m"
  pacman -Qdt
  echo -e "\n\033[1;37mRemove them? [Y/n]\033[0m"
  read -r ans
  [[ $ans != "n" && $ans != "N" ]] && sudo pacman -Rs $orphans
fi

# ----------------------------------------------------------
# 4) SECURITY CONTROLS
# ----------------------------------------------------------
echo -e "\n\033[1;36m>>> Security Checks\033[0m"

# AppArmor (soft check)
if command -v aa-status >/dev/null 2>&1; then
  enforce=$(aa-status 2>/dev/null | grep -c enforce || true)
  enforce=$(( enforce + 0 ))               # boşsa 0 yap
  [ "$enforce" -gt 0 ] && echo "  ✅ AppArmor enforce count: $enforce" || echo "  ⚠️  AppArmor no enforce profile"
else
  echo "  ⚠️  AppArmor tools not found"
fi

# UFW
systemctl is-active -q ufw && echo "  ✅ UFW active" || echo "  ⚠️  UFW not active"

# USBGuard
systemctl is-active -q usbguard && echo "  ✅ USBGuard active" || echo "  ⚠️  USBGuard not active"

# SSH (should be masked)
if systemctl is-enabled sshd 2>/dev/null | grep -q masked; then
  echo "  ✅ SSH service masked"
else
  echo "  ⚠️  SSH service NOT masked"
fi

# ----------------------------------------------------------
# 5) ENDING
# ----------------------------------------------------------
echo -e "\n\033[1;36m>>> Disk usage summary after cleanup:\033[0m"
df -h /

# Get available space on root partition
root_available=$(df -h / | awk 'NR==2 {print $4}')
echo -e "\n\033[1;34m🗂️  Available space on '/' partition:\033[0m \033[1;32m$root_available\033[0m\n"

echo -e "\033[1;37;44m🎉 Update and Cleanup Completed Successfully!\033[0m"

# === End of log ===
echo -e "\n===== UPDATE ENDED AT $(date) =====\n"

# === Delete log files older than 30 days ===
find "$LOG_DIR" -type f -name "*.log" -mtime +30 -print -exec rm -f {} \;
