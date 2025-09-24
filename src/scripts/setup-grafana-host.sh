#!/bin/bash
# Script to set up Grafana host and apply Terraform configuration

set -e  # Exit on error

# Default values
GRAFANA_HOST="grafana.local"
TERRAFORM_DIR="infra/terraform"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --host=*)
      GRAFANA_HOST="${1#*=}"
      shift
      ;;
    --help)
      echo "Usage: $0 [--host=grafana.hostname]"
      echo "  --host=HOSTNAME  Set the Grafana hostname (default: grafana.local)"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "🚀 Setting up Grafana host: $GRAFANA_HOST"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
  echo "❌ Error: Terraform is not installed. Please install it first."
  exit 1
fi

# Navigate to Terraform directory
cd "$(dirname "$0")/../$TERRAFORM_DIR" || {
  echo "❌ Error: Could not find Terraform directory at $TERRAFORM_DIR"
  exit 1
}

# Initialize Terraform (if not already initialized)
if [ ! -d ".terraform" ]; then
  echo "🔧 Initializing Terraform..."
  terraform init -backend=false
fi

# Apply Terraform with the specified Grafana host
echo "🔄 Applying Terraform configuration with Grafana host: $GRAFANA_HOST"
terraform apply \
  -var="grafana_host=$GRAFANA_HOST" \
  -auto-approve

# Add to /etc/hosts if not already present
if ! grep -q "$GRAFANA_HOST" /etc/hosts; then
  echo "📝 Adding $GRAFANA_HOST to /etc/hosts (requires sudo)"
  echo "127.0.0.1 $GRAFANA_HOST" | sudo tee -a /etc/hosts
fi

echo "✅ Done! Grafana should be available at: http://$GRAFANA_HOST"
echo "   Default credentials: admin / admin123"

# Instructions for port-forwarding
echo -e "\nTo access Grafana, run:"
echo "kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 80:80"
echo -e "\nThen open: http://$GRAFANA_HOST"
