#!/usr/bin/env bash
set -euo pipefail

# 🛠️ Inputly - Local Environment Setup Script
# This script will install all required dependencies for running Inputly locally
# Integrates with existing Inputly script architecture

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get >/dev/null 2>&1; then
            OS="ubuntu"
        elif command -v yum >/dev/null 2>&1; then
            OS="centos"
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
    else
        OS="unknown"
    fi
    
    print_status "Detected OS: $OS"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install for macOS
install_macos() {
    print_status "Installing dependencies for macOS..."
    
    # Install Homebrew if not present
    if ! command_exists brew; then
        print_status "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        print_success "Homebrew installed!"
    else
        print_success "Homebrew already installed"
    fi
    
    # Install tools
    local tools=("node" "docker" "kubectl" "minikube")
    for tool in "${tools[@]}"; do
        if ! command_exists "$tool"; then
            print_status "Installing $tool..."
            brew install "$tool"
            print_success "$tool installed!"
        else
            print_success "$tool already installed"
        fi
    done
    
    # Start Docker Desktop if not running
    if ! docker info >/dev/null 2>&1; then
        print_warning "Docker is not running. Starting Docker Desktop..."
        open -a Docker
        print_status "Waiting for Docker to start..."
        while ! docker info >/dev/null 2>&1; do
            sleep 2
        done
        print_success "Docker is now running!"
    fi
}

# Install for Ubuntu/Debian
install_ubuntu() {
    print_status "Installing dependencies for Ubuntu/Debian..."
    
    # Update package list
    print_status "Updating package list..."
    sudo apt-get update -y
    
    # Install Node.js
    if ! command_exists node; then
        print_status "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
        print_success "Node.js installed!"
    else
        print_success "Node.js already installed"
    fi
    
    # Install Docker
    if ! command_exists docker; then
        print_status "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        print_success "Docker installed! (You may need to log out and back in)"
        rm get-docker.sh
    else
        print_success "Docker already installed"
    fi
    
    # Install kubectl
    if ! command_exists kubectl; then
        print_status "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
        print_success "kubectl installed!"
    else
        print_success "kubectl already installed"
    fi
    
    # Install minikube
    if ! command_exists minikube; then
        print_status "Installing minikube..."
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        sudo install minikube-linux-amd64 /usr/local/bin/minikube
        rm minikube-linux-amd64
        print_success "minikube installed!"
    else
        print_success "minikube already installed"
    fi
}

# Install for Windows (using Chocolatey)
install_windows() {
    print_status "Installing dependencies for Windows..."
    print_warning "Please ensure you're running this in an Administrator PowerShell"
    
    # Check for Chocolatey
    if ! command_exists choco; then
        print_error "Chocolatey not found!"
        echo ""
        echo "Please install Chocolatey first by running this in Administrator PowerShell:"
        echo "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
        echo ""
        echo "Then run this script again."
        exit 1
    fi
    
    # Install tools
    local tools=("nodejs" "docker-desktop" "kubectl" "minikube")
    for tool in "${tools[@]}"; do
        print_status "Installing $tool..."
        choco install "$tool" -y
        print_success "$tool installation requested!"
    done
    
    print_warning "Please restart your terminal/PowerShell after installation completes"
}

# Verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    local tools=("node" "npm" "docker" "kubectl" "minikube")
    local all_good=true
    
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            local version=$($tool --version 2>/dev/null | head -1 || echo "installed")
            print_success "$tool: $version"
        else
            print_error "$tool: not found"
            all_good=false
        fi
    done
    
    if $all_good; then
        print_success "All tools installed successfully!"
        return 0
    else
        print_error "Some tools are missing. Please check the installation."
        return 1
    fi
}

# Print next steps
print_next_steps() {
    echo ""
    echo "🎉 Environment setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. Clone the repository:"
    echo "   git clone https://github.com/thulanibango/Inputly.git"
    echo "   cd Inputly"
    echo ""
    echo "2. Run the quick deployment:"
    echo "   ./quick-deploy.sh"
    echo ""
    echo "3. Access your app at http://localhost:8080"
    echo ""
    
    if [[ "$OS" == "ubuntu" ]] && groups $USER | grep -q docker; then
        print_warning "Note: If Docker commands fail, you may need to log out and back in"
        echo "Or run: newgrp docker"
    fi
}

# Main function
main() {
    echo "🛠️ Inputly - Environment Setup"
    echo "==============================="
    echo ""
    
    detect_os
    
    case $OS in
        "macos")
            install_macos
            ;;
        "ubuntu")
            install_ubuntu
            ;;
        "windows")
            install_windows
            ;;
        *)
            print_error "Unsupported operating system: $OS"
            echo ""
            echo "Please install manually:"
            echo "- Node.js 20+"
            echo "- Docker"
            echo "- kubectl"
            echo "- minikube"
            exit 1
            ;;
    esac
    
    echo ""
    if verify_installation; then
        print_next_steps
    else
        print_error "Setup incomplete. Please check the errors above."
        exit 1
    fi
}

# Run main function
main "$@"