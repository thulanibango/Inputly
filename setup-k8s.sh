#!/bin/bash
set -e

echo "🚀 Setting up Inputly Kubernetes Environment"

# Step 1: Start minikube if not running
echo "📦 Starting minikube..."
if ! minikube status &>/dev/null; then
    minikube start --driver=docker
    echo "✅ Minikube started successfully"
else
    echo "✅ Minikube is already running"
fi

# Step 2: Enable ingress addon
echo "🌐 Enabling ingress addon..."
minikube addons enable ingress

# Step 3: Use minikube's docker environment
echo "🔧 Configuring Docker environment..."
eval $(minikube docker-env)

# Step 4: Build Docker images in minikube's docker
echo "🏗️ Building backend Docker image..."
docker build -t inputly:local .

echo "🏗️ Building frontend Docker image..."
docker build -t inputly-frontend:local client/

# Step 5: Setup /etc/hosts entry
echo "📝 Setting up /etc/hosts entry..."
MINIKUBE_IP=$(minikube ip)
if ! grep -q "inputly.local" /etc/hosts; then
    echo "Adding inputly.local to /etc/hosts (requires sudo)"
    echo "$MINIKUBE_IP inputly.local" | sudo tee -a /etc/hosts
else
    echo "✅ inputly.local already in /etc/hosts"
fi

# Step 6: Deploy services using Helm
echo "⚡ Deploying backend service..."
helm install inputly-api deploy/helm/inputly-api -f deploy/helm/inputly-api/values-minikube.yaml 2>/dev/null || \
helm upgrade inputly-api deploy/helm/inputly-api -f deploy/helm/inputly-api/values-minikube.yaml

echo "⚡ Deploying frontend service..."
helm install inputly-frontend deploy/helm/inputly-frontend -f deploy/helm/inputly-frontend/values-minikube.yaml 2>/dev/null || \
helm upgrade inputly-frontend deploy/helm/inputly-frontend -f deploy/helm/inputly-frontend/values-minikube.yaml

echo "⚡ Deploying ingress..."
helm install inputly-ingress deploy/helm/inputly-ingress 2>/dev/null || \
helm upgrade inputly-ingress deploy/helm/inputly-ingress

# Step 7: Wait for deployments
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/inputly-api
kubectl wait --for=condition=available --timeout=300s deployment/inputly-frontend

# Step 8: Show status
echo ""
echo "🎉 Deployment Complete!"
echo "📊 Status:"
kubectl get pods,svc,ingress

echo ""
echo "🌐 Access your application:"
echo "Frontend: http://inputly.local"
echo "Backend API: http://inputly.local/api"

echo ""
echo "🔍 Useful commands:"
echo "  kubectl get pods              # Check pod status"
echo "  kubectl logs -f <pod-name>    # View logs"
echo "  minikube dashboard            # Open Kubernetes dashboard"
echo "  minikube tunnel               # Enable LoadBalancer services (if needed)"