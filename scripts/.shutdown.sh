#!/bin/bash

set -e

# --- Functions ---
shutdown_now() {
  echo -e "\n✅ Cleanup complete. Shutting down in 5 seconds..."
  sleep 5
  sudo systemctl poweroff
}

stay_on() {
  echo -e "\n✅ Cleanup complete. System will stay on."
}

# CLEAR ALL LINES
clear

# --- Check Parameter ---
if [[ "$1" =~ ^[YyNn]$ ]]; then
  choice="$1"
else
  read -p "Do you want to shutdown after cleanup? (y/n): " choice
fi

echo "🔧 Starting cleanup before shutdown..."

# === Enable logging ===
LOG_DIR="$HOME/Desktop/.shutdown-logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/shutdown-cleanup-$(date +%Y-%m-%d).log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo -e "\n\n===== CLEANUP & SHUTDOWN STARTED AT $(date) =====\n"

# FLUSH FILESYSTEM CACHES
echo "🧠 Flushing filesystem cache..."
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

# VACUUM JOURNAL LOGS
echo "🧹 Vacuuming journal logs (keep last 2 days)..."
sudo journalctl --vacuum-time=2d

# CLEAN TEMP FILES
echo "🧹 Cleaning /tmp and /var/tmp..."
sudo rm -rf /tmp/* /var/tmp/* 2>/dev/null || true

# CLEAR USER CACHE (again, in case something re-added)
echo "🧹 Clearing user cache again..."
rm -rf ~/.cache/* 2>/dev/null || true

# CLEAN GNOME THUMBNAIL CACHE
echo "🖼️  Cleaning GNOME thumbnail cache..."
rm -rf ~/.cache/thumbnails/* 2>/dev/null || true

# REMOVE OLD PACKAGE CACHE
echo "📦 Removing old package cache (keep none)..."
sudo paccache -ruk0 2>/dev/null || true

# CLEAN AUR HELPER CACHE (yay / paru)
echo "📦 Cleaning AUR helper cache..."
rm -rf ~/.cache/yay 2>/dev/null || true
rm -rf ~/.cache/paru 2>/dev/null || true

# CLEAN DEV TOOL CACHES (npm / yarn / bun / pnpm)
echo "🧰 Cleaning dev tool caches..."
rm -rf ~/.npm 2>/dev/null || true
rm -rf ~/.cache/yarn 2>/dev/null || true
rm -rf ~/.pnpm-store 2>/dev/null || true
rm -rf ~/.bun/install/cache 2>/dev/null || true
rm -rf ~/.bun/cache 2>/dev/null || true
rm -rf ~/.cache/bun 2>/dev/null || true

# CLEAN FLATPAK ORPHAN PACKAGE
echo "📦 Cleaning unused Flatpak runtimes..."
flatpak uninstall --unused -y

# CLEAN FLATPAK CACHE
echo "📦 Cleaning Flatpak cache..."
rm -rf ~/.var/app/*/cache 2>/dev/null || true
sudo rm -rf /var/tmp/flatpak-cache/* 2>/dev/null || true

# DELETE OLD LOG FILES
echo "🗃️  Removing shutdown logs older than 30 days..."
find "$LOG_DIR" -type f -name "*.log" -mtime +30 -print -exec rm -f {} \;

# DECIDE TO SHUTDOWN OR NOT
if [[ "$choice" =~ ^[Yy]$ ]]; then
  shutdown_now
elif [[ "$choice" =~ ^[Nn]$ ]]; then
  stay_on
else
  echo -e "\n⚠ Invalid input. Assuming system stays on."
  stay_on
fi
