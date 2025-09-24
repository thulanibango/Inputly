#!/usr/bin/env bash
set -euo pipefail

# Build backend and frontend images, optionally inside Minikube Docker
# Env vars (optional):
#   USE_MINIKUBE_DOCKER=true|false (default: true)
#   BACKEND_IMAGE=inputly
#   BACKEND_TAG=local
#   FRONTEND_IMAGE=inputly-frontend
#   FRONTEND_TAG=local

USE_MINIKUBE_DOCKER=${USE_MINIKUBE_DOCKER:-true}
BACKEND_IMAGE=${BACKEND_IMAGE:-inputly}
BACKEND_TAG=${BACKEND_TAG:-local}
FRONTEND_IMAGE=${FRONTEND_IMAGE:-inputly-frontend}
FRONTEND_TAG=${FRONTEND_TAG:-local}
PROFILE=${MINIKUBE_PROFILE:-minikube}

if [[ "$USE_MINIKUBE_DOCKER" == "true" ]]; then
  if ! command -v minikube >/dev/null 2>&1; then
    echo "Minikube not installed. Install from https://minikube.sigs.k8s.io/docs/start/"
    exit 1
  fi
  echo "Switching Docker daemon to Minikube profile '$PROFILE'..."
  # shellcheck disable=SC2046
  eval $(minikube -p "$PROFILE" docker-env)
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)

cd "$REPO_ROOT"

echo "Building backend image: ${BACKEND_IMAGE}:${BACKEND_TAG}"
docker build -t "${BACKEND_IMAGE}:${BACKEND_TAG}" -f Dockerfile .

echo "Building frontend image: ${FRONTEND_IMAGE}:${FRONTEND_TAG}"
docker build -t "${FRONTEND_IMAGE}:${FRONTEND_TAG}" ./client

echo "Images built:"
docker images | grep -E "(${BACKEND_IMAGE}|${FRONTEND_IMAGE})\s+(${BACKEND_TAG}|${FRONTEND_TAG})" || true

echo "Done."
