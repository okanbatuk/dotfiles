#!/bin/bash

# --- Fonksiyonlar ---
shutdown_now() {
  echo -e "\n✅ Cleanup complete. Shutting down in 5 seconds..."
  sleep 5
  systemctl poweroff
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
sudo rm -rf /tmp/* /var/tmp/*

# CLEAR USER CACHE (again, in case something re-added)
echo "🧹 Clearing user cache again..."
rm -rf ~/.cache/*

# REMOVE OLD PACKAGE CACHE
echo "📦 Removing old package cache (keep none)..."
sudo paccache -ruk0

# CLEAN SNAP
echo "📦 Cleaning Snap cache..."
sudo rm -rf /var/lib/snapd/cache/*

# DELETE OLD LOG FILES
echo "🗃️  Removing shutdown logs older than 30 days..."
find "$LOG_DIR" -type f -name "*.log" -mtime +30 -print -exec rm -f {} \;

# REPORT DISK USAGE
echo "📊 Disk usage before shutdown:"
df -h /

# DECIDE TO SHUTDOWN OR NOT
if [[ "$choice" =~ ^[Yy]$ ]]; then
  shutdown_now
elif [[ "$choice" =~ ^[Nn]$ ]]; then
  stay_on
else
  echo -e "\n⚠ Invalid input. Assuming system stays on."
  stay_on
fi
