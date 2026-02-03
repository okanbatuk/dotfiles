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

    # DELETE OLD LOG FILES
    echo "🗃️  Removing shutdown logs older than 30 days..."
    find "$LOG_DIR" -type f -name "*.log" -mtime +30 -print -exec rm -f {} \;
}

# --- Run report ---
report_disk_usage
echo -e "\n✅ Disk report generated at $LOG_FILE"
