#!/bin/bash

# Color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

clear
echo -e "${YELLOW}============================================${NC}"
echo -e "${GREEN}      Welcome to SyncTech Setup Menu        ${NC}"
echo -e "${YELLOW}============================================${NC}"
echo
echo "Please select an option:"
echo "1) Basic Configuration"
echo "2) Install VPN"
echo
read -p "Enter your choice [1 or 2]: " choice

case "$choice" in
    1)
        echo -e "${GREEN}Running Basic Configuration...${NC}"
        sh -c "$(wget -O- https://raw.githubusercontent.com/synctech-project/LTE-Modem/main/install.sh)"
        ;;
    2)
        echo -e "${GREEN}Running VPN Installation...${NC}"
        sh -c "$(wget -O- https://raw.githubusercontent.com/synctech-project/LTE-Modem/main/passwall.sh)"
        ;;
    *)
        echo -e "${RED}Invalid choice. Please run the script again and choose 1 or 2.${NC}"
        exit 1
        ;;
esac
