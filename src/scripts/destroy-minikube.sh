#!/usr/bin/env bash
set -euo pipefail

# Destroy Inputly resources deployed via Terraform
# Optional env:
#   MINIKUBE_PROFILE=minikube (unused here but kept for symmetry)

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)

TF_DIR="$REPO_ROOT/infra/terraform"
cd "$TF_DIR"

echo "Initializing Terraform..."
terraform init -backend=false

echo "Destroying Kubernetes resources managed by Terraform..."
terraform destroy -auto-approve || {
  echo "Terraform destroy failed. You may inspect resources with: kubectl get all -n inputly" >&2
  exit 1
}

echo "Destroyed Terraform-managed resources."
