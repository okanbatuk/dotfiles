#!/bin/bash
# 09-local-env.sh - Managing device-specific local environment variables
# Creates a .zshenv.local file for machine-specific IDs and private variables.

set -e # Exit immediately if a command fails to trigger setup.sh trap

# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_DIR/../core.sh" || { source "$CORE_DIR/core.sh" 2>/dev/null || exit 1; }

LOCAL_ENV="$REAL_HOME/.zshenv.local"

log_info "🔍 Checking local environment file for $REAL_USER..."

# 1. Local Environment Creation Logic
if [ ! -f "$LOCAL_ENV" ]; then
    log_warn "💡 $LOCAL_ENV not found. Creating a new one with default device IDs..."

    # Create the file using a heredoc
    # This file contains sensitive hardware IDs and should remain local (gitignored)
    cat <<EOF > "$LOCAL_ENV"
# Device Ids - Update these using 'lsusb' if needed
export ID_WEBCAM="04f2:b5a7"
export ID_BLUETOOTH="8087:0a2b"
export ID_FINGERPRINT="1c7a:0603"

# You can add local private variables or machine-specific exports below.
EOF

    # 2. Permissions & Ownership
    # Critical: Ensure the file is owned by the real user, not root
    chown "$REAL_USER:$REAL_USER" "$LOCAL_ENV"

    # Set restrictive permissions (read/write only for user) as it might contain private data
    chmod 600 "$LOCAL_ENV"

    log_info "✅ Local environment file created successfully at $LOCAL_ENV."
else
    # Preserving manual changes is a priority for device-specific configs
    log_debug "ℹ️  $LOCAL_ENV already exists. Skipping creation to preserve your manual changes."
fi

log_info "✅ Local environment task finished."
