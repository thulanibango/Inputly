# 🚀 Inputly - Quick Start

**Deploy Inputly on your local machine in under 5 minutes!**

## ⚡ **Super Quick Start**

```bash
# 1. Clone the repo
git clone https://github.com/thulanibango/Inputly.git
cd Inputly

# 2. Run the magic script
./src/scripts/quick-kubernetes-deploy.sh

# 3. Open http://localhost:8080 🎉
```

**Alternative**: For full monitoring stack, use `./src/scripts/quick-start.sh`

That's it! Your full-stack application with React frontend, Node.js backend, and Kubernetes orchestration is now running locally.

## 📋 **What You Need**

Install these tools first (takes ~5 minutes):

### macOS (easiest):
```bash
brew install node docker kubectl minikube
```

### Ubuntu/Linux:
```bash
# Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Docker
curl -fsSL https://get.docker.com | sh

# kubectl & minikube
sudo snap install kubectl --classic
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

### Windows:
```powershell
# Install chocolatey first, then:
choco install nodejs docker-desktop kubectl minikube
```

## 🚀 **Deployment Options**

### Option 1: Quick Kubernetes Deploy (Recommended)
```bash
./src/scripts/quick-kubernetes-deploy.sh
# OR: npm run k8s:quick-deploy
```

### Option 2: Full Stack with Monitoring
```bash
./src/scripts/quick-start.sh
# OR: npm run setup:quick
```

### Option 3: Using run-app.sh (Existing)
```bash
./src/scripts/run-app.sh kubernetes --build
```

### Option 4: Step-by-step with NPM
```bash
npm run setup:environment    # Install dependencies
npm run k8s:quick-deploy     # Deploy to Kubernetes
npm run k8s:status          # Check status
```

### Option 5: Simple Docker Compose
```bash
# Quick development setup
docker-compose -f docker-compose.dev.yml up --build
# Access at http://localhost:3000
```

## 🌐 **Access Your App**

| Service | URL | What It Does |
|---------|-----|--------------|
| **🎨 Frontend** | http://localhost:8080 | React user interface |
| **🔧 API** | http://localhost:8081 | Backend REST API |
| **❤️ Health** | http://localhost:8081/health | Server status |

## 🛑 **Stop Everything**

```bash
# Stop services
pkill -f "kubectl port-forward"

# Remove from Kubernetes  
kubectl delete -f k8s-deployment.yaml

# Stop minikube
minikube stop
```

## 🔧 **Check Status**

```bash
# See what's running
kubectl get pods
# OR: npm run k8s:status

# View logs
kubectl logs deployment/inputly-api -f
# OR: npm run k8s:logs

# Test API
curl http://localhost:8081/health
```

## 📋 **Useful NPM Scripts**

| Command | What it does |
|---------|--------------|
| `npm run k8s:quick-deploy` | Deploy to Kubernetes |
| `npm run k8s:status` | Check deployment status |
| `npm run k8s:logs` | View API logs |
| `npm run k8s:port-forward` | Setup port forwarding |
| `npm run k8s:stop-forward` | Stop port forwarding |
| `npm run k8s:restart` | Restart services |
| `npm run k8s:scale` | Scale to 2 replicas |
| `npm run setup:environment` | Install dependencies |

## ❗ **Troubleshooting**

**Problem: "command not found"**
```bash
# Install missing tools with brew (macOS) or apt (Ubuntu)
```

**Problem: Docker not running**
```bash
# Start Docker Desktop or: sudo systemctl start docker
```

**Problem: Can't access app**
```bash
# Check port forwarding
kubectl port-forward svc/inputly-frontend-service 8080:80
```

**Problem: Pods not starting**
```bash
# Check what's wrong
kubectl describe pod <pod-name>
```

## 📊 **What's Included**

- ✅ **React Frontend** - Modern UI with Tailwind CSS
- ✅ **Node.js Backend** - Express.js REST API  
- ✅ **PostgreSQL Ready** - Database integration
- ✅ **JWT Authentication** - Secure user management
- ✅ **Kubernetes Deployment** - Production-ready orchestration
- ✅ **Docker Containerization** - Consistent environments
- ✅ **Health Checks** - Monitoring and observability
- ✅ **Security Features** - Rate limiting, CORS, headers

## 🎯 **Next Steps**

1. **Explore the UI**: Open http://localhost:8080
2. **Test the API**: Try http://localhost:8081/health  
3. **View Logs**: `kubectl logs deployment/inputly-api -f`
4. **Scale Up**: `kubectl scale deployment inputly-api --replicas=3`
5. **Monitor**: Check metrics at http://localhost:8081/metrics

## 📚 **Need More Details?**

- **Full Documentation**: See `Docs/deployment.md`
- **Architecture**: Check the main `README.md`
- **Setup Summary**: See `Docs/setup-summary.md`
- **Issues**: [GitHub Issues](https://github.com/thulanibango/Inputly/issues)

---

**⚡ Ready to deploy in production? Check out the Helm charts in `/deploy/helm/`**

**⭐ Like this project? Star it on GitHub!**