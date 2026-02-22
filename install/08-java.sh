#!/bin/bash
# 08-java.sh - Java normalization via SDKMAN and IntelliJ setup

source "$(dirname "$0")/00-core.sh"

echo -e "${CYAN}🚀 Configuring Java environment with SDKMAN...${NC}"

# 1. Ensure SDKMAN is installed and sourced
export SDKMAN_DIR="$HOME/.sdkman"
if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
    echo -e "  ${GREEN}✅ SDKMAN found and sourced.${NC}"
else
    echo -e "${YELLOW}⚠️  SDKMAN missing, installing...${NC}"
    curl -s "https://get.sdkman.io" | bash
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi

# 2. Install and set Temurin versions via SDKMAN
echo -e "${YELLOW}☕ Installing Temurin JDK 21 and 17...${NC}"
# Standardizing on SDKMAN versions to ensure 'which java' points here
sdk install java 21.0.2-tem < /dev/null
sdk install java 17.0.10-tem < /dev/null

echo -e "${YELLOW}⚙️  Setting Temurin 21 as default for SDKMAN...${NC}"
sdk default java 21.0.2-tem

# 3. Install Maven via SDKMAN
echo -e "${YELLOW}🛠️  Installing Maven via SDKMAN...${NC}"
sdk install maven < /dev/null

# 5. Install IntelliJ IDEA Community Edition from Official Repos
echo -e "${YELLOW}📦 Ensuring IntelliJ IDEA is installed (Official Repo)...${NC}"
sudo pamac install --no-confirm intellij-idea-community-edition

echo -e "${GREEN}✅ Java setup completed!${NC}"
echo -e "${BLUE}NOTE: System OpenJDK remains to satisfy IntelliJ dependencies, but SDKMAN takes priority in shell.${NC}"
