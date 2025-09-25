#!/usr/bin/env bash
set -euo pipefail

# Start Minikube (if not running) and enable ingress addon

if ! command -v minikube >/dev/null 2>&1; then
  echo "Minikube is not installed. Please install Minikube first: https://minikube.sigs.k8s.io/docs/start/"
  exit 1
fi

PROFILE=${MINIKUBE_PROFILE:-minikube}

if ! minikube status -p "$PROFILE" >/dev/null 2>&1; then
  echo "Starting Minikube profile '$PROFILE'..."
  minikube start -p "$PROFILE"
else
  echo "Minikube profile '$PROFILE' already running."
fi

echo "Enabling ingress addon..."
minikube addons enable ingress -p "$PROFILE"

echo "Minikube IP: $(minikube ip -p "$PROFILE")"
echo "Done."
