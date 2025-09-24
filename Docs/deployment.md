# 🚀 Inputly Deployment Guide

This comprehensive guide covers all deployment methods for Inputly, from local development to production Kubernetes environments.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Deployment](#quick-deployment)
- [Local Development](#local-development)
- [Docker Deployment](#docker-deployment)
- [Kubernetes Deployment](#kubernetes-deployment)
- [Production Deployment](#production-deployment)
- [Environment Configuration](#environment-configuration)
- [Troubleshooting](#troubleshooting)

## 📋 Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Node.js | 20+ | JavaScript runtime |
| npm | 8+ | Package manager |
| Docker Desktop | Latest | Containerization |
| Minikube | Latest | Local Kubernetes |
| kubectl | Latest | Kubernetes CLI |
| Helm | 3.x | Kubernetes package manager |
| Terraform | 1.x | Infrastructure as Code |

### System Requirements

- **Memory**: 8GB RAM minimum (16GB recommended)
- **Storage**: 10GB free space
- **OS**: macOS, Linux, or Windows with WSL2

## ⚡ Quick Deployment

### One-Command Setup
```bash
git clone https://github.com/thulanibango/Inputly.git
cd Inputly
./src/scripts/quick-start.sh
```

This script automatically:
- ✅ Installs all prerequisites via Homebrew
- ✅ Starts Minikube with proper configuration
- ✅ Builds and deploys the application
- ✅ Sets up monitoring (Prometheus + Grafana)
- ✅ Configures access to all services

### Installation Script
```bash
./src/scripts/install-prerequisites.sh
```

## 🔧 Local Development

### Method 1: Node.js Native
```bash
# Clone repository
git clone https://github.com/thulanibango/Inputly.git
cd Inputly

# Install dependencies
npm install

# Setup environment
cp .env.example .env.development
# Edit .env.development with your database credentials

# Run database migrations
npm run db:migrate

# Start development server
npm run dev
# OR
./src/scripts/run-app.sh local
```

**Access**: http://localhost:3000

### Method 2: Using the Run Script
```bash
./src/scripts/run-app.sh local
```

### Development Features
- ✅ Hot reload with `--watch` flag
- ✅ Automatic environment setup
- ✅ Database migration handling
- ✅ Error handling with graceful fallback

## 🐳 Docker Deployment

### Development Mode
```bash
# Using run script (recommended)
./src/scripts/run-app.sh docker-dev --logs

# Or using Docker Compose directly
docker-compose -f docker-compose.dev.yml up --build
```

**Includes**:
- Neon Local database proxy
- Application with hot reload
- Volume mounting for development

### Production Mode
```bash
# Using run script
./src/scripts/run-app.sh docker-prod

# Or using Docker Compose directly
docker-compose -f docker-compose.prod.yml up --build -d
```

**Features**:
- Optimized production build
- Multi-stage Docker builds
- Health checks and restart policies
- Minimal attack surface

### Docker Configuration

#### Development Environment (.env.development)
```bash
NODE_ENV=development
PORT=3000
DATABASE_URL=postgres://neon:npg@neon-local:5432/neondb
JWT_SECRET=dev-secret-key
ARCJET_KEY=your-arcjet-key
```

#### Production Environment (.env.production)
```bash
NODE_ENV=production
PORT=3000
DATABASE_URL=postgres://user:pass@your-neon-host.neon.tech/dbname
JWT_SECRET=your-super-secret-jwt-key
ARCJET_KEY=your-arcjet-key
```

## ☸️ Kubernetes Deployment

### Local Kubernetes (Minikube)

#### Method 1: Complete Deployment
```bash
./src/scripts/run-app.sh kubernetes --build
```

#### Method 2: Step by Step
```bash
# 1. Setup Minikube
./src/scripts/minikube-setup.sh

# 2. Build images
./src/scripts/build-images.sh

# 3. Deploy application
./src/scripts/deploy-minikube.sh

# 4. Deploy monitoring
./src/scripts/deploy-monitoring.sh

# 5. Fix monitoring configuration
./src/scripts/fix-monitoring.sh
```

#### Method 3: Manual Kubernetes Deployment

**1. Create Namespace**
```bash
kubectl create namespace inputly
```

**2. Deploy Database Secrets**
```bash
kubectl create secret generic inputly-secrets \
  --from-literal=jwt-secret="your-jwt-secret" \
  --from-literal=database-url="your-database-url" \
  --from-literal=arcjet-key="your-arcjet-key" \
  -n inputly
```

**3. Deploy with Helm**
```bash
# API Service
helm install inputly-api ./deploy/helm/inputly-api \
  --namespace inputly \
  --set image.repository=inputly \
  --set image.tag=local

# Frontend Service
helm install inputly-frontend ./deploy/helm/inputly-frontend \
  --namespace inputly \
  --set image.repository=inputly-frontend \
  --set image.tag=local

# Ingress
helm install inputly-ingress ./deploy/helm/inputly-ingress \
  --namespace inputly \
  --set ingress.host=inputly.local
```

**4. Access Application**
```bash
# Add to /etc/hosts
echo "$(minikube ip) inputly.local" | sudo tee -a /etc/hosts

# Test application
curl -H "Host: inputly.local" http://$(minikube ip)/
```

### Production Kubernetes

#### Using Terraform (Recommended)
```bash
cd infra/terraform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan \
  -var="jwt_secret=your-jwt-secret" \
  -var="database_url=your-database-url" \
  -var="host=your-domain.com"

# Apply deployment
terraform apply \
  -var="jwt_secret=your-jwt-secret" \
  -var="database_url=your-database-url" \
  -var="host=your-domain.com"
```

#### Manual Production Deployment

**1. Container Registry**
```bash
# Tag images for your registry
docker tag inputly:local your-registry.com/inputly:v1.0.0
docker tag inputly-frontend:local your-registry.com/inputly-frontend:v1.0.0

# Push to registry
docker push your-registry.com/inputly:v1.0.0
docker push your-registry.com/inputly-frontend:v1.0.0
```

**2. Production Values**
```bash
# Deploy with production values
helm install inputly-api ./deploy/helm/inputly-api \
  --namespace production \
  --set image.repository=your-registry.com/inputly \
  --set image.tag=v1.0.0 \
  --set ingress.host=your-domain.com \
  --set resources.requests.cpu=500m \
  --set resources.requests.memory=512Mi \
  --set replicas=3
```

## 🌐 Production Deployment

### Cloud Platforms

#### AWS EKS
```bash
# Create EKS cluster
eksctl create cluster --name inputly-prod --region us-west-2

# Deploy application
kubectl apply -k deploy/kubernetes/overlays/production/
```

#### Google GKE
```bash
# Create GKE cluster
gcloud container clusters create inputly-prod \
  --zone us-central1-a \
  --num-nodes 3

# Deploy application
kubectl apply -k deploy/kubernetes/overlays/production/
```

#### Azure AKS
```bash
# Create AKS cluster
az aks create \
  --resource-group inputly-rg \
  --name inputly-prod \
  --node-count 3 \
  --enable-addons monitoring

# Deploy application
kubectl apply -k deploy/kubernetes/overlays/production/
```

### Monitoring Deployment

#### Complete Monitoring Stack
```bash
./src/scripts/deploy-monitoring.sh
```

#### Manual Monitoring Deployment
```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Deploy kube-prometheus-stack
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword=admin123 \
  --set grafana.ingress.enabled=true \
  --set grafana.ingress.hosts[0]=grafana.local
```

## ⚙️ Environment Configuration

### Environment Files

| File | Purpose | Required Variables |
|------|---------|-------------------|
| `.env.development` | Local development | DATABASE_URL, JWT_SECRET |
| `.env.production` | Production deployment | All production secrets |
| `.env.test` | Testing environment | Test database credentials |

### Required Environment Variables

```bash
# Application
NODE_ENV=production                    # Environment mode
PORT=3000                             # Application port

# Database
DATABASE_URL=postgres://...           # PostgreSQL connection string

# Authentication
JWT_SECRET=your-super-secret-key      # JWT signing secret
JWT_EXPIRES_IN=7d                     # Token expiration

# Security
ARCJET_KEY=ajkey_...                  # Arcjet API key

# Monitoring (optional)
PROMETHEUS_ENABLED=true               # Enable metrics collection
LOG_LEVEL=info                        # Logging level
```

### Database Configuration

#### Neon Database (Recommended)
```bash
# Development
DATABASE_URL=postgres://user:pass@ep-xxx.us-east-1.neon.tech/dbname

# Production with connection pooling
DATABASE_URL=postgres://user:pass@ep-xxx-pooler.us-east-1.neon.tech/dbname?pgbouncer=true
```

#### Self-hosted PostgreSQL
```bash
DATABASE_URL=postgres://user:pass@your-postgres-host:5432/dbname?sslmode=require
```

## 🔄 CI/CD Pipeline

### GitHub Actions Example
```yaml
name: Deploy to Kubernetes

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build and Push Images
        run: |
          docker build -t ${{ secrets.REGISTRY }}/inputly:${{ github.sha }} .
          docker push ${{ secrets.REGISTRY }}/inputly:${{ github.sha }}
      
      - name: Deploy to Kubernetes
        run: |
          helm upgrade --install inputly-api ./deploy/helm/inputly-api \
            --set image.tag=${{ github.sha }} \
            --namespace production
```

### GitLab CI Example
```yaml
stages:
  - build
  - deploy

build:
  stage: build
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

deploy:
  stage: deploy
  script:
    - helm upgrade --install inputly ./deploy/helm/inputly-api
        --set image.tag=$CI_COMMIT_SHA
```

## 📊 Health Checks

### Application Health
```bash
# Health check endpoint
curl http://localhost:3000/health

# Expected response
{
  "status": "OK",
  "message": "Inputly is running",
  "timestamp": "2024-01-20T10:30:00.000Z",
  "uptime": 3600,
  "memoryUsage": {
    "rss": 67108864,
    "heapTotal": 29360128,
    "heapUsed": 20971520,
    "external": 1638400
  }
}
```

### Kubernetes Health
```bash
# Check pod status
kubectl get pods -n inputly

# Check service endpoints
kubectl get endpoints -n inputly

# Check ingress
kubectl get ingress -n inputly
```

## 🛠️ Troubleshooting

### Common Deployment Issues

#### 1. Minikube Won't Start
```bash
# Delete and recreate
minikube delete
minikube start --driver=docker

# Check system resources
minikube status
docker system df
```

#### 2. Images Not Found
```bash
# Ensure you're using Minikube's Docker daemon
eval $(minikube docker-env)

# Rebuild images
./src/scripts/build-images.sh

# Check images exist
docker images | grep inputly
```

#### 3. Database Connection Issues
```bash
# Test database connectivity
kubectl exec -it deployment/inputly-api -n inputly -- \
  node -e "console.log(process.env.DATABASE_URL)"

# Check secrets
kubectl get secrets -n inputly
kubectl describe secret inputly-secrets -n inputly
```

#### 4. Ingress Not Working
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Verify ingress resource
kubectl describe ingress inputly-ingress -n inputly

# Test with curl
curl -H "Host: inputly.local" http://$(minikube ip)/
```

### Monitoring Issues

#### Grafana Not Accessible
```bash
# Check Grafana pod
kubectl get pods -n monitoring | grep grafana

# Check service
kubectl get svc -n monitoring | grep grafana

# Port forward for testing
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring
```

#### Metrics Not Showing
```bash
# Check ServiceMonitor
kubectl get servicemonitor -n inputly

# Check Prometheus targets
kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring
# Visit http://localhost:9090/targets

# Test metrics endpoint
curl http://$(minikube ip)/metrics -H "Host: inputly.local"
```

### Performance Tuning

#### Resource Optimization
```bash
# Check resource usage
kubectl top pods -n inputly

# Adjust resources in Helm values
helm upgrade inputly-api ./deploy/helm/inputly-api \
  --set resources.requests.cpu=250m \
  --set resources.requests.memory=256Mi \
  --set resources.limits.cpu=1000m \
  --set resources.limits.memory=1Gi
```

#### Database Connection Pooling
```bash
# Use connection pooler for production
DATABASE_URL=postgres://user:pass@pooler-host.neon.tech/dbname?pgbouncer=true&pool_timeout=30
```

## 📝 Deployment Checklist

### Pre-deployment
- [ ] All environment variables configured
- [ ] Database migrations tested
- [ ] Images built and tagged
- [ ] Secrets created in target namespace
- [ ] Resource limits configured

### Deployment
- [ ] Application pods running
- [ ] Services accessible
- [ ] Ingress configured
- [ ] SSL certificates valid
- [ ] Health checks passing

### Post-deployment
- [ ] Monitoring dashboards working
- [ ] Logs being collected
- [ ] Alerts configured
- [ ] Backup strategy implemented
- [ ] Performance tested

### Production Readiness
- [ ] Security scan completed
- [ ] Load testing passed
- [ ] Disaster recovery tested
- [ ] Documentation updated
- [ ] Team trained

## 🔗 Additional Resources

- [Architecture Overview](./architecture.md)
- [API Documentation](./api.md)
- [Security Guide](./security.md)
- [Monitoring Guide](./monitoring.md)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Terraform Documentation](https://terraform.io/docs/)

---

For deployment support, create an issue on [GitHub](https://github.com/thulanibango/Inputly/issues) or check the [troubleshooting section](../README.md#troubleshooting) in the main README.