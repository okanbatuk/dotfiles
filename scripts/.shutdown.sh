#!/bin/bash

set -e

# --- Colors ---
BLUE='\033[1;34m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
PURPLE='\033[1;35m'
NC='\033[0m' # No Color

# --- Functions ---
shutdown_now() {
  echo -e "\n${GREEN}✅ Cleanup complete. Shutting down in 5 seconds...${NC}"
  sleep 5
  sudo systemctl poweroff
}

stay_on() {
  echo -e "\n${GREEN}✅ Cleanup complete. System will stay on.${NC}"
}

# CLEAR ALL LINES
clear

# --- Check Parameter ---
if [[ "$1" =~ ^[YyNn]$ ]]; then
  choice="$1"
else
  echo -e "${CYAN}❓ Do you want to shutdown after cleanup? (y/n):${NC} "
  read -r choice
fi

echo "🔧 Starting cleanup before shutdown..."

# === Enable logging ===
LOG_DIR="$HOME/dotfiles/logs/maintenance"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/shutdown-cleanup-$(date +%Y-%m-%d).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "\n${PURPLE}===== CLEANUP & SHUTDOWN STARTED AT $(date) =====${NC}\n"
echo -e "${YELLOW}🔧 Starting maintenance routine...${NC}"

# FLUSH FILESYSTEM CACHES
echo -e "${BLUE}🧠 Flushing filesystem cache...${NC}"
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

# VACUUM JOURNAL LOGS
echo -e "${BLUE}🧹 Vacuuming journal logs (keep last 2 days)...${NC}"
sudo journalctl --vacuum-time=2d

# CLEAN TEMP FILES
echo -e "${BLUE}🧹 Cleaning /tmp and /var/tmp...${NC}"
sudo rm -rf /tmp/* /var/tmp/* 2>/dev/null || true

# CLEAR USER CACHE (again, in case something re-added)
echo -e "${BLUE}🧹 Clearing user & GNOME thumbnail cache...${NC}"
rm -rf ~/.cache/* 2>/dev/null || true
rm -rf ~/.cache/thumbnails/* 2>/dev/null || true

# REMOVE OLD PACKAGE CACHE
echo -e "${BLUE}📦 Cleaning package & AUR helper caches...${NC}"
sudo paccache -rk 2 2>/dev/null || true
rm -rf ~/.cache/yay 2>/dev/null || true
rm -rf ~/.cache/paru 2>/dev/null || true

# CLEAN DEV TOOL CACHES (npm / yarn / bun / pnpm)
echo -e "${BLUE}🧰 Cleaning dev tool caches (npm, bun, pnpm, yarn)...${NC}"
rm -rf ~/.npm 2>/dev/null || true
rm -rf ~/.cache/yarn 2>/dev/null || true
rm -rf ~/.pnpm-store 2>/dev/null || true
rm -rf ~/.bun/install/cache 2>/dev/null || true
rm -rf ~/.bun/cache 2>/dev/null || true
rm -rf ~/.cache/bun 2>/dev/null || true

# CLEAN FLATPAK ORPHAN PACKAGE
echo -e "${BLUE}📦 Cleaning Flatpak unused runtimes & cache...${NC}"
flatpak uninstall --unused -y 2>/dev/null || true
rm -rf ~/.var/app/*/cache 2>/dev/null || true
sudo rm -rf /var/tmp/flatpak-cache/* 2>/dev/null || true

# DELETE OLD LOG FILES
echo -e "${PURPLE}🗃️  Removing maintenance logs older than 30 days...${NC}"
if command -v fd >/dev/null 2>&1; then
    fd -t f -e log --changed-before 30d . "$LOG_DIR" -x rm -v
else
    find "$LOG_DIR" -type f -name "*.log" -mtime +30 -print -exec rm -f {} \;
fi

# DECIDE TO SHUTDOWN OR NOT
if [[ "$choice" =~ ^[Yy]$ ]]; then
  shutdown_now
elif [[ "$choice" =~ ^[Nn]$ ]]; then
  stay_on
else
  echo -e "\n${RED}⚠️  Invalid input. Assuming system stays on.${NC}"
  stay_on
fi
