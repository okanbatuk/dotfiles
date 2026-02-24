#!/bin/bash
# update.sh - Smart update system with core integration

clear
# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_ENV="$CORE_DIR/../core.sh"

if [ -f "$CORE_ENV" ]; then
    source "$CORE_ENV"
else
    # Fallback to current dir if not in scripts/
    source "$CORE_DIR/core.sh" 2>/dev/null || { echo "Error: core.sh not found"; exit 1; }
fi

# 0) HANDLE FLAGS
MODE="light"
INFO_MODE="--light"
[[ "$1" == "--full" ]] && INFO_MODE="--full" && MODE="full"

# === Enable logging ===
LOG_DIR_UPDATES="$LOG_DIR/updates"
mkdir -p "$LOG_DIR_UPDATES"
LOG_FILE="$LOG_DIR_UPDATES/update-$(date +%Y-%m-%d)-$MODE.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "\n${PURPLE}===== UPDATE STARTED AT $(date) [Mode: $MODE] =====${NC}"

# 1) SYSTEM UPDATE
if [[ "$INFO_MODE" == "--full" ]]; then
    echo -e "\n${BLUE}>>> [$MODE] Deep maintenance in progress...${NC}"

    # Mirror & Database Sync
    sudo pacman-mirrors --fasttrack 10
fi

echo -e "\n${GREEN}>>> Updating system packages (Pacman & Yay)...${NC}"
sudo pacman -Syyu --noconfirm
command -v yay >/dev/null 2>&1 && yay -Syu --noconfirm

echo -e "\n${GREEN}>>> Updating Flatpak...${NC}"
flatpak update -y

# 2) TOOLING (Bun & Rust & Npm & SDKMAN!)
echo -e "\n${GREEN}>>> Updating Bun...${NC}"
command -v bun >/dev/null 2>&1 && bun upgrade
echo -e "  ${GREEN}✅ 2.1 Bun updated.${NC}"

echo -e "\n${GREEN}>>> Updating Rustup & Toolchain...${NC}"
if command -v rustup >/dev/null 2>&1; then
    rustup update stable
    rustup default stable
    echo -e "  ${GREEN}✅ 2.2 Rust updated.${NC}"
fi

if command -v npm >/dev/null 2>&1; then
    echo -e "\n${GREEN}>>> Updating user-global npm packages...${NC}"
    npm install -g npm@latest --silent
    npm update -g
    npm cache verify
    echo -e "  ${GREEN}✅ 2.3 NPM update process completed.${NC}"
fi

if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    echo -e "\n${GREEN}>>> Updating SDKMAN!...${NC}"
    source "$SDKMAN_DIR/bin/sdkman-init.sh"

    sdk selfupdate
    sdk update

    if [[ "$INFO_MODE" == "--full" ]]; then
        echo -e "\n${BLUE}>>> [$MODE] Upgrading SDKMAN candidates (Java, Maven, etc.)...${NC}"
        export sdkman_auto_answer=true
        sdk upgrade
    fi
    echo -e "  ${GREEN}✅ 2.4 SDKMAN! update process completed.${NC}"
fi

# 3) CLEANUP
if [[ "$INFO_MODE" == "--full" ]]; then
    echo -e "\n${BLUE}>>> [$MODE] Deep cleanup (~/.cache, flatpak, node_modules) in progress...${NC}"

    # 1. Package Cache Cleanup
    echo -e "\n${CYAN}>>> Cleaning package cache...${NC}"
    # $REAL_HOME kullanarak sudo altındaki yanlış silmeyi önlüyoruz
    du -sh "$REAL_HOME/.cache" 2>/dev/null || echo "0    $REAL_HOME/.cache"
    rm -rf "$REAL_HOME/.cache"/* 2>/dev/null || true
    sudo paccache -rk 2

    # 2. Unused Flatpaks
    echo -e "\n${CYAN}>>> Removing unused Flatpak runtimes...${NC}"
    flatpak uninstall --unused -y 2>/dev/null || true

    # 3. Heavy Dir Cleanup (node_modules)
    echo -e "\n${CYAN}>>> Removing node_modules in projects...${NC}"
    PROJECTS_DIR="$REAL_HOME/Desktop/Projects"
    if [ -d "$PROJECTS_DIR" ]; then
        if command -v fd >/dev/null 2>&1; then
            fd -H -t d node_modules "$PROJECTS_DIR" -x rm -rf
        else
            find "$PROJECTS_DIR" -name "node_modules" -type d -prune -exec rm -rf {} + 2>/dev/null
        fi
    fi

    # 4. Failed service check
    echo -e "\n${CYAN}>>> Checking for failed services...${NC}"
    failed_system=$(systemctl --failed --no-legend)
    if [[ -n "$failed_system" ]]; then
        echo -e "${RED}❌ Failed SYSTEM services:${NC}\n$failed_system"
        sudo systemctl reset-failed
    else
        echo -e "${GREEN}✅ No failed system services.${NC}"
    fi

    echo -e "\n${GREEN}🗑️  Deep cleanup completed.${NC}"
else
    echo -e "\n${GREEN}>>> [LIGHT] Skipping deep cleanup.${NC}"
fi

# Orphaned Packages
orphans=$(pacman -Qdtq)
if [[ -n "$orphans" ]]; then
  echo -e "\n${YELLOW}⚠️  Orphaned packages detected, removing...${NC}"
  sudo pacman -Rs $orphans --noconfirm
else
  echo -e "\n${GREEN}✅ No orphaned packages to clean.${NC}"
fi

# 4) SECURITY CONTROLS
echo -e "\n${CYAN}>>> Security Checks${NC}"
systemctl is-active -q ufw && echo -e "  ${GREEN}✅ UFW active${NC}" || echo -e "  ${YELLOW}⚠️  UFW not active${NC}"
systemctl is-active -q usbguard && echo -e "  ${GREEN}✅ USBGuard active${NC}" || echo -e "  ${YELLOW}⚠️  USBGuard not active${NC}"
systemctl is-enabled sshd 2>/dev/null | grep -q masked && echo -e "  ${GREEN}✅ SSH service masked${NC}" || echo -e "  ${YELLOW}⚠️  SSH service NOT masked${NC}"

# Space check
root_available=$(df -h / | awk 'NR==2 {print $4}')
echo -e "\n${BLUE}🗂️  Available space on '/' partition:${NC} ${GREEN}$root_available${NC}\n"

echo -e "${PURPLE}===== UPDATE ENDED AT $(date) =====${NC}"
echo -e "\n${BLUE}🎉 Update Process Completed! Logs: $LOG_FILE${NC}\n"

# 5) AUTO-ROTATE LOGS (30 Days)
find "$LOG_DIR_UPDATES" -type f -name "*.log" -mtime +30 -delete
