#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${CYAN}============================================================${NC}"
echo -e "${BOLD}${WHITE}🔄 KUBERNETES COMPLETE RESET SCRIPT${NC}"
echo -e "${CYAN}============================================================${NC}"
echo -e "${WHITE}This will completely remove Kubernetes from all nodes${NC}"
echo -e "${WHITE}and reset them to pre-installation state.${NC}"
echo ""
echo -e "${RED}${BOLD}WARNING: This action cannot be undone!${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

read -p "$(echo -e "${BOLD}${WHITE}Are you sure you want to proceed? (yes/no): ${NC}")" confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${RED}❌ Reset cancelled.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🚀 Starting Kubernetes complete reset...${NC}"
echo ""

# Run the reset playbook
ansible-playbook -i inventory.ini 99-reset-k8s-cluster.yml

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}${BOLD}✅ Kubernetes reset completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}To reinstall Kubernetes, run:${NC}"
    echo -e "${CYAN}  ./run-k8s-install.sh${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}${BOLD}❌ Reset encountered some errors.${NC}"
    echo -e "${YELLOW}Check the output above for details.${NC}"
    echo -e "${YELLOW}Some manual cleanup might be required.${NC}"
    echo ""
fi
