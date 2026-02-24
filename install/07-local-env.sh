#!/bin/bash
# install/07-local-env.sh
# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_ENV="$CORE_DIR/../core.sh"

if [ -f "$CORE_ENV" ]; then
    source "$CORE_ENV"
else
    # Fallback to current dir if not in scripts/
    source "$CORE_DIR/core.sh" 2>/dev/null || { echo "Error: core.sh not found"; exit 1; }
fi

LOCAL_ENV="$REAL_HOME/.zshenv.local"

echo -e "${CYAN}🔍 Checking local environment file...${NC}"

if [ ! -f "$LOCAL_ENV" ]; then
    echo -e "${YELLOW}Creating $LOCAL_ENV with default device IDs...${NC}"

    cat <<EOF > "$LOCAL_ENV"
# Device Ids
export ID_WEBCAM="04f2:b5a7"
export ID_BLUETOOTH="8087:0a2b"
export ID_FINGERPRINT="1c7a:0603"

# You can add local private variables here.
EOF
    echo -e "${GREEN}✅ Local environment file created.${NC}"
else
    echo -e "${BLUE} $LOCAL_ENV already exists. Skipping creation.${NC}"
fi
