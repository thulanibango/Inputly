#!/bin/bash
# Script to deploy the monitoring stack (Prometheus + Grafana)

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
TF_DIR="$REPO_ROOT/infra/terraform"

# Default values
GRAFANA_HOST=${GRAFANA_HOST:-grafana.local}
GRAFANA_PASSWORD=${GRAFANA_PASSWORD:-admin123}
MONITORING_NAMESPACE=${MONITORING_NAMESPACE:-monitoring}

echo "🚀 Deploying Monitoring Stack..."
echo "   Grafana Host: $GRAFANA_HOST"
echo "   Namespace: $MONITORING_NAMESPACE"

# Check if Minikube is running
if ! minikube status &>/dev/null; then
  echo "❌ Minikube is not running. Please start it first:"
  echo "   minikube start"
  exit 1
fi

# Navigate to Terraform directory
cd "$TF_DIR"

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
  echo "🔧 Initializing Terraform..."
  terraform init -backend=false
fi

# Deploy monitoring stack with specified variables
echo "🔄 Deploying monitoring stack..."
terraform apply \
  -var="grafana_host=$GRAFANA_HOST" \
  -var="grafana_admin_password=$GRAFANA_PASSWORD" \
  -var="monitoring_namespace=$MONITORING_NAMESPACE" \
  -var="prometheus_release_name=kube-prometheus-stack" \
  -target="kubernetes_namespace.monitoring" \
  -target="helm_release.kps" \
  -auto-approve

# Add to /etc/hosts if not already present
if ! grep -q "$GRAFANA_HOST" /etc/hosts; then
  echo "📝 Adding $GRAFANA_HOST to /etc/hosts (requires sudo)"
  echo "127.0.0.1 $GRAFANA_HOST" | sudo tee -a /etc/hosts
fi

echo "✅ Monitoring stack deployed!"
echo "   Grafana will be available at: http://$GRAFANA_HOST"
echo "   Default credentials: admin / $GRAFANA_PASSWORD"

# Instructions
echo -e "\nTo access Grafana:"
echo "1. Start port-forwarding:"
echo "   kubectl -n $MONITORING_NAMESPACE port-forward svc/kube-prometheus-stack-grafana 80:80"
echo -e "\n2. Open: http://$GRAFANA_HOST"
echo -e "\n3. Login with: admin / $GRAFANA_PASSWORD"
