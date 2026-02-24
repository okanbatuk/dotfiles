#!/bin/bash
# 09-javascript.sh - JavaScript & TypeScript Ecosystem Setup

# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_DIR/../core.sh"

echo -e "${PURPLE}🌐 Configuring JavaScript/TypeScript Environment for $REAL_USER...${NC}"

# 1. Node.js and NPM Installation
# Check if node is already installed to avoid unnecessary pacman calls
if ! command -v node >/dev/null; then
    echo -e "${BLUE}📦 Installing Node.js and NPM via pacman...${NC}"
    sudo pacman -S --noconfirm nodejs npm
else
    echo -e "  ${GREEN}✅ Node.js $(node -v) is already installed.${NC}"
fi

# 2. NPM Global Directory Configuration
# Redirecting global packages to home directory to avoid permission issues and sudo usage
echo -e "${BLUE}⚙️  Setting NPM global prefix to $REAL_HOME/.npm-global...${NC}"
mkdir -p "$REAL_HOME/.npm-global"
npm config set prefix "$REAL_HOME/.npm-global"

# 3. Global Package Installation
# Installing essential backend tools. Sudo is no longer required due to prefix change.
echo -e "${BLUE}🛠️  Installing Global Tools (TypeScript, PM2, Vercel)...${NC}"
npm install -g typescript ts-node nodemon pm2 vercel prettier

# 4. Bun Runtime Installation
# High-performance runtime for your streaming-aware projects
if ! command -v bun >/dev/null; then
    echo -e "${BLUE}🚀 Installing Bun Runtime...${NC}"
    # Ensure unzip is available (checked in 01-system.sh) for successful extraction
    curl -fsSL https://bun.sh/install | bash
else
    echo -e "  ${GREEN}✅ Bun is already installed.${NC}"
fi

# 5. Zed & Editor LSP Support
# Pre-installing language servers to ensure Zed's IDE features work out-of-the-box
echo -e "${BLUE}📝 Installing Language Servers for Zed LSP...${NC}"
npm install -g typescript-language-server vscode-langservers-extracted

# 6. Path Verification
# Since your .zshrc already handles the path array, we just verify the directory existence
if [[ -d "$REAL_HOME/.npm-global/bin" ]]; then
    echo -e "  ${GREEN}✅ JS binary directory is ready and mapped in your .zshrc structure.${NC}"
fi

echo -e "${GREEN}✅ JavaScript ecosystem setup completed successfully!${NC}"
