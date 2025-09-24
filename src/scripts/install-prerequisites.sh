#!/usr/bin/env bash
set -euo pipefail

# Complete installation script for Inputly monitoring stack
# Installs all prerequisites and sets up the monitoring environment

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

echo -e "${PURPLE}🚀 Inputly Monitoring Stack Installation${NC}"
echo "========================================"
echo -e "${BLUE}This script will install and configure:${NC}"
echo "• Homebrew (if not installed)"
echo "• Docker Desktop"
echo "• Minikube"
echo "• kubectl"
echo "• Helm"
echo "• Terraform"
echo "• Complete monitoring stack (Prometheus + Grafana)"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if Homebrew is installed
check_homebrew() {
    if command_exists brew; then
        echo -e "${GREEN}✅ Homebrew is already installed${NC}"
        return 0
    else
        echo -e "${YELLOW}📦 Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for current session
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zshrc
        fi
        
        echo -e "${GREEN}✅ Homebrew installed${NC}"
        return 0
    fi
}

# Function to install Docker Desktop
install_docker() {
    if command_exists docker; then
        echo -e "${GREEN}✅ Docker is already installed${NC}"
        # Check if Docker is running
        if docker info >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Docker is running${NC}"
        else
            echo -e "${YELLOW}⚠️ Docker is installed but not running. Please start Docker Desktop.${NC}"
            echo -e "${BLUE}Opening Docker Desktop...${NC}"
            open -a "Docker Desktop" 2>/dev/null || echo "Please start Docker Desktop manually"
            echo "Waiting for Docker to start..."
            until docker info >/dev/null 2>&1; do
                sleep 2
                echo -n "."
            done
            echo ""
            echo -e "${GREEN}✅ Docker is now running${NC}"
        fi
    else
        echo -e "${YELLOW}🐳 Installing Docker Desktop...${NC}"
        echo -e "${BLUE}Note: This will download and install Docker Desktop. Please follow the installer prompts.${NC}"
        
        # Download and install Docker Desktop
        curl -o ~/Downloads/Docker.dmg https://desktop.docker.com/mac/main/amd64/Docker.dmg
        
        echo -e "${BLUE}Please manually install Docker Desktop from ~/Downloads/Docker.dmg${NC}"
        echo -e "${YELLOW}After installation:${NC}"
        echo "1. Open Docker Desktop"
        echo "2. Complete the setup"
        echo "3. Re-run this script"
        exit 1
    fi
}

# Function to install Kubernetes tools
install_k8s_tools() {
    echo -e "\n${YELLOW}⚙️ Installing Kubernetes tools...${NC}"
    
    # Install kubectl
    if command_exists kubectl; then
        echo -e "${GREEN}✅ kubectl is already installed${NC}"
    else
        echo -e "${BLUE}Installing kubectl...${NC}"
        brew install kubectl
        echo -e "${GREEN}✅ kubectl installed${NC}"
    fi
    
    # Install minikube
    if command_exists minikube; then
        echo -e "${GREEN}✅ minikube is already installed${NC}"
    else
        echo -e "${BLUE}Installing minikube...${NC}"
        brew install minikube
        echo -e "${GREEN}✅ minikube installed${NC}"
    fi
    
    # Install helm
    if command_exists helm; then
        echo -e "${GREEN}✅ helm is already installed${NC}"
    else
        echo -e "${BLUE}Installing helm...${NC}"
        brew install helm
        echo -e "${GREEN}✅ helm installed${NC}"
    fi
    
    # Install terraform
    if command_exists terraform; then
        echo -e "${GREEN}✅ terraform is already installed${NC}"
    else
        echo -e "${BLUE}Installing terraform...${NC}"
        brew install terraform
        echo -e "${GREEN}✅ terraform installed${NC}"
    fi
}

# Function to start and configure Minikube
setup_minikube() {
    echo -e "\n${YELLOW}🎯 Setting up Minikube...${NC}"
    
    # Check if minikube is running
    if minikube status >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Minikube is already running${NC}"
    else
        echo -e "${BLUE}Starting Minikube...${NC}"
        minikube start --driver=docker
        echo -e "${GREEN}✅ Minikube started${NC}"
    fi
    
    # Enable ingress addon
    echo -e "${BLUE}Enabling ingress addon...${NC}"
    minikube addons enable ingress
    echo -e "${GREEN}✅ Ingress addon enabled${NC}"
    
    # Enable metrics-server addon
    echo -e "${BLUE}Enabling metrics-server addon...${NC}"
    minikube addons enable metrics-server
    echo -e "${GREEN}✅ Metrics-server addon enabled${NC}"
    
    echo -e "${BLUE}Minikube IP: $(minikube ip)${NC}"
}

# Function to build and deploy the application
deploy_application() {
    echo -e "\n${YELLOW}🏗️ Building and deploying application...${NC}"
    
    cd "$SCRIPT_DIR/../.."
    
    # Build images using existing script
    if [[ -f "$SCRIPT_DIR/build-images.sh" ]]; then
        echo -e "${BLUE}Building application images...${NC}"
        USE_MINIKUBE_DOCKER=true bash "$SCRIPT_DIR/build-images.sh"
        echo -e "${GREEN}✅ Application images built${NC}"
    else
        echo -e "${YELLOW}⚠️ build-images.sh not found, skipping image build${NC}"
    fi
}

# Function to deploy monitoring stack
deploy_monitoring() {
    echo -e "\n${YELLOW}📊 Deploying monitoring stack...${NC}"
    
    # Deploy monitoring using existing script
    if [[ -f "$SCRIPT_DIR/deploy-monitoring.sh" ]]; then
        bash "$SCRIPT_DIR/deploy-monitoring.sh"
        echo -e "${GREEN}✅ Monitoring stack deployed${NC}"
    else
        echo -e "${RED}❌ deploy-monitoring.sh not found${NC}"
        return 1
    fi
}

# Function to apply monitoring fixes
apply_monitoring_fixes() {
    echo -e "\n${YELLOW}🔧 Applying monitoring fixes...${NC}"
    
    if [[ -f "$SCRIPT_DIR/fix-monitoring.sh" ]]; then
        bash "$SCRIPT_DIR/fix-monitoring.sh"
        echo -e "${GREEN}✅ Monitoring fixes applied${NC}"
    else
        echo -e "${YELLOW}⚠️ fix-monitoring.sh not found, skipping fixes${NC}"
    fi
}

# Function to setup Grafana access
setup_grafana_access() {
    echo -e "\n${YELLOW}🌐 Setting up Grafana access...${NC}"
    
    # Add grafana.local to hosts file
    if grep -q "grafana.local" /etc/hosts; then
        echo -e "${GREEN}✅ grafana.local already in /etc/hosts${NC}"
    else
        echo -e "${BLUE}Adding grafana.local to /etc/hosts (requires sudo)...${NC}"
        echo "127.0.0.1 grafana.local" | sudo tee -a /etc/hosts >/dev/null
        echo -e "${GREEN}✅ Added grafana.local to /etc/hosts${NC}"
    fi
}

# Function to verify the installation
verify_installation() {
    echo -e "\n${YELLOW}🔍 Verifying installation...${NC}"
    
    # Run verification script if it exists
    if [[ -f "$SCRIPT_DIR/verify-metrics.sh" ]]; then
        bash "$SCRIPT_DIR/verify-metrics.sh"
    else
        echo -e "${BLUE}Manual verification:${NC}"
        kubectl get pods -A
    fi
}

# Function to show final instructions
show_final_instructions() {
    echo -e "\n${GREEN}🎉 Installation Complete!${NC}"
    echo "======================================"
    echo -e "${BLUE}Your monitoring stack is ready. Here's how to access it:${NC}"
    echo ""
    echo -e "${YELLOW}1. Access Grafana:${NC}"
    echo "   kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 80:80"
    echo "   Then visit: http://grafana.local"
    echo "   Credentials: admin / admin123"
    echo ""
    echo -e "${YELLOW}2. Access Prometheus:${NC}"
    echo "   kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090"
    echo "   Then visit: http://localhost:9090"
    echo ""
    echo -e "${YELLOW}3. Test your application:${NC}"
    echo "   curl -H 'Host: inputly.local' http://\$(minikube ip)/"
    echo "   curl -H 'Host: inputly.local' http://\$(minikube ip)/metrics"
    echo ""
    echo -e "${BLUE}Useful commands:${NC}"
    echo "   minikube dashboard  # Kubernetes dashboard"
    echo "   kubectl get pods -A # View all pods"
    echo "   minikube stop       # Stop minikube"
    echo "   minikube start      # Start minikube"
    echo ""
    echo -e "${GREEN}Happy monitoring! 🚀${NC}"
}

# Main installation flow
main() {
    echo -e "${BLUE}Starting installation...${NC}"
    
    # Step 1: Install Homebrew
    echo -e "\n${PURPLE}Step 1: Homebrew${NC}"
    check_homebrew
    
    # Step 2: Install Docker
    echo -e "\n${PURPLE}Step 2: Docker Desktop${NC}"
    install_docker
    
    # Step 3: Install Kubernetes tools
    echo -e "\n${PURPLE}Step 3: Kubernetes Tools${NC}"
    install_k8s_tools
    
    # Step 4: Setup Minikube
    echo -e "\n${PURPLE}Step 4: Minikube Setup${NC}"
    setup_minikube
    
    # Step 5: Deploy application
    echo -e "\n${PURPLE}Step 5: Application Deployment${NC}"
    deploy_application
    
    # Step 6: Deploy monitoring
    echo -e "\n${PURPLE}Step 6: Monitoring Stack${NC}"
    deploy_monitoring
    
    # Step 7: Apply fixes
    echo -e "\n${PURPLE}Step 7: Monitoring Fixes${NC}"
    apply_monitoring_fixes
    
    # Step 8: Setup Grafana access
    echo -e "\n${PURPLE}Step 8: Grafana Access${NC}"
    setup_grafana_access
    
    # Step 9: Verify installation
    echo -e "\n${PURPLE}Step 9: Verification${NC}"
    verify_installation
    
    # Step 10: Show instructions
    show_final_instructions
}

# Check if script is run with --help
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Inputly Monitoring Stack Installation Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --skip-docker  Skip Docker installation check"
    echo ""
    echo "This script installs all prerequisites and sets up the complete monitoring stack."
    exit 0
fi

# Run main installation
main

echo -e "\n${GREEN}Installation script completed! 🎉${NC}"