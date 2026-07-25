#!/bin/bash

## ---------------------------
## Argo Tunnel Installer v2.0
## ---------------------------

# Color definitions
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Check root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}This script must be run as root!${NC}"
    exit 1
fi

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}         Argo Tunnel Installer v2.0${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Function to draw line
draw_line() {
    echo -e "${CYAN}────────────────────────────────────────────${NC}"
}

# Step 1: Download Argo Binary
echo -e "\n${YELLOW}[1/4] Downloading Argo Tunnel Binary...${NC}"
draw_line

if command -v wget &> /dev/null; then
    wget -O /root/server https://github.com/lightyagami210618/argo/releases/download/v1.0/server
else
    echo -e "${YELLOW}Installing wget...${NC}"
    apt update && apt install wget -y
    wget -O /root/server https://github.com/lightyagami210618/argo/releases/download/v1.0/server
fi

if [ ! -f /root/server ]; then
    echo -e "${RED}Download failed! Please check your internet connection.${NC}"
    exit 1
fi

chmod +x /root/server
echo -e "${GREEN}✓ Argo binary downloaded and permissions set${NC}"

# Step 2: Download Manager Script from GitHub
echo -e "\n${YELLOW}[2/4] Downloading Argo Manager Script...${NC}"
draw_line

wget -O /root/manager.sh https://raw.githubusercontent.com/lightyagami210618/argo/main/manager.sh

if [ ! -f /root/manager.sh ]; then
    echo -e "${RED}Failed to download manager.sh from GitHub!${NC}"
    echo -e "${YELLOW}Please check: https://raw.githubusercontent.com/lightyagami210618/argo/main/manager.sh${NC}"
    exit 1
fi

chmod +x /root/manager.sh
echo -e "${GREEN}✓ Argo Tunnel Manager Script Downloaded${NC}"

# Step 3: Get Cloudflare Token
echo -e "\n${YELLOW}[3/4] Cloudflare Token Configuration${NC}"
draw_line
echo -e "${WHITE}Enter your Cloudflare Zero Trust Token:${NC}"
echo -e "${BLUE}How to get token:${NC}"
echo -e "1. Go to https://one.dash.cloudflare.com"
echo -e "2. Navigate to Networks → Tunnels"
echo -e "3. Create a new tunnel or use existing one"
echo -e "4. Copy the token (starts with 'eyJ...')"
draw_line

echo -en "${GREEN}Enter Token: ${NC}"
read CLOUDFLARE_TOKEN

if [ -z "$CLOUDFLARE_TOKEN" ]; then
    echo -e "${RED}Token cannot be empty!${NC}"
    exit 1
fi

echo "$CLOUDFLARE_TOKEN" > /root/cloudflare_token.txt
chmod 600 /root/cloudflare_token.txt
echo -e "${GREEN}✓ Token saved to /root/cloudflare_token.txt${NC}"

# Step 4: Start Tunnel and Setup Management
echo -e "\n${YELLOW}[4/4] Starting Argo Tunnel...${NC}"
draw_line

# Kill any existing processes
pkill -f "server tunnel" 2>/dev/null
sleep 2

# Start tunnel using the binary directly
cd /root
nohup ./server tunnel --edge-ip-version auto --no-autoupdate --protocol http2 run --token "$CLOUDFLARE_TOKEN" > /root/argo.log 2>&1 &
sleep 3

# Check if started
if pgrep -f "server tunnel" > /dev/null; then
    local PID=$(pgrep -f "server tunnel")
    echo -e "${GREEN}✓ Argo Tunnel started successfully (PID: $PID)${NC}"
else
    echo -e "${RED}Failed to start Argo Tunnel! Check /root/argo.log${NC}"
fi

# Create aliases for easy management
echo "alias argo='/root/manager.sh'" >> /root/.bashrc
echo "alias argo-manager='/root/manager.sh'" >> /root/.bashrc
echo "alias argo-start='/root/manager.sh start'" >> /root/.bashrc
echo "alias argo-stop='/root/manager.sh stop'" >> /root/.bashrc
echo "alias argo-restart='/root/manager.sh restart'" >> /root/.bashrc
echo "alias argo-status='/root/manager.sh status'" >> /root/.bashrc
echo "alias argo-logs='/root/manager.sh logs'" >> /root/.bashrc
echo "alias argo-token='/root/manager.sh token'" >> /root/.bashrc
echo "alias argo-update-token='/root/manager.sh update-token'" >> /root/.bashrc

# Add to crontab for auto-start on reboot
(crontab -l 2>/dev/null | grep -v "manager.sh"; echo "@reboot /root/manager.sh start") | crontab -
echo -e "${GREEN}✓ Auto-start on reboot enabled (crontab)${NC}"

# Final output
clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}         Argo Tunnel Installation Complete!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# Show current status
/root/manager.sh status
echo

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Management Commands (using manager.sh):${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}Direct commands:${NC}"
echo -e "  ${GREEN}/root/manager.sh status${NC}     - Check status"
echo -e "  ${GREEN}/root/manager.sh logs${NC}       - View logs"
echo -e "  ${GREEN}/root/manager.sh restart${NC}    - Restart tunnel"
echo -e "  ${GREEN}/root/manager.sh token${NC}      - Show token"
echo -e "  ${GREEN}/root/manager.sh update-token${NC} - Update token"
echo
echo -e "${WHITE}Aliases (after re-login or 'source /root/.bashrc'):${NC}"
echo -e "  ${GREEN}argo status${NC}         - Check status"
echo -e "  ${GREEN}argo logs${NC}           - View logs"
echo -e "  ${GREEN}argo restart${NC}        - Restart tunnel"
echo -e "  ${GREEN}argo token${NC}          - Show token"
echo -e "  ${GREEN}argo update-token${NC}   - Update token"
echo
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}To use aliases now: source /root/.bashrc${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
