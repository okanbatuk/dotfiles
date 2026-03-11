#!/bin/bash
# 08-local-env.sh - Managing device-specific local environment variables
# Creates a .zshenv.local file for machine-specific IDs and private variables.

set -e # Exit immediately if a command fails to trigger setup.sh trap

# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_DIR/../core.sh" || { source "$CORE_DIR/core.sh" 2>/dev/null || exit 1; }

LOCAL_ENV="$REAL_HOME/.zshenv.local"

echo -e "${CYAN}🔍 Checking local environment file for $REAL_USER...${NC}"

if [ ! -f "$LOCAL_ENV" ]; then
    echo -e "${YELLOW}Creating $LOCAL_ENV with default device IDs...${NC}"

    # Create the file using a heredoc
    # Note: We use a simple cat here, but we will fix ownership immediately after
    cat <<EOF > "$LOCAL_ENV"
# Device Ids - Update these using 'lsusb' if needed
export ID_WEBCAM="04f2:b5a7"
export ID_BLUETOOTH="8087:0a2b"
export ID_FINGERPRINT="1c7a:0603"

# You can add local private variables or machine-specific exports below.
EOF

    # Critical: Ensure the file is owned by the real user, not root
    chown "$REAL_USER:$REAL_USER" "$LOCAL_ENV"
    chmod 600 "$LOCAL_ENV" # Set restrictive permissions as it might contain private data

    echo -e "${GREEN}✅ Local environment file created successfully.${NC}"
else
    echo -e "${BLUE}ℹ️  $LOCAL_ENV already exists. Skipping creation to preserve your manual changes.${NC}"
fi

echo -e "${GREEN}✅ Local environment task finished.${NC}"
