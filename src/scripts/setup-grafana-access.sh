#!/usr/bin/env bash
set -euo pipefail

# Script to set up Grafana access properly
# Handles both hosts file and direct port forwarding options

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🌐 Setting up Grafana Access${NC}"
echo "============================"

# Check if kubectl/minikube kubectl is available
if command -v kubectl >/dev/null 2>&1; then
    KUBECTL="kubectl"
elif command -v minikube >/dev/null 2>&1; then
    KUBECTL="minikube kubectl --"
else
    echo -e "${RED}❌ Neither kubectl nor minikube found in PATH${NC}"
    exit 1
fi

# Check if Grafana is running
echo -e "\n${YELLOW}1. Checking Grafana status...${NC}"
if ! $KUBECTL get pod -n monitoring -l app.kubernetes.io/name=grafana &>/dev/null; then
    echo -e "${RED}❌ Grafana is not running. Deploy monitoring stack first:${NC}"
    echo "   ./deploy-monitoring.sh"
    exit 1
fi

GRAFANA_POD=$($KUBECTL get pods -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}')
if $KUBECTL get pod "$GRAFANA_POD" -n monitoring -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; then
    echo -e "${GREEN}✅ Grafana pod is ready${NC}"
else
    echo -e "${RED}❌ Grafana pod is not ready${NC}"
    exit 1
fi

echo -e "\n${YELLOW}2. Setting up access options...${NC}"
echo -e "${BLUE}Choose your preferred access method:${NC}"
echo "1. Add grafana.local to /etc/hosts (requires sudo)"
echo "2. Use direct localhost access (no hosts file needed)"
echo "3. Show both options"

read -p "Enter choice (1-3): " choice

case $choice in
    1|3)
        echo -e "\n${YELLOW}Option 1: Adding grafana.local to /etc/hosts${NC}"
        if grep -q "grafana.local" /etc/hosts; then
            echo -e "${GREEN}✅ grafana.local already in /etc/hosts${NC}"
        else
            echo -e "${BLUE}Adding 127.0.0.1 grafana.local to /etc/hosts (requires sudo)${NC}"
            echo "127.0.0.1 grafana.local" | sudo tee -a /etc/hosts
            echo -e "${GREEN}✅ Added grafana.local to /etc/hosts${NC}"
        fi
        
        echo -e "\n${BLUE}Starting port-forward for grafana.local access...${NC}"
        echo -e "${YELLOW}You can now access Grafana at: http://grafana.local${NC}"
        echo -e "${BLUE}Username: admin${NC}"
        echo -e "${BLUE}Password: admin123${NC}"
        echo -e "\n${YELLOW}Press Ctrl+C to stop port forwarding${NC}"
        
        if [ "$choice" = "1" ]; then
            $KUBECTL port-forward -n monitoring svc/kube-prometheus-stack-grafana 80:80
        fi
        ;;
esac

case $choice in
    2|3)
        echo -e "\n${YELLOW}Option 2: Direct localhost access${NC}"
        echo -e "${BLUE}Starting port-forward for localhost access...${NC}"
        echo -e "${YELLOW}You can access Grafana at: http://localhost:3001${NC}"
        echo -e "${BLUE}Username: admin${NC}"
        echo -e "${BLUE}Password: admin123${NC}"
        echo -e "\n${YELLOW}Press Ctrl+C to stop port forwarding${NC}"
        
        if [ "$choice" = "2" ]; then
            $KUBECTL port-forward -n monitoring svc/kube-prometheus-stack-grafana 3001:80
        fi
        ;;
esac

if [ "$choice" = "3" ]; then
    echo -e "\n${BLUE}Both options configured. Choose one:${NC}"
    echo -e "${YELLOW}For grafana.local (port 80):${NC}"
    echo "   $KUBECTL port-forward -n monitoring svc/kube-prometheus-stack-grafana 80:80"
    echo "   Then visit: http://grafana.local"
    echo ""
    echo -e "${YELLOW}For localhost (port 3001):${NC}"
    echo "   $KUBECTL port-forward -n monitoring svc/kube-prometheus-stack-grafana 3001:80"
    echo "   Then visit: http://localhost:3001"
    echo ""
    echo -e "${BLUE}Credentials for both: admin / admin123${NC}"
fi

echo -e "\n${GREEN}🎉 Grafana access setup complete!${NC}"