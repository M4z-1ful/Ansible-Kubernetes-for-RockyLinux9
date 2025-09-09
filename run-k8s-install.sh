#!/bin/bash

# Kubernetes Cluster Installation Script
# Executes playbooks 01-04 in sequence for complete K8s cluster setup

set -e  # Exit on any error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Colors (distinct from Ansible's default colors)
BLUE='\033[1;34m'     # Bright Blue
CYAN='\033[1;36m'     # Bright Cyan  
MAGENTA='\033[1;35m'  # Bright Magenta
WHITE='\033[1;37m'    # Bright White
NC='\033[0m'          # No Color

echo -e "${MAGENTA}============================================================${NC}"
echo -e "${MAGENTA}🚀 Kubernetes Cluster Installation Started${NC}"
echo -e "${MAGENTA}============================================================${NC}"

echo -e "${CYAN}[1/4] Creating kube user and SSH setup...${NC}"
ansible-playbook -i inventory.ini 01-user-create.yml

echo -e "${CYAN}[2/4] Installing Kubernetes components...${NC}"
ansible-playbook -i inventory.ini 02-k8s-install.yml

echo -e "${CYAN}[3/4] Initializing cluster and joining nodes...${NC}"
ansible-playbook -i inventory.ini 03-k8s-init-cluster.yml

echo -e "${CYAN}[4/4] Verifying cluster installation...${NC}"
ansible-playbook -i inventory.ini 04-k8s-check-cluster.yml

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}✅ Kubernetes Cluster Installation Completed!${NC}"
echo -e "${BLUE}============================================================${NC}"
