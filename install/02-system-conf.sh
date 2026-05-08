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

# --- 1. Systemd Unit Orchestration ---
# Link all files (services, timers, path units) from dotfiles to /etc
setup_systemd_units() {
    log_info "🔗 Linking and activating systemd units..."

    if [ -d "$SYSTEMD_CONF_DIR" ]; then
        for unit_path in "$SYSTEMD_CONF_DIR"/*; do
            [ -e "$unit_path" ] || continue
            unit_name=$(basename "$unit_path")

            # Create symlink in /etc/systemd/system
            ln -sf "$unit_path" "$SYSTEMD_TARGET_DIR/$unit_name"
            log_debug "Linked: $unit_name"
        done

        # Reload systemd to recognize new symlinks
        systemctl daemon-reload
    else
        log_warn "⚠️  Systemd config directory not found: $SYSTEMD_CONF_DIR"
        exit 1
    fi
}

# --- 2. Service & Timer Activation ---
# Enable all .timer units dynamically to ensure scheduled tasks are active
enable_core_services() {
    log_info "🚀 Enabling core system services and timers..."

    # Enable all timers found in the config
    for timer in "$SYSTEMD_CONF_DIR"/*.timer; do
        [ -e "$timer" ] || continue
        timer_name=$(basename "$timer")
        systemctl enable --now "$timer_name" 2>/dev/null || true
        log_debug "Enabled timer: $timer_name"
    done

    # Specific services that must run at boot
    local SERVICES=("mount-ldm.service")
    for svc in "${SERVICES[@]}"; do
        if [ -f "$SYSTEMD_TARGET_DIR/$svc" ]; then
            systemctl enable --now "$svc"
            log_debug "Enabled: $svc"
        fi
    done

    # Start the timers immediately to ensure they are tracking schedules
    systemctl start update-light.timer update-full.timer 2>/dev/null || true
}

# --- 3. syncthing integration ---
setup_syncthing() {
    log_info "🔄 configuring syncthing (user service)..."

    # check if syncthing binary exists (from 01-system.sh)
    if command -v syncthing &>/dev/null; then
        # enable and start syncthing as a user service (best for gnome/home sync)
        if sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$REAL_USER")/bus" \
           systemctl --user is-enabled syncthing.service &>/dev/null; then
            log_debug "✅ Syncthing service is already active."
        else
            sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$REAL_USER")/bus" \
                systemctl --user enable --now syncthing.service

            log_success "🚀 Syncthing user service started."
            log_info "🔗 Syncthing GUI: ${BLUE}http://localhost:8384${NC} (Pair your devices here)"
            send_notification "Syncthing" "P2P Synchronization service is now active." "normal" "syncthing"
        fi
    else
        log_error "❌ syncthing package not found. ensure 01-system.sh ran correctly."
        exit 1
    fi
}

# --- 4. GRUB & Performance Tuning ---
optimize_boot() {
    log_info "🏎️  Optimizing GRUB performance..."

    if [ -f "$GRUB_CONFIG" ]; then
        # Instant boot
        sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' "$GRUB_CONFIG"

        # Performance & Silent boot parameters
        local PERF_CMD="quiet loglevel=3 noplymouth apparmor=1 security=apparmor udev.log_priority=3"
        sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$PERF_CMD\"|" "$GRUB_CONFIG"

        # Update GRUB only if changes were made (idempotent check can be added if needed)
        update-grub
        log_success "✅ GRUB optimized for speed and silence."
    fi
}

# --- Main Execution ---
main() {
    log_info "Starting Modular System Configuration..."

    # Container Guard
    # systemd and GRUB are not available in Docker/container environments.
    # Detect by checking if systemd is PID 1 — if not, skip gracefully.
    if [ ! -d /run/systemd/system ]; then
        log_warn "⚠️  Container environment detected. Skipping systemd/GRUB tasks."
        exit 0
    fi

    setup_systemd_units
    enable_core_services
    setup_syncthing
    optimize_boot

    # Ensure the backend script for mounting is executable
    [ -f "$DOTFILES_DIR/scripts/mount.sh" ] && chmod +x "$DOTFILES_DIR/scripts/mount.sh"

    log_info "✅ System configuration completed successfully."
}

main "$@"
