#!/bin/bash
# install/07-local-env.sh
source "$(dirname "$0")/00-core.sh"

LOCAL_ENV="$HOME/.zshenv.local"

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
