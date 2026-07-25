#!/bin/bash

## ---------------------------
## Argo Tunnel Manager v1.0
## ---------------------------

# Color definitions
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Configuration
ARGO_BINARY="/root/server"
TOKEN_FILE="/root/cloudflare_token.txt"
LOG_FILE="/root/argo.log"
PID_FILE="/tmp/argo.pid"

# Show status
show_status() {
    if pgrep -f "server tunnel" > /dev/null; then
        local PID=$(pgrep -f "server tunnel")
        echo -e "${GREEN}â— Argo Tunnel is RUNNING${NC}"
        echo -e "${WHITE}PID: ${GREEN}$PID${NC}"
        echo -e "\n${CYAN}Process Info:${NC}"
        ps -p $PID -o pid,ppid,cmd,%cpu,%mem,start,time --no-headers 2>/dev/null
        echo -e "\n${CYAN}Last 5 Logs:${NC}"
        tail -5 "$LOG_FILE" 2>/dev/null || echo "No logs"
        return 0
    else
        echo -e "${RED}â— Argo Tunnel is NOT RUNNING${NC}"
        return 1
    fi
}

# Start tunnel
start_tunnel() {
    echo -e "${YELLOW}Starting Argo Tunnel...${NC}"

    if pgrep -f "server tunnel" > /dev/null; then
        echo -e "${YELLOW}Tunnel already running${NC}"
        show_status
        return 0
    fi

    if [ ! -f "$TOKEN_FILE" ]; then
        echo -e "${RED}Token file not found! Run install.sh first${NC}"
        return 1
    fi

    if [ ! -f "$ARGO_BINARY" ]; then
        echo -e "${RED}Argo binary not found! Run install.sh first${NC}"
        return 1
    fi

    local TOKEN=$(cat "$TOKEN_FILE")
    cd /root
    nohup "$ARGO_BINARY" tunnel --edge-ip-version auto --no-autoupdate --protocol http2 run --token "$TOKEN" > "$LOG_FILE" 2>&1 &
    local PID=$!
    echo $PID > "$PID_FILE"

    sleep 3
    if ps -p $PID > /dev/null 2>&1; then
        echo -e "${GREEN}âœ“ Tunnel started (PID: $PID)${NC}"
    else
        echo -e "${RED}Failed to start tunnel!${NC}"
    fi
}

# Stop tunnel
stop_tunnel() {
    echo -e "${YELLOW}Stopping Argo Tunnel...${NC}"

    if ! pgrep -f "server tunnel" > /dev/null; then
        echo -e "${YELLOW}Tunnel not running${NC}"
        return 0
    fi

    pkill -f "server tunnel"
    sleep 2

    if pgrep -f "server tunnel" > /dev/null; then
        pkill -9 -f "server tunnel"
    fi

    if ! pgrep -f "server tunnel" > /dev/null; then
        echo -e "${GREEN}âœ“ Tunnel stopped${NC}"
        rm -f "$PID_FILE"
    fi
}

# Restart tunnel
restart_tunnel() {
    echo -e "${YELLOW}Restarting Argo Tunnel...${NC}"
    stop_tunnel
    sleep 2
    start_tunnel
}

# View logs
view_logs() {
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${RED}No log file found${NC}"
        return 1
    fi
    echo -e "${CYAN}Press Ctrl+C to exit${NC}"
    sleep 1
    tail -f "$LOG_FILE"
}

# Show token
show_token() {
    if [ -f "$TOKEN_FILE" ]; then
        local TOKEN=$(cat "$TOKEN_FILE")
        echo -e "${WHITE}Token: ${GREEN}${TOKEN:0:30}...${NC}"
    else
        echo -e "${RED}No token file${NC}"
    fi
}

# Update token
update_token() {
    echo -en "${YELLOW}Enter new token: ${NC}"
    read NEW_TOKEN
    if [ -n "$NEW_TOKEN" ]; then
        echo "$NEW_TOKEN" > "$TOKEN_FILE"
        chmod 600 "$TOKEN_FILE"
        echo -e "${GREEN}âœ“ Token updated${NC}"
        echo -e "${YELLOW}Run 'manager.sh restart' to apply${NC}"
    fi
}

# Check binary
check_binary() {
    if [ -f "$ARGO_BINARY" ]; then
        echo -e "${WHITE}Binary: ${GREEN}$ARGO_BINARY${NC}"
        echo -e "${WHITE}Size: ${GREEN}$(du -h "$ARGO_BINARY" | cut -f1)${NC}"
    else
        echo -e "${RED}Binary not found${NC}"
    fi
}

# Show help
show_help() {
    echo -e "${CYAN}â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”${NC}"
    echo -e "${GREEN}        Argo Tunnel Manager v1.0${NC}"
    echo -e "${CYAN}â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”${NC}"
    echo -e "${WHITE}Usage: ./manager.sh {command}${NC}"
    echo
    echo -e "${YELLOW}Commands:${NC}"
    echo -e "  ${GREEN}start${NC}         - Start tunnel"
    echo -e "  ${GREEN}stop${NC}          - Stop tunnel"
    echo -e "  ${GREEN}restart${NC}       - Restart tunnel"
    echo -e "  ${GREEN}status${NC}        - Show status"
    echo -e "  ${GREEN}logs${NC}          - View logs"
    echo -e "  ${GREEN}token${NC}         - Show token"
    echo -e "  ${GREEN}update-token${NC}  - Update token"
    echo -e "  ${GREEN}check${NC}         - Check binary"
    echo -e "  ${GREEN}help${NC}          - Show help"
    echo
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ${WHITE}./manager.sh status${NC}"
    echo -e "  ${WHITE}./manager.sh logs${NC}"
    echo -e "  ${WHITE}./manager.sh restart${NC}"
    echo -e "${CYAN}â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”${NC}"
}

# Main
case "${1:-help}" in
    start) start_tunnel ;;
    stop) stop_tunnel ;;
    restart) restart_tunnel ;;
    status) show_status ;;
    logs) view_logs ;;
    token) show_token ;;
    update-token) update_token ;;
    check) check_binary ;;
    help|--help|-h) show_help ;;
    *) 
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac

exit 0
