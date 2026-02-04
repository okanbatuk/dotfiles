#!/bin/bash

# --- Setup logging ---
LOG_DIR="$HOME/dotfiles/logs/storage"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/disk-report-$(date +%Y-%m-%d_%H-%M-%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# --- Functions ---
# Disk Health
check_disk_health() {
    echo -e "\n\033[1;36m🛡️  Disk Health Check (S.M.A.R.T.):\033[0m"

    # --- SSD (sda) ---
    SSD_STATUS=$(sudo smartctl -H /dev/sda | grep -i "test result" | awk -F: '{print $2}' | xargs)
    SSD_BAD=$(sudo smartctl -A /dev/sda | grep "Reallocated_Sector_Ct" | awk '{print $10}')
    
    echo -e "  [SSD - sda] Status: \033[1;32m$SSD_STATUS\033[0m"
    if [ "$SSD_BAD" -eq 0 ]; then
        echo -e "  - Physical Condition: \033[1;32mPerfect.\033[0m"
    else
        echo -e "  - \033[1;33m⚠️  WARNING: $SSD_BAD physical errors detected. Consider backing up your data.\033[0m"
    fi

    # --- HDD (sdb) ---
    HDD_STATUS=$(sudo smartctl -H /dev/sdb | grep -i "test result" | awk -F: '{print $2}' | xargs)
    HDD_BAD=$(sudo smartctl -A /dev/sdb | grep "Reallocated_Sector_Ct" | awk '{print $10}')
    HDD_PENDING=$(sudo smartctl -A /dev/sdb | grep "Current_Pending_Sector" | awk '{print $10}')
    
    echo -e "  [HDD - sdb] Status: \033[1;32m$HDD_STATUS\033[0m"
    if [ "$HDD_BAD" -eq 0 ] && [ "$HDD_PENDING" -eq 0 ]; then
        echo -e "  - Physical Condition: \033[1;32mHealthy (Aged but no errors).\033[0m"
    else
        ERROR_TOTAL=$((HDD_BAD + HDD_PENDING))
        echo -e "  - \033[1;31m❌ DANGER: $ERROR_TOTAL physical issues detected! Disk failure might be imminent.\033[0m"
    fi
}

# Show disk usage
report_disk_usage() {
    echo -e "\n\033[1;34m📊 Top disk usage (home):\033[0m"
    du -h --max-depth=2 ~ 2>/dev/null | sort -hr | head -n 15

    echo -e "\n\033[1;34m📊 Top disk usage (/var & /home & /usr):\033[0m"
    sudo du -h --max-depth=2 /var | sort -hr | head -n 5
    sudo du -h --max-depth=2 /home | sort -hr | head -n 5
    sudo du -h --max-depth=2 /usr | sort -hr | head -n 5

    echo -e "\n\033[1;34m📊 Disk usage summary:\033[0m"
    df -h /
}

# Delete Old Log Files
delete_old_files() {
    echo -e "\n\033[1;35m🗃️  Cleaning logs older than 7 days using fd...\033[0m"
    
    if command -v fd >/dev/null 2>&1; then
        # fd ile 7 günden eski (older than 7 days) dosyaları bul ve sil
        fd --type f --extension log --changed-before 7d . "$LOG_DIR" -x rm -v
    else
        # Yedek olarak find (fd kurulu değilse patlamasın)
        find "$LOG_DIR" -type f -name "*.log" -mtime +7 -print -delete
    fi
}
# --- Run ---
check_disk_health
report_disk_usage
delete_old_files

echo -e "\n\033[1;32m✅ Disk report generated at $LOG_FILE\033[0m"
