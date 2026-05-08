#!/usr/bin/env bash
# ~/dotfiles/install/10-ufw-setup.sh

# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_DIR/../core.sh" || { source "$CORE_DIR/core.sh" 2>/dev/null || exit 1; }

# Global VPN Toggle (Default: false)
IS_VPN_ACTIVE=false

# Root check
if [[ $EUID -ne 0 ]]; then
   log_error "UFW setup must be run as root (use sudo)."
   exit 1
fi

log_info "Initializing UFW Security Stack..."

# 1. Reset to Secure Defaults
# Reset işlemi mevcut tüm kuralları siler ve firewall'u kapatır
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# 2. Dynamic Rule Parsing from hints/
RULES_FILE="$DOTFILES_DIR/hints/ufw_rules.txt"

if [[ -f "$RULES_FILE" ]]; then
    log_debug "Parsing rules from $RULES_FILE"

    # Extract VPN variables from file
    VPN_IFACE=$(grep "vpn_interface" "$RULES_FILE" | awk '{print $2}')
    VPN_EP=$(grep "vpn_endpoint" "$RULES_FILE" | awk '{print $2}')
    VPN_PORT=$(grep "vpn_port" "$RULES_FILE" | awk '{print $2}')

    # Activate VPN logic if variables are non-empty
    [[ -n "$VPN_IFACE" && -n "$VPN_EP" && -n "$VPN_PORT" ]] && IS_VPN_ACTIVE=true

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments, empty lines, and vpn_ config lines
        [[ "$line" =~ ^#.*$ || -z "$line" || "$line" =~ ^vpn_ ]] && continue

        if [[ "$line" == allow_in_on* ]]; then
            # Translate allow_in_on to ufw syntax
            # Etc: allow_in_on wlp3s0 from 192.168.1.0/24 -> ufw allow in on wlp3s0 from ...
            cmd=$(echo "$line" | sed 's/_/ /g')
            ufw $cmd
        else
            ufw $line
        fi
    done < "$RULES_FILE"
else
    log_warn "Rules file not found at $RULES_FILE. Using default deny policy."
    # Fallback: Only allow local network
    ufw allow in on wlp3s0 from 192.168.1.0/24
    ufw allow in on eth0 from 192.168.1.0/24
fi

# 3. VPN Specific Enforcement (Kill-Switch Logic)
if [ "$IS_VPN_ACTIVE" = true ]; then
    log_info "VPN detected: Applying rules for $VPN_IFACE ($VPN_EP:$VPN_PORT)"

    # VPN Handshake ve Interface izinleri
    ufw allow out to "$VPN_EP" port "$VPN_PORT" proto udp
    ufw allow in on "$VPN_IFACE"
    ufw allow out on "$VPN_IFACE"
else
    log_info "Standard firewall rules applied (No VPN config found)."
fi

# 4. Enable and Notify
ufw --force enable
log_success "UFW has been successfully configured and enabled."

# Desktop Notification via core.sh
send_notification "Security Guard" "Firewall is active. VPN: $IS_VPN_ACTIVE" "normal" "security-high"
