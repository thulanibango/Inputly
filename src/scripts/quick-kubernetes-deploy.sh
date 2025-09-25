#!/usr/bin/env bash
set -euo pipefail

# 🚀 Inputly - Quick Kubernetes Deployment Script
# This script will deploy Inputly on your local Kubernetes cluster
# Integrates with existing Inputly script architecture

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command_exists node; then
        missing_tools+=("node")
    fi
    
    if ! command_exists docker; then
        missing_tools+=("docker")
    fi
    
    if ! command_exists kubectl; then
        missing_tools+=("kubectl")
    fi
    
    if ! command_exists minikube; then
        missing_tools+=("minikube")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo ""
        echo "Please install missing tools:"
        echo "  macOS: brew install node docker kubectl minikube"
        echo "  Ubuntu: See DEPLOYMENT.md for installation instructions"
        echo ""
        exit 1
    fi
    
    print_success "All prerequisites found!"
}

# Check Docker is running
check_docker() {
    print_status "Checking Docker status..."
    
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running!"
        echo ""
        echo "Please start Docker Desktop and try again."
        echo "  macOS: Open Docker Desktop app"
        echo "  Linux: sudo systemctl start docker"
        echo ""
        exit 1
    fi
    
    print_success "Docker is running!"
}

# Start minikube
start_minikube() {
    print_status "Starting minikube..."
    
    if minikube status >/dev/null 2>&1; then
        print_warning "Minikube is already running"
    else
        print_status "Starting minikube cluster (this may take a few minutes)..."
        minikube start --driver=docker
        print_success "Minikube started!"
    fi
    
    print_status "Enabling ingress addon..."
    minikube addons enable ingress
    print_success "Ingress enabled!"
}

# Build Docker images
build_images() {
    print_status "Building Docker images..."
    
    # Switch to minikube's Docker environment
    eval $(minikube docker-env)
    
    print_status "Building backend image..."
    docker build -t inputly:local "$REPO_ROOT" > /dev/null 2>&1
    
    print_status "Building frontend image..."
    docker build -t inputly-frontend:local "$REPO_ROOT/client/" > /dev/null 2>&1
    
    print_success "Docker images built successfully!"
}

# Deploy to Kubernetes
deploy_kubernetes() {
    print_status "Deploying to Kubernetes..."
    
    # Apply the deployment
    kubectl apply -f "$REPO_ROOT/k8s-deployment.yaml"
    
    print_status "Waiting for deployments to be ready (up to 2 minutes)..."
    if kubectl wait --for=condition=available --timeout=120s deployment/inputly-api deployment/inputly-frontend; then
        print_success "Deployments are ready!"
    else
        print_warning "Deployments are taking longer than expected..."
        print_status "Checking pod status..."
        kubectl get pods
    fi
}

# Setup port forwarding
setup_port_forwarding() {
    print_status "Setting up port forwarding..."
    
    # Kill any existing port forwards
    pkill -f "kubectl port-forward" 2>/dev/null || true
    
    # Start port forwarding in background
    kubectl port-forward svc/inputly-frontend-service 8080:80 >/dev/null 2>&1 &
    kubectl port-forward svc/inputly-api-service 8081:3000 >/dev/null 2>&1 &
    
    # Wait a moment for port forwarding to establish
    sleep 3
    
    print_success "Port forwarding established!"
}

# Test deployment
test_deployment() {
    print_status "Testing deployment..."
    
    # Test API health endpoint
    if curl -s http://localhost:8081/health >/dev/null 2>&1; then
        print_success "API is responding!"
    else
        print_warning "API health check failed - it may still be starting up"
    fi
    
    # Test frontend
    if curl -s http://localhost:8080 >/dev/null 2>&1; then
        print_success "Frontend is responding!"
    else
        print_warning "Frontend check failed - it may still be starting up"
    fi
}

# Print success message
print_final_message() {
    echo ""
    echo "🎉 Inputly deployment complete!"
    echo ""
    echo "Access your application:"
    echo "  Frontend:    http://localhost:8080"
    echo "  Backend API: http://localhost:8081"
    echo "  Health:      http://localhost:8081/health"
    echo ""
    echo "Useful commands:"
    echo "  kubectl get pods              # Check pod status"
    echo "  kubectl logs deployment/inputly-api -f  # View API logs"
    echo "  minikube dashboard            # Kubernetes dashboard"
    echo ""
    echo "To stop:"
    echo "  pkill -f 'kubectl port-forward'  # Stop port forwarding"
    echo "  kubectl delete -f k8s-deployment.yaml  # Remove app"
    echo "  minikube stop                 # Stop cluster"
    echo ""
}

# Cleanup function
cleanup() {
    print_error "Deployment interrupted!"
    print_status "Cleaning up..."
    pkill -f "kubectl port-forward" 2>/dev/null || true
    exit 1
}

# Main execution
main() {
    echo "🚀 Inputly - Quick Deployment Script"
    echo "===================================="
    echo ""
    
    # Set up trap for cleanup on interrupt
    trap cleanup INT TERM
    
    # Run deployment steps
    check_prerequisites
    check_docker
    start_minikube
    build_images
    deploy_kubernetes
    setup_port_forwarding
    test_deployment
    print_final_message
    
    print_success "Deployment completed successfully! 🚀"
}

# Run main function
main "$@"