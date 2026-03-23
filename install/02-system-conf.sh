#!/bin/bash
# 02-system-config.sh - Handles dynamic systemd unit linking and automated activation
# Optimized for backend performance and Infrastructure as Code (IaC) principles.

set -e # Exit on any error

# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_DIR/../core.sh" || { source "$CORE_DIR/core.sh" 2>/dev/null || exit 1; }

SYSTEMD_CONF_DIR="$DOTFILES_DIR/config/systemd"
SYSTEMD_TARGET_DIR="/etc/systemd/system"
GRUB_CONFIG="/etc/default/grub"

log_info "Starting dynamic systemd configuration..."

# --- Container Guard ---
# systemd and GRUB are not available in Docker/container environments.
# Detect by checking if systemd is PID 1 — if not, skip gracefully.
if [ ! -d /run/systemd/system ]; then
    log_warn "⚠️  Container environment detected (systemd not available). Skipping systemd and GRUB configuration."
    log_info "✅ System configuration task finished (skipped for container)."
    exit 0
fi

# --- 1. Dynamic Symlinking ---
# Link all files (services, timers, path units) from dotfiles to /etc
log_debug "Synchronizing all systemd units from $SYSTEMD_CONF_DIR..."
if [ -d "$SYSTEMD_CONF_DIR" ]; then
    log_info "Linking all units from $SYSTEMD_CONF_DIR..."
    for unit_path in "$SYSTEMD_CONF_DIR"/*; do
        [ -e "$unit_path" ] || continue
        unit_name=$(basename "$unit_path")

        ln -sf "$unit_path" "$SYSTEMD_TARGET_DIR/$unit_name"
        log_debug "Linked: $unit_name"
    done
else
    log_error "Source directory $SYSTEMD_CONF_DIR not found!"
    exit 1
fi

# Reload systemd to recognize new symlinks
systemctl daemon-reload

# --- 2. Intelligent Activation ---
log_info "Activating system units..."

# Enable all .timer units dynamically to ensure scheduled tasks are active
for timer in "$SYSTEMD_CONF_DIR"/*.timer; do
    [ -e "$timer" ] || continue
    timer_name=$(basename "$timer")
    systemctl enable "$timer_name"
    log_debug "Enabled timer: $timer_name"
done

# Enable specific services that must run at boot
# Note: We enable mount-ldm because it's required for disk availability
# For other services, we decide if they need 'enable' (at boot) or 'start' (now)
SERVICES_TO_ENABLE=("mount-ldm.service")

for svc in "${SERVICES_TO_ENABLE[@]}"; do
    if [ -f "$SYSTEMD_TARGET_DIR/$svc" ]; then
        systemctl enable "$svc"
        log_debug "Enabled service: $svc"
    fi
done

# Start the timers immediately to ensure they are tracking schedules
systemctl start update-light.timer update-full.timer 2>/dev/null || true

# --- 3. GRUB & Performance Tuning ---
log_info "Optimizing GRUB for zero-wait boot..."
if [ -f "$GRUB_CONFIG" ]; then
    # Set timeout to 0 for instant boot sequence
    sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' "$GRUB_CONFIG"

    # Apply silent boot and performance parameters
    PERF_CMD="quiet loglevel=3 noplymouth apparmor=1 security=apparmor udev.log_priority=3"
    sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$PERF_CMD\"|" "$GRUB_CONFIG"

    update-grub
    log_info "✅ GRUB optimized."
fi

# --- 4. Permissions ---
# Ensure the backend script for mounting is executable
[ -f "$DOTFILES_DIR/scripts/mount.sh" ] && chmod +x "$DOTFILES_DIR/scripts/mount.sh"

log_info "✅ System configuration task finished."
