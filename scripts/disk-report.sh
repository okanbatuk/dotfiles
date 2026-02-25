#!/bin/bash
# disk-report.sh - Updated with core.sh integration

# --- Core Environment Import ---
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

CORE_ENV="$(dirname "$SCRIPT_DIR")/core.sh"
source "$CORE_ENV" 2>/dev/null || { echo "Error: core.sh not found"; exit 1; }

# --- Setup logging ---
LOG_DIR_STORAGE="$LOG_DIR/storage"
mkdir -p "$LOG_DIR_STORAGE"
LOG_FILE="$LOG_DIR_STORAGE/disk-report-$(date +%Y-%m-%d_%H-%M-%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# --- Functions ---
check_disk_health() {
    echo -e "\n${CYAN}🛡️  Disk Health Check (S.M.A.R.T.):${NC}"

    # SSD (sda)
    if [ -b /dev/sda ]; then
        SSD_STATUS=$(sudo smartctl -H /dev/sda | grep -i "test result" | awk -F: '{print $2}' | xargs)
        SSD_BAD=$(sudo smartctl -A /dev/sda | grep "Reallocated_Sector_Ct" | awk '{print $10}')
        echo -e "  [SSD - sda] Status: ${GREEN}$SSD_STATUS${NC}"
        [[ "$SSD_BAD" -eq 0 ]] && echo -e "  - Physical: ${GREEN}Perfect.${NC}" || echo -e "  - ${YELLOW}⚠️  WARNING: $SSD_BAD errors!${NC}"
    fi

    # HDD (sdb)
    if [ -b /dev/sdb ]; then
        HDD_STATUS=$(sudo smartctl -H /dev/sdb | grep -i "test result" | awk -F: '{print $2}' | xargs)
        echo -e "  [HDD - sdb] Status: ${GREEN}$HDD_STATUS${NC}"
    fi
}

report_disk_usage() {
    echo -e "\n${BLUE}📊 Top disk usage (home - $REAL_HOME):${NC}"
    du -h --max-depth=2 "$REAL_HOME" 2>/dev/null | sort -hr | head -n 15

    echo -e "\n${BLUE}📊 Disk usage summary:${NC}"
    df -h /
}

delete_old_files() {
    echo -e "\n${PURPLE}🗃️  Cleaning storage logs older than 30 days...${NC}"
    find "$LOG_DIR_STORAGE" -type f -name "*.log" -mtime +30 -delete 2>/dev/null
}

# --- Run ---
check_disk_health
report_disk_usage
delete_old_files

echo -e "\n${GREEN}✅ Disk report generated at $LOG_FILE${NC}"
