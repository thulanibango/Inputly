#!/usr/bin/env bash
set -euo pipefail

# Script to fix and deploy monitoring configuration
# This script applies the ServiceMonitor and Prometheus configuration fixes

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
TF_DIR="$REPO_ROOT/infra/terraform"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Fixing Monitoring Configuration${NC}"
echo "=================================="

# Check if Minikube is running
echo -e "\n${YELLOW}1. Checking Minikube status...${NC}"
if ! minikube status &>/dev/null; then
  echo -e "${RED}❌ Minikube is not running. Please start it first:${NC}"
  echo "   minikube start"
  exit 1
fi
echo -e "${GREEN}✅ Minikube is running${NC}"

# Check if kubectl/minikube kubectl is available
if command -v kubectl >/dev/null 2>&1; then
    KUBECTL="kubectl"
elif command -v minikube >/dev/null 2>&1; then
    KUBECTL="minikube kubectl --"
else
    echo -e "${RED}❌ Neither kubectl nor minikube found in PATH${NC}"
    exit 1
fi

# Step 1: Apply Terraform monitoring fixes
echo -e "\n${YELLOW}2. Applying Terraform monitoring configuration...${NC}"
cd "$TF_DIR"

if [ ! -d ".terraform" ]; then
  echo -e "${BLUE}🔧 Initializing Terraform...${NC}"
  terraform init -backend=false
fi

echo -e "${BLUE}🔄 Updating Prometheus configuration...${NC}"
terraform apply \
  -var="grafana_host=${GRAFANA_HOST:-grafana.local}" \
  -var="grafana_admin_password=${GRAFANA_PASSWORD:-admin123}" \
  -var="monitoring_namespace=${MONITORING_NAMESPACE:-monitoring}" \
  -var="prometheus_release_name=kube-prometheus-stack" \
  -target="helm_release.kps" \
  -auto-approve

echo -e "${GREEN}✅ Terraform monitoring configuration updated${NC}"

# Step 2: Wait for Prometheus to restart
echo -e "\n${YELLOW}3. Waiting for Prometheus to restart...${NC}"
sleep 10
$KUBECTL rollout status statefulset/prometheus-kube-prometheus-stack-prometheus -n monitoring --timeout=120s

# Step 3: Deploy/upgrade the API with fixed ServiceMonitor
echo -e "\n${YELLOW}4. Deploying API with fixed ServiceMonitor...${NC}"
cd "$REPO_ROOT"

# Check if the release exists
if $KUBECTL get deployment inputly-api -n inputly &>/dev/null; then
  echo -e "${BLUE}🔄 Upgrading existing inputly-api release...${NC}"
  $KUBECTL get namespace inputly &>/dev/null || $KUBECTL create namespace inputly
  helm upgrade inputly-api ./deploy/helm/inputly-api \
    --namespace inputly \
    --set image.repository=inputly \
    --set image.tag=local \
    --set metrics.enabled=true \
    --set metrics.prometheusRelease=kube-prometheus-stack
else
  echo -e "${BLUE}🔄 Installing inputly-api release...${NC}"
  $KUBECTL get namespace inputly &>/dev/null || $KUBECTL create namespace inputly
  helm install inputly-api ./deploy/helm/inputly-api \
    --namespace inputly \
    --set image.repository=inputly \
    --set image.tag=local \
    --set metrics.enabled=true \
    --set metrics.prometheusRelease=kube-prometheus-stack
fi

# Wait for deployment to be ready
echo -e "\n${YELLOW}5. Waiting for API deployment to be ready...${NC}"
$KUBECTL rollout status deployment/inputly-api -n inputly --timeout=120s

# Step 4: Verify ServiceMonitor was created
echo -e "\n${YELLOW}6. Verifying ServiceMonitor creation...${NC}"
if $KUBECTL get servicemonitor inputly-api -n inputly &>/dev/null; then
  echo -e "${GREEN}✅ ServiceMonitor 'inputly-api' created successfully${NC}"
  echo -e "${BLUE}ServiceMonitor details:${NC}"
  $KUBECTL get servicemonitor inputly-api -n inputly -o yaml | grep -A 10 "labels\|selector"
else
  echo -e "${RED}❌ ServiceMonitor 'inputly-api' not found${NC}"
  echo -e "${YELLOW}Checking if metrics are enabled in values...${NC}"
  exit 1
fi

# Step 5: Verify service has correct labels
echo -e "\n${YELLOW}7. Verifying service labels...${NC}"
SERVICE_LABELS=$($KUBECTL get svc inputly-api -n inputly -o jsonpath='{.metadata.labels}')
echo -e "${BLUE}Service labels: ${SERVICE_LABELS}${NC}"

if echo "$SERVICE_LABELS" | grep -q "release.*kube-prometheus-stack"; then
  echo -e "${GREEN}✅ Service has correct 'release' label${NC}"
else
  echo -e "${RED}❌ Service missing 'release' label${NC}"
fi

# Step 6: Check if Prometheus is discovering the target
echo -e "\n${YELLOW}8. Checking Prometheus targets...${NC}"
echo -e "${BLUE}Waiting 30 seconds for Prometheus to discover new targets...${NC}"
sleep 30

# Test metrics endpoint directly
echo -e "\n${YELLOW}9. Testing metrics endpoint...${NC}"
if $KUBECTL exec -n inputly deployment/inputly-api -- wget -q -O - http://localhost:3000/metrics | head -5; then
  echo -e "${GREEN}✅ Metrics endpoint is responding${NC}"
else
  echo -e "${RED}❌ Metrics endpoint not responding${NC}"
fi

echo -e "\n${GREEN}🎉 Monitoring fix deployment completed!${NC}"
echo "=================================="
echo -e "${BLUE}Next steps:${NC}"
echo "1. Access Prometheus to check targets:"
echo "   $KUBECTL port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090"
echo "   Then visit: http://localhost:9090/targets"
echo ""
echo "2. Access Grafana:"
echo "   $KUBECTL port-forward -n monitoring svc/kube-prometheus-stack-grafana 80:80"
echo "   Then visit: http://grafana.local (admin/admin123)"
echo ""
echo "3. Look for 'inputly-api' target in Prometheus targets page"
echo "4. Import dashboards for Node.js applications in Grafana"
echo ""
echo -e "${YELLOW}If targets still don't appear, run:${NC}"
echo "   bash $SCRIPT_DIR/troubleshoot-monitoring.sh"