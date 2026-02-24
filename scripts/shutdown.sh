#!/bin/bash
# shutdown.sh - System maintenance and cleanup before poweroff

set -e
clear

# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_ENV="$CORE_DIR/../core.sh"

if [ -f "$CORE_ENV" ]; then
    source "$CORE_ENV"
else
    source "$CORE_DIR/core.sh" 2>/dev/null || { echo "Error: core.sh not found"; exit 1; }
fi

# --- Functions ---
shutdown_now() {
  echo -e "\n${GREEN}✅ Cleanup complete. Shutting down in 5 seconds...${NC}"
  sleep 5
  sudo systemctl poweroff
}

stay_on() {
  echo -e "\n${GREEN}✅ Cleanup complete. System will stay on.${NC}"
}

# --- Check Parameter ---
if [[ "$1" =~ ^[YyNn]$ ]]; then
  choice="$1"
else
  echo -e "${CYAN}❓ Do you want to shutdown after cleanup? (y/n):${NC} "
  read -r choice
fi

echo -e "${YELLOW}🔧 Starting cleanup routine for user: $REAL_USER...${NC}"

# === Enable logging ===
LOG_DIR_MAINT="$LOG_DIR/maintenance"
mkdir -p "$LOG_DIR_MAINT"
LOG_FILE="$LOG_DIR_MAINT/shutdown-cleanup-$(date +%Y-%m-%d).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "\n${PURPLE}===== CLEANUP & SHUTDOWN STARTED AT $(date) =====${NC}\n"

# 1. FLUSH FILESYSTEM CACHES
echo -e "${BLUE}🧠 Flushing filesystem cache...${NC}"
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

# 2. VACUUM JOURNAL LOGS
echo -e "${BLUE}🧹 Vacuuming journal logs (keep last 2 days)...${NC}"
sudo journalctl --vacuum-time=2d

# 3. CLEAN TEMP FILES
echo -e "${BLUE}🧹 Cleaning /tmp and /var/tmp...${NC}"
sudo rm -rf /tmp/* /var/tmp/* 2>/dev/null || true

# 4. SCREENSHOT CLEANUP
if [ -d "$SS_DIR" ]; then
  echo -e "${BLUE}🧹 Cleaning old screenshots in $SS_DIR (older than 24h)...${NC}"
  find "$SS_DIR" -type f -name "Screenshot*" -mmin +1440 -delete
else
  echo -e "${RED}>>> Screenshot directory not found: $SS_DIR. Skipping.${NC}"
fi

# 5. CLEAR USER CACHE
echo -e "${BLUE}🧹 Clearing user & GNOME thumbnail cache...${NC}"
rm -rf "$REAL_HOME/.cache"/* 2>/dev/null || true

# 6. REMOVE PACKAGE CACHE
echo -e "${BLUE}📦 Cleaning package & AUR helper caches...${NC}"
sudo paccache -rk 2 2>/dev/null || true
sudo pamac clean --keep 2 2>/dev/null || true
rm -rf "$REAL_HOME/.cache/yay" 2>/dev/null || true
rm -rf "$REAL_HOME/.cache/paru" 2>/dev/null || true

# 7. CLEAN DEV TOOL CACHES
echo -e "${BLUE}🧰 Cleaning dev tool caches (npm, bun, pnpm, yarn)...${NC}"
rm -rf "$REAL_HOME/.npm" 2>/dev/null || true
rm -rf "$REAL_HOME/.pnpm-store" 2>/dev/null || true
rm -rf "$REAL_HOME/.cache/yarn" 2>/dev/null || true
rm -rf "$REAL_HOME/.bun/install/cache" 2>/dev/null || true
rm -rf "$REAL_HOME/.cache/bun" 2>/dev/null || true

# 8. CLEAN FLATPAK
echo -e "${BLUE}📦 Cleaning Flatpak unused runtimes & app cache...${NC}"
flatpak uninstall --unused -y 2>/dev/null || true
rm -rf "$REAL_HOME/.var/app"/*/cache 2>/dev/null || true

# 9. DELETE CUSTOM SESSION LOGS
CUSTOM_LOG_DIR="$LOG_DIR/custom"
if [ -d "$CUSTOM_LOG_DIR" ]; then
    echo -e "${PURPLE}🧹 Wiping custom session logs...${NC}"
    rm -rf "$CUSTOM_LOG_DIR"
    echo -e "${GREEN}✅ Custom logs directory removed.${NC}"
fi

# 10. DELETE OLD MAINTENANCE LOGS (30 Days)
echo -e "${PURPLE}🗃️  Removing maintenance logs older than 30 days...${NC}"
if command -v fd >/dev/null 2>&1; then
    fd -t f -e log --changed-before 30d . "$LOG_DIR_MAINT" -x rm -v
else
    find "$LOG_DIR_MAINT" -type f -name "*.log" -mtime +30 -delete
fi

# --- DECIDE TO SHUTDOWN ---
if [[ "$choice" =~ ^[Yy]$ ]]; then
  shutdown_now
else
  stay_on
fi
