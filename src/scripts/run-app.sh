#!/usr/bin/env bash
set -euo pipefail

# Comprehensive script to run Inputly app in different modes
# Supports local development, Docker, and Kubernetes deployments

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Function to show usage
show_usage() {
    echo -e "${BLUE}Inputly Application Runner${NC}"
    echo "========================"
    echo ""
    echo "Usage: $0 [MODE] [OPTIONS]"
    echo ""
    echo -e "${YELLOW}Modes:${NC}"
    echo "  local       - Run locally with Node.js (development)"
    echo "  docker-dev  - Run with Docker Compose (development)"
    echo "  docker-prod - Run with Docker Compose (production)"
    echo "  kubernetes  - Deploy to Minikube/Kubernetes"
    echo "  all         - Deploy everything (K8s + monitoring)"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  --build     - Force rebuild images"
    echo "  --clean     - Clean up before starting"
    echo "  --logs      - Show logs after starting"
    echo "  --help      - Show this help"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 local                    # Run locally"
    echo "  $0 docker-dev --logs       # Run with Docker and show logs"
    echo "  $0 kubernetes --build      # Deploy to K8s with fresh build"
    echo "  $0 all                     # Full deployment with monitoring"
}

# Function to check prerequisites
check_prerequisites() {
    local mode=$1
    
    case $mode in
        local)
            if ! command -v node >/dev/null 2>&1; then
                echo -e "${RED}❌ Node.js is required for local mode${NC}"
                echo "Install with: brew install node"
                exit 1
            fi
            ;;
        docker-*)
            if ! command -v docker >/dev/null 2>&1; then
                echo -e "${RED}❌ Docker is required for Docker mode${NC}"
                echo "Install Docker Desktop"
                exit 1
            fi
            if ! docker info >/dev/null 2>&1; then
                echo -e "${RED}❌ Docker is not running${NC}"
                echo "Please start Docker Desktop"
                exit 1
            fi
            ;;
        kubernetes|all)
            if ! command -v kubectl >/dev/null 2>&1 && ! command -v minikube >/dev/null 2>&1; then
                echo -e "${RED}❌ kubectl or minikube is required for Kubernetes mode${NC}"
                echo "Run: $SCRIPT_DIR/install-prerequisites.sh"
                exit 1
            fi
            ;;
    esac
}

# Function to setup environment
setup_environment() {
    local mode=$1
    
    cd "$REPO_ROOT"
    
    case $mode in
        local)
            if [[ ! -f .env.development ]]; then
                echo -e "${YELLOW}⚠️ Creating .env.development from template${NC}"
                if [[ -f .env.example ]]; then
                    cp .env.example .env.development
                else
                    cat > .env.development << 'EOF'
NODE_ENV=development
PORT=3000
DATABASE_URL=postgres://user:pass@localhost:5432/inputly_dev
JWT_SECRET=your-dev-jwt-secret
EOF
                fi
                echo -e "${BLUE}Please update .env.development with your database credentials${NC}"
            fi
            ;;
        docker-dev)
            if [[ ! -f .env.development ]]; then
                echo -e "${YELLOW}⚠️ .env.development not found, creating template${NC}"
                cat > .env.development << 'EOF'
NODE_ENV=development
PORT=3000
DATABASE_URL=postgres://neon:npg@neon-local:5432/neondb
JWT_SECRET=dev-secret-key
EOF
            fi
            ;;
        docker-prod)
            if [[ ! -f .env.production ]]; then
                echo -e "${RED}❌ .env.production is required for production mode${NC}"
                echo "Create .env.production with your production environment variables"
                exit 1
            fi
            ;;
    esac
}

# Function to run locally
run_local() {
    echo -e "${BLUE}🏃 Running Inputly locally${NC}"
    
    # Install dependencies if needed
    if [[ ! -d node_modules ]]; then
        echo -e "${YELLOW}📦 Installing dependencies...${NC}"
        npm install
    fi
    
    # Run database migrations
    echo -e "${YELLOW}📊 Running database migrations...${NC}"
    npm run db:migrate || echo -e "${YELLOW}⚠️ Migration failed, continuing...${NC}"
    
    # Start the application
    echo -e "${GREEN}✅ Starting application on http://localhost:3000${NC}"
    echo -e "${BLUE}Press Ctrl+C to stop${NC}"
    npm run dev
}

# Function to run with Docker
run_docker() {
    local mode=$1
    local build_flag=$2
    local logs_flag=$3
    
    echo -e "${BLUE}🐳 Running Inputly with Docker (${mode})${NC}"
    
    local compose_file=""
    local service_name=""
    
    case $mode in
        docker-dev)
            compose_file="docker-compose.dev.yml"
            service_name="app"
            ;;
        docker-prod)
            compose_file="docker-compose.prod.yml"
            service_name="app"
            ;;
    esac
    
    # Build flag
    local build_args=""
    if [[ $build_flag == "true" ]]; then
        build_args="--build"
    fi
    
    # Start containers
    echo -e "${YELLOW}📦 Starting containers...${NC}"
    docker compose -f "$compose_file" up $build_args -d
    
    # Wait for services to be ready
    echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
    sleep 10
    
    # Run migrations
    echo -e "${YELLOW}📊 Running database migrations...${NC}"
    docker compose -f "$compose_file" exec "$service_name" npm run db:migrate || echo -e "${YELLOW}⚠️ Migration failed${NC}"
    
    # Show status
    echo -e "${GREEN}✅ Application started!${NC}"
    if [[ $mode == "docker-dev" ]]; then
        echo -e "${BLUE}Application: http://localhost:3000${NC}"
    else
        echo -e "${BLUE}Application: http://localhost:3000${NC}"
    fi
    
    # Show logs if requested
    if [[ $logs_flag == "true" ]]; then
        echo -e "${YELLOW}📋 Showing logs (Ctrl+C to stop logs, containers keep running):${NC}"
        docker compose -f "$compose_file" logs -f
    else
        echo -e "${BLUE}To view logs: docker compose -f $compose_file logs -f${NC}"
        echo -e "${BLUE}To stop: docker compose -f $compose_file down${NC}"
    fi
}

# Function to run on Kubernetes
run_kubernetes() {
    local build_flag=$1
    
    echo -e "${BLUE}☸️ Deploying Inputly to Kubernetes${NC}"
    
    # Check if Minikube is running
    if ! kubectl cluster-info >/dev/null 2>&1 && ! minikube status >/dev/null 2>&1; then
        echo -e "${YELLOW}🚀 Starting Minikube...${NC}"
        minikube start
    fi
    
    # Build images if requested
    if [[ $build_flag == "true" ]] || [[ ! $(docker images -q inputly:local) ]]; then
        echo -e "${YELLOW}🏗️ Building application images...${NC}"
        USE_MINIKUBE_DOCKER=true bash "$SCRIPT_DIR/build-images.sh"
    fi
    
    # Deploy application
    echo -e "${YELLOW}🚀 Deploying application...${NC}"
    bash "$SCRIPT_DIR/deploy-minikube.sh"
    
    # Show access information
    echo -e "${GREEN}✅ Kubernetes deployment completed!${NC}"
    echo -e "${BLUE}Access your application:${NC}"
    echo "  curl -H 'Host: inputly.local' http://\$(minikube ip)/"
    echo "  curl -H 'Host: inputly.local' http://\$(minikube ip)/api"
    echo ""
    echo -e "${BLUE}Useful commands:${NC}"
    echo "  kubectl get pods -n inputly"
    echo "  kubectl logs -n inputly deployment/inputly-api"
    echo "  minikube dashboard"
}

# Function to deploy everything
run_all() {
    local build_flag=$1
    
    echo -e "${PURPLE}🚀 Full Inputly Stack Deployment${NC}"
    echo "================================"
    
    # Install prerequisites if needed
    echo -e "${YELLOW}1. Checking prerequisites...${NC}"
    if [[ -f "$SCRIPT_DIR/install-prerequisites.sh" ]]; then
        bash "$SCRIPT_DIR/install-prerequisites.sh"
    else
        run_kubernetes "$build_flag"
    fi
    
    echo -e "${GREEN}🎉 Full stack deployed!${NC}"
    echo -e "${BLUE}Access points:${NC}"
    echo "  Application: curl -H 'Host: inputly.local' http://\$(minikube ip)/"
    echo "  Grafana: http://grafana.local (admin/admin123)"
    echo "  Prometheus: http://localhost:9090"
}

# Parse arguments
MODE=""
BUILD_FLAG="false"
CLEAN_FLAG="false"
LOGS_FLAG="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        local|docker-dev|docker-prod|kubernetes|all)
            MODE="$1"
            shift
            ;;
        --build)
            BUILD_FLAG="true"
            shift
            ;;
        --clean)
            CLEAN_FLAG="true"
            shift
            ;;
        --logs)
            LOGS_FLAG="true"
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Check if mode is provided
if [[ -z "$MODE" ]]; then
    echo -e "${RED}❌ Please specify a mode${NC}"
    show_usage
    exit 1
fi

# Clean up if requested
if [[ $CLEAN_FLAG == "true" ]]; then
    echo -e "${YELLOW}🧹 Cleaning up...${NC}"
    case $MODE in
        docker-*|all)
            docker compose down -v 2>/dev/null || true
            docker system prune -f
            ;;
        kubernetes|all)
            kubectl delete namespace inputly --ignore-not-found=true
            ;;
    esac
fi

# Main execution
echo -e "${PURPLE}Starting Inputly in ${MODE} mode${NC}"

# Check prerequisites
check_prerequisites "$MODE"

# Setup environment
setup_environment "$MODE"

# Run based on mode
case $MODE in
    local)
        run_local
        ;;
    docker-dev|docker-prod)
        run_docker "$MODE" "$BUILD_FLAG" "$LOGS_FLAG"
        ;;
    kubernetes)
        run_kubernetes "$BUILD_FLAG"
        ;;
    all)
        run_all "$BUILD_FLAG"
        ;;
esac

echo -e "${GREEN}🎉 Inputly is running!${NC}"