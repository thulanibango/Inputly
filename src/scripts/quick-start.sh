#!/usr/bin/env bash
set -euo pipefail

# Quick start script for Inputly monitoring
# One command to rule them all!

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}⚡ Inputly Quick Start${NC}"
echo "==================="
echo -e "${BLUE}This will install everything and start your monitoring stack${NC}"
echo ""

# Check if prerequisites script exists
if [[ ! -f "$SCRIPT_DIR/install-prerequisites.sh" ]]; then
    echo -e "${RED}❌ install-prerequisites.sh not found${NC}"
    exit 1
fi

# Run the complete installation
echo -e "${YELLOW}🚀 Running complete installation...${NC}"
bash "$SCRIPT_DIR/install-prerequisites.sh"

echo -e "\n${GREEN}🎉 Quick start completed!${NC}"
echo -e "${BLUE}Your monitoring stack should now be running.${NC}"
echo ""
echo -e "${YELLOW}To access Grafana right now:${NC}"
echo "1. Open a new terminal"
echo "2. Run: kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 80:80"
echo "3. Visit: http://grafana.local"
echo "4. Login: admin / admin123"
echo ""
echo -e "${GREEN}Enjoy your monitoring! 📊${NC}"