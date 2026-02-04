#!/bin/bash

# --- Setup logging ---
LOG_DIR="$HOME/Desktop/.disk-logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/disk-report-$(date +%Y-%m-%d_%H-%M-%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# --- Functions ---
report_disk_usage() {
    echo -e "\n📊 Top disk usage (home):"
    du -h --max-depth=2 ~ 2>/dev/null | sort -hr | head -n 15

    echo -e "\n📊 Top disk usage (/var & /home & /usr):"
    sudo du -h --max-depth=2 /var | sort -hr | head -n 15
    sudo du -h --max-depth=2 /home | sort -hr | head -n 15
    sudo du -h --max-depth=2 /usr | sort -hr | head -n 15

    echo -e "\n📊 Disk usage summary:"
    df -h /
}

check_disk_health() {
    echo -e "\n🛡️  Disk Health Check (S.M.A.R.T.):"

    # --- SSD (sda) ---
    SSD_STATUS=$(sudo smartctl -H /dev/sda | grep -i "test result" | awk -F: '{print $2}' | xargs)
    # Reallocated Sector: Fiziksel hasar var mı? (0 olmalı)
    SSD_BAD=$(sudo smartctl -A /dev/sda | grep "Reallocated_Sector_Ct" | awk '{print $10}')
    
    echo "  [SSD - sda] Status: $SSD_STATUS"
    if [ "$SSD_BAD" -eq 0 ]; then
        echo "  - Physical Condition: Perfect."
    else
        echo "  - ⚠️  WARNING: $SSD_BAD physical errors detected. Consider backing up your data."
    fi

    # --- HDD (sdb) ---
    HDD_STATUS=$(sudo smartctl -H /dev/sdb | grep -i "test result" | awk -F: '{print $2}' | xargs)
    # Pending Sector: HDD'nin okumakta zorlandığı can çekişen sektörler
    HDD_BAD=$(sudo smartctl -A /dev/sdb | grep "Reallocated_Sector_Ct" | awk '{print $10}')
    HDD_PENDING=$(sudo smartctl -A /dev/sdb | grep "Current_Pending_Sector" | awk '{print $10}')
    
    echo "  [HDD - sdb] Status: $HDD_STATUS"
    if [ "$HDD_BAD" -eq 0 ] && [ "$HDD_PENDING" -eq 0 ]; then
        echo "  - Physical Condition: Healthy (Aged but no errors)."
    else
        ERROR_TOTAL=$((HDD_BAD + HDD_PENDING))
        echo "  - ❌ DANGER: $ERROR_TOTAL physical issues detected! Disk failure might be imminent."
    fi
}

# DELETE OLD LOG FILES
delete_old_files() {
    echo "🗃️  Removing shutdown logs older than 7 days..."
    find "$LOG_DIR" -type f -name "*.log" -mtime +7 -print -exec rm -f {} \;
}
# --- Run ---
report_disk_usage
check_disk_health
delete_old_files

echo -e "\n✅ Disk report generated at $LOG_FILE"
