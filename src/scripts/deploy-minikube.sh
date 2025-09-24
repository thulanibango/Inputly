#!/usr/bin/env bash
set -euo pipefail

# Deploy Inputly to Minikube end-to-end:
# - Start Minikube and enable ingress
# - Build backend and frontend images inside Minikube Docker
# - Apply Terraform to install Helm charts (API, Frontend, Ingress)
#
# Env vars (optional):
#   MINIKUBE_PROFILE=minikube
#   JWT_SECRET=dev
#   DATABASE_URL=postgres://user:pass@host:5432/db
#   HOST=inputly.local
#   # For advanced: override image repos/tags (typically not needed for Minikube)
#   API_IMAGE_REPO=inputly
#   API_IMAGE_TAG=local
#   FE_IMAGE_REPO=inputly-frontend
#   FE_IMAGE_TAG=local

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)

HOST=${HOST:-inputly.local}
API_IMAGE_REPO=${API_IMAGE_REPO:-inputly}
API_IMAGE_TAG=${API_IMAGE_TAG:-local}
FE_IMAGE_REPO=${FE_IMAGE_REPO:-inputly-frontend}
FE_IMAGE_TAG=${FE_IMAGE_TAG:-local}

# 1) Minikube setup
bash "$SCRIPT_DIR/minikube-setup.sh"

# 2) Build images inside Minikube Docker
USE_MINIKUBE_DOCKER=true BACKEND_IMAGE="$API_IMAGE_REPO" BACKEND_TAG="$API_IMAGE_TAG" \
  FRONTEND_IMAGE="$FE_IMAGE_REPO" FRONTEND_TAG="$FE_IMAGE_TAG" \
  bash "$SCRIPT_DIR/build-images.sh"

# 3) Terraform apply
TF_DIR="$REPO_ROOT/infra/terraform"
cd "$TF_DIR"
terraform init -backend=false

if [[ -z "${JWT_SECRET:-}" || -z "${DATABASE_URL:-}" ]]; then
  echo "Warning: JWT_SECRET or DATABASE_URL not set. Using placeholders for demo."
fi

echo "Applying Terraform..."
terraform apply -auto-approve \
  -var="jwt_secret=${JWT_SECRET:-dev}" \
  -var="database_url=${DATABASE_URL:-postgres://user:pass@localhost:5432/db}" \
  -var="host=$HOST" \
  -var="api_image_repository=$API_IMAGE_REPO" \
  -var="api_image_tag=$API_IMAGE_TAG" \
  -var="frontend_image_repository=$FE_IMAGE_REPO" \
  -var="frontend_image_tag=$FE_IMAGE_TAG"

echo "Deployment complete. Test with:"
echo "  curl -H 'Host: $HOST' http://\$(minikube ip)/"
echo "  curl -H 'Host: $HOST' http://\$(minikube ip)/api"
