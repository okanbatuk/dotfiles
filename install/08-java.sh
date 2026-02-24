#!/bin/bash
# 08-java.sh - Java normalization via SDKMAN and IntelliJ setup
# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_ENV="$CORE_DIR/../core.sh"

if [ -f "$CORE_ENV" ]; then
    source "$CORE_ENV"
else
    # Fallback to current dir if not in scripts/
    source "$CORE_DIR/core.sh" 2>/dev/null || { echo "Error: core.sh not found"; exit 1; }
fi

echo -e "${CYAN}🚀 Configuring Java environment with SDKMAN...${NC}"

# 1. Ensure SDKMAN is installed and sourced
if [ ! -d "$SDKMAN_DIR" ]; then
    echo -e "${BLUE}📥 Downloading and installing SDKMAN!...${NC}"
    export sdkman_auto_answer=true
    curl -s "https://get.sdkman.io" | bash

    source "$SDKMAN_DIR/bin/sdkman-init.sh"
else
    echo -e "${GREEN}✅ SDKMAN! is already installed.${NC}"
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi

# 2. Install and set Temurin versions via SDKMAN
if command -v sdk >/dev/null; then
    export sdkman_auto_answer=true
    export sdkman_auto_selfupdate=true

    echo -e "${BLUE}☕ Installing JDKs...${NC}"
    sdk install java 17.0.10-tem
    sdk install java 21.0.2-tem
    sdk default java 21.0.2-tem

    echo -e "${BLUE}🛠️  Installing Maven...${NC}"
    sdk install maven
else
    echo -e "${RED}❌ SDKMAN initialization failed! Check $SDKMAN_DIR${NC}"
fi

# 3. Install IntelliJ IDEA Community Edition from Official Repos
echo -e "${YELLOW}📦 Ensuring IntelliJ IDEA is installed (Official Repo)...${NC}"
sudo pamac install --no-confirm intellij-idea-community-edition

echo -e "${GREEN}✅ Java setup completed!${NC}"
echo -e "${BLUE}NOTE: System OpenJDK remains to satisfy IntelliJ dependencies, but SDKMAN takes priority in shell.${NC}"
