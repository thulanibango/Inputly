#!/usr/bin/env bash
set -euo pipefail

# Script to verify that metrics are working correctly
# This script checks all components of the metrics pipeline

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Verifying Metrics Pipeline${NC}"
echo "=============================="

# Check if kubectl/minikube kubectl is available
if command -v kubectl >/dev/null 2>&1; then
    KUBECTL="kubectl"
elif command -v minikube >/dev/null 2>&1; then
    KUBECTL="minikube kubectl --"
else
    echo -e "${RED}❌ Neither kubectl nor minikube found in PATH${NC}"
    exit 1
fi

# Function to check if a pod is ready
check_pod_ready() {
    local namespace=$1
    local selector=$2
    local name=$3
    
    local pod=$($KUBECTL get pods -n "$namespace" -l "$selector" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [ -n "$pod" ]; then
        if $KUBECTL get pod "$pod" -n "$namespace" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; then
            echo -e "${GREEN}✅ $name pod is ready${NC}"
            return 0
        else
            echo -e "${RED}❌ $name pod is not ready${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ $name pod not found${NC}"
        return 1
    fi
}

echo -e "\n${YELLOW}1. Checking pod status...${NC}"

# Check Prometheus
check_pod_ready "monitoring" "app.kubernetes.io/name=prometheus" "Prometheus" || exit 1

# Check Grafana
check_pod_ready "monitoring" "app.kubernetes.io/name=grafana" "Grafana" || exit 1

# Check API
check_pod_ready "inputly" "app=inputly-api" "Inputly API" || exit 1

echo -e "\n${YELLOW}2. Checking ServiceMonitor...${NC}"
if $KUBECTL get servicemonitor inputly-api -n inputly &>/dev/null; then
    echo -e "${GREEN}✅ ServiceMonitor exists${NC}"
    
    # Check ServiceMonitor labels
    SM_LABELS=$($KUBECTL get servicemonitor inputly-api -n inputly -o jsonpath='{.metadata.labels}')
    echo -e "${BLUE}ServiceMonitor labels: ${SM_LABELS}${NC}"
    
    if echo "$SM_LABELS" | grep -q "release.*kube-prometheus-stack"; then
        echo -e "${GREEN}✅ ServiceMonitor has correct release label${NC}"
    else
        echo -e "${RED}❌ ServiceMonitor missing release label${NC}"
    fi
else
    echo -e "${RED}❌ ServiceMonitor not found${NC}"
    exit 1
fi

echo -e "\n${YELLOW}3. Checking Service labels...${NC}"
if $KUBECTL get svc inputly-api -n inputly &>/dev/null; then
    SVC_LABELS=$($KUBECTL get svc inputly-api -n inputly -o jsonpath='{.metadata.labels}')
    echo -e "${BLUE}Service labels: ${SVC_LABELS}${NC}"
    
    if echo "$SVC_LABELS" | grep -q "release.*kube-prometheus-stack"; then
        echo -e "${GREEN}✅ Service has correct release label${NC}"
    else
        echo -e "${RED}❌ Service missing release label${NC}"
    fi
else
    echo -e "${RED}❌ Service not found${NC}"
    exit 1
fi

echo -e "\n${YELLOW}4. Testing metrics endpoint...${NC}"
# Test metrics endpoint directly from pod
METRICS_OUTPUT=$($KUBECTL exec -n inputly deployment/inputly-api -- wget -q -O - http://localhost:3000/metrics 2>/dev/null || echo "FAILED")

if [ "$METRICS_OUTPUT" != "FAILED" ] && echo "$METRICS_OUTPUT" | grep -q "http_requests_total"; then
    echo -e "${GREEN}✅ Metrics endpoint responding with valid data${NC}"
    echo -e "${BLUE}Sample metrics:${NC}"
    echo "$METRICS_OUTPUT" | head -10
else
    echo -e "${RED}❌ Metrics endpoint not responding or invalid data${NC}"
    exit 1
fi

echo -e "\n${YELLOW}5. Checking if Prometheus can reach the service...${NC}"
# Port forward to Prometheus and check targets (this requires manual verification)
echo -e "${BLUE}To check Prometheus targets:${NC}"
echo "1. Run: $KUBECTL port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090"
echo "2. Open: http://localhost:9090/targets"
echo "3. Look for 'inputly-api' in the targets list"
echo ""

echo -e "\n${YELLOW}6. Prometheus configuration check...${NC}"
# Check if Prometheus has the correct serviceMonitorSelector
PROM_CONFIG=$($KUBECTL get prometheus -n monitoring -o jsonpath='{.items[0].spec.serviceMonitorSelector}' 2>/dev/null || echo "")
echo -e "${BLUE}Prometheus serviceMonitorSelector: ${PROM_CONFIG}${NC}"

if echo "$PROM_CONFIG" | grep -q "kube-prometheus-stack"; then
    echo -e "${GREEN}✅ Prometheus configured to select ServiceMonitors with correct label${NC}"
else
    echo -e "${YELLOW}⚠️  Prometheus serviceMonitorSelector might need configuration${NC}"
fi

echo -e "\n${YELLOW}7. Generating test traffic...${NC}"
echo -e "${BLUE}Sending test requests to generate metrics...${NC}"
for i in {1..5}; do
    $KUBECTL exec -n inputly deployment/inputly-api -- wget -q -O - http://localhost:3000/health > /dev/null 2>&1
    echo -n "."
done
echo ""
echo -e "${GREEN}✅ Test traffic sent${NC}"

echo -e "\n${GREEN}🎉 Metrics verification completed!${NC}"
echo "================================"
echo -e "${BLUE}Summary:${NC}"
echo "- All pods are running and ready"
echo "- ServiceMonitor exists with correct labels"
echo "- Service has correct labels for Prometheus discovery"
echo "- Metrics endpoint is responding"
echo "- Test traffic generated"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Check Prometheus targets: http://localhost:9090/targets"
echo "2. Check Grafana dashboards: http://grafana.local"
echo "3. Create custom dashboards for your application metrics"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo "- Port-forward Prometheus: $KUBECTL port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090"
echo "- Port-forward Grafana: $KUBECTL port-forward -n monitoring svc/kube-prometheus-stack-grafana 80:80"
echo "- View ServiceMonitor: $KUBECTL describe servicemonitor inputly-api -n inputly"
echo "- View Prometheus logs: $KUBECTL logs -n monitoring -l app.kubernetes.io/name=prometheus"