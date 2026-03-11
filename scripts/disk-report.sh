#!/bin/bash
# disk-report.sh - S.M.A.R.T. health analysis & storage usage reports
# Optimized with centralized core.sh logic and English documentation.

# --- Core Environment Import ---
# Using the streamlined import method leveraging .zshenv variables
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "$DOTFILES_DIR/core.sh" || { echo "Error: core.sh not found"; exit 1; }

# --- Setup logging ---
setup_env() {
    LOG_DIR_STORAGE="$LOG_DIR/storage"
    mkdir -p "$LOG_DIR_STORAGE" 2>/dev/null
    LOG_FILE="$LOG_DIR_STORAGE/disk-report-$(date +%Y-%m-%d_%H-%M-%S).log"

    # Fail-safe: Ensure the current user owns the log file if it was previously created by root
    [ -f "$LOG_FILE" ] && sudo chown "$REAL_USER":"$REAL_USER" "$LOG_FILE" 2>/dev/null

    # Redirect all output to both log file and terminal
    exec > >(tee -a "$LOG_FILE") 2>&1
    echo -e "${PURPLE}===== DISK REPORT STARTED AT $(date) =====${NC}"
}

# --- Functions ---

check_disk_health() {
    echo -e "\n${CYAN}🛡️  Disk Health Check (S.M.A.R.T.):${NC}"

    # SSD (sda) - Primary Drive
    if [ -b /dev/sda ]; then
        SSD_STATUS=$(sudo smartctl -H /dev/sda | grep -i "test result" | awk -F: '{print $2}' | xargs)
        SSD_BAD=$(sudo smartctl -A /dev/sda | grep "Reallocated_Sector_Ct" | awk '{print $10}')
        echo -e "  [SSD - sda] Status: ${GREEN}$SSD_STATUS${NC}"

        if [[ "$SSD_BAD" -eq 0 ]]; then
            echo -e "  - Physical: ${GREEN}Perfect (0 bad sectors).${NC}"
        else
            echo -e "  - ${RED}⚠️  WARNING: $SSD_BAD reallocated sectors detected!${NC}"
        fi
    fi

    # HDD (sdb) - Storage Drive
    if [ -b /dev/sdb ]; then
        HDD_STATUS=$(sudo smartctl -H /dev/sdb | grep -i "test result" | awk -F: '{print $2}' | xargs)
        echo -e "  [HDD - sdb] Status: ${GREEN}$HDD_STATUS${NC}"
    fi
}

report_disk_usage() {
    echo -e "\n${BLUE}📊 Top Disk Usage (Home: $REAL_HOME):${NC}"
    # Showing top 15 largest directories/files in home
    du -h --max-depth=2 "$REAL_HOME" 2>/dev/null | sort -hr | head -n 15

    echo -e "\n${BLUE}📊 System Partition Summary:${NC}"
    df -h /
}

delete_old_reports() {
    echo -e "\n${PURPLE}🗃️  Cleaning storage logs older than 30 days...${NC}"
    # Automated log rotation to prevent storage bloat
    find "$LOG_DIR_STORAGE" -type f -name "*.log" -mtime +30 -delete 2>/dev/null
}

# --- Main Execution ---
main() {
    setup_env
    check_disk_health
    report_disk_usage
    delete_old_reports

    echo -e "\n${GREEN}✅ Disk report generated successfully at:${NC}"
    echo -e "${YELLOW}$LOG_FILE${NC}"
}

main "$@"
