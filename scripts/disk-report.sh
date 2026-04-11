#!/bin/bash
# disk-report.sh - S.M.A.R.T. health analysis & storage usage reports
# Optimized with centralized core.sh logic and English documentation.

# --- Core Environment Import ---
# Using the streamlined import method leveraging .zshenv variables
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "$DOTFILES_DIR/core.sh" || { echo "Error: core.sh not found"; exit 1; }

# --- Setup logging ---
setup_env() {
    # 1. Create a unique timestamp for the file name (Year-Month-Day_Hour-Minute-Second)
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

    # 2. Build the dynamic log name
    local log_name="disk-report-${timestamp}.log"

    # Initialize storage log directory and file
    prepare_logging "storage" "$log_name"

    # Redirect all output to both log file and terminal
    exec > >(tee -a "$CURRENT_LOG_FILE") 2>&1
    log_info "===== DISK REPORT STARTED AT $(date) ====="
}

# --- Functions ---

check_disk_health() {
    log_info "🛡️  Analyzing Physical Disk Health (S.M.A.R.T.)..."

    # Identify all physical disks (excluding partitions, loop devices, and rom)
    local disks=$(lsblk -dno NAME,TYPE | grep "disk" | awk '{print $1}')

    for dev in $disks; do
        local dev_path="/dev/$dev"
        local model=$(lsblk -dno MODEL "$dev_path")

        log_info "Analyzing device: $dev_path [$model]"

        # Validate S.M.A.R.T. capability and health status
        if sudo smartctl -H "$dev_path" > /dev/null 2>&1; then
            local status=$(sudo smartctl -H "$dev_path" | grep -i "test result" | awk -F: '{print $2}' | xargs)
            echo -e "  - Overall Health Status: ${GREEN}$status${NC}"

            # Check for Reallocated Sectors (Critical for SATA SSD/HDD longevity)
            if sudo smartctl -A "$dev_path" | grep -q "Reallocated_Sector_Ct"; then
                local bad_sectors=$(sudo smartctl -A "$dev_path" | grep "Reallocated_Sector_Ct" | awk '{print $10}')
                if [[ "$bad_sectors" -eq 0 ]]; then
                    echo -e "  - Surface Condition: ${GREEN}Perfect (0 bad sectors)${NC}"
                else
                    log_warn "⚠️  WARNING: $bad_sectors reallocated sectors detected on $dev_path!"
                fi
            fi
        else
            log_error "Failed to retrieve S.M.A.R.T. data for $dev_path. Ensure drive supports S.M.A.R.T."
        fi
    done
}

report_disk_usage() {
    log_info "📊 Top Disk Usage (Home: $REAL_HOME):"
    # Display top 15 largest directories/files in the home directory
    du -h --max-depth=2 "$REAL_HOME" 2>/dev/null | sort -hr | head -n 15

    log_info "📊 System Partition Summary:"
    df -h /
}

# --- Main Execution ---
main() {
    setup_env
    check_disk_health
    report_disk_usage

    # Rotation is handled globally by prepare_logging in core.sh,
    # but specific directory cleanup can be added here if needed.

    log_info "===== DISK REPORT GENERATED SUCCESSFULLY ====="
    log_info "Log location: ${YELLOW}$CURRENT_LOG_FILE${NC}"
}

main "$@"
