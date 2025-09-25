# 🚀 Inputly

**A modern, cloud-native user management system built with security, scalability, and observability at its core.**

[![Node.js](https://img.shields.io/badge/Node.js-20.x-green.svg)](https://nodejs.org/)
[![React](https://img.shields.io/badge/React-18.x-blue.svg)](https://reactjs.org/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Ready-brightgreen.svg)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/Docker-Supported-blue.svg)](https://docker.com/)
[![CI](https://github.com/thulanibango/Inputly/actions/workflows/ci.yml/badge.svg)](https://github.com/thulanibango/Inputly/actions/workflows/ci.yml)
[![Tests](https://github.com/thulanibango/Inputly/actions/workflows/tests.yml/badge.svg)](https://github.com/thulanibango/Inputly/actions/workflows/tests.yml)
[![Lint](https://github.com/thulanibango/Inputly/actions/workflows/lint-and-format.yml/badge.svg)](https://github.com/thulanibango/Inputly/actions/workflows/lint-and-format.yml)
[![License](https://img.shields.io/badge/License-ISC-yellow.svg)](LICENSE)

Inputly is a production-ready web application that provides secure user authentication and management with enterprise-grade security features, comprehensive monitoring, and cloud-native deployment capabilities.

## ✨ Features

### 🔐 **Security First**
- **Multi-layered Protection**: Arcjet integration for bot detection, attack shields, and smart rate limiting
- **JWT Authentication**: Secure token-based auth with httpOnly cookies
- **Role-based Access Control**: Admin and user roles with different permissions
- **Password Security**: bcrypt hashing with salt rounds
- **Security Headers**: Helmet.js protection against common vulnerabilities

### 📊 **Enterprise Monitoring**
- **Prometheus Metrics**: Custom HTTP request/duration/error tracking
- **Grafana Dashboards**: Beautiful visualizations and alerting
- **Health Endpoints**: Comprehensive system health checks
- **Structured Logging**: JSON logging with Winston

### ☸️ **Cloud Native**
- **Kubernetes Ready**: Helm charts with proper health checks
- **Infrastructure as Code**: Terraform deployment automation
- **Horizontal Scaling**: Stateless design for easy scaling
- **Container Optimized**: Multi-stage Docker builds

### 🛠️ **Developer Experience**
- **Modern Stack**: Node.js 20, React 18, ES Modules
- **Type Safety**: Zod validation and Drizzle ORM
- **Hot Reload**: Development with file watching
- **Testing**: Jest integration tests with coverage
- **Code Quality**: ESLint and Prettier configured

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend API   │    │   Database      │
│   React + Vite  │◄──►│   Node.js       │◄──►│   PostgreSQL    │
│   (Nginx)       │    │   + Express     │    │   (Neon)        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                               │
                       ┌─────────────────┐
                       │   Monitoring    │
                       │   Prometheus    │
                       │   + Grafana     │
                       └─────────────────┘
```

**Tech Stack:**
- **Backend**: Node.js 20, Express 5.x, Drizzle ORM
- **Frontend**: React 18, Vite
- **Database**: PostgreSQL (Neon Serverless)
- **Security**: Arcjet, JWT, bcrypt
- **Monitoring**: Prometheus, Grafana
- **Infrastructure**: Docker, Kubernetes, Terraform, Helm

## 🚀 Quick Start

Choose your preferred deployment method:

### Option 1: One-Command Setup (Recommended)
```bash
git clone https://github.com/thulanibango/Inputly.git
cd Inputly
./src/scripts/quick-start.sh
```

### Option 2: Local Development
```bash
git clone https://github.com/thulanibango/Inputly.git
cd Inputly
npm install
./src/scripts/run-app.sh local
```

Your app will be running at **http://localhost:3000** 🎉

## 📦 Installation

### Prerequisites

- **Node.js** 20+ and npm
- **Docker Desktop** (for containerized deployment)
- **Minikube** or Kubernetes cluster (for K8s deployment)

### Automated Installation

The easiest way to get everything set up:

```bash
# Install all prerequisites and deploy the full stack
./src/scripts/install-prerequisites.sh
```

This script will:
- ✅ Install Homebrew (if missing)
- ✅ Install Docker Desktop, kubectl, minikube, helm, terraform
- ✅ Start Minikube and enable ingress
- ✅ Build and deploy your application
- ✅ Set up monitoring (Prometheus + Grafana)
- ✅ Configure access to all services

### Manual Installation

<details>
<summary>Click to expand manual installation steps</summary>

#### 1. Install Dependencies
```bash
# macOS with Homebrew
brew install node docker kubectl minikube helm terraform

# Or install manually:
# Node.js: https://nodejs.org/
# Docker Desktop: https://docker.com/products/docker-desktop
# Minikube: https://minikube.sigs.k8s.io/docs/start/
```

#### 2. Start Minikube
```bash
minikube start
minikube addons enable ingress
```

#### 3. Clone and Setup
```bash
git clone https://github.com/thulanibango/Inputly.git
cd Inputly
npm install
```

#### 4. Environment Configuration
```bash
# Copy environment template
cp .env.example .env.development

# Edit with your database credentials
nano .env.development
```

#### 5. Deploy Application
```bash
# Full deployment
./src/scripts/deploy-minikube.sh

# Or step by step:
./src/scripts/build-images.sh
./src/scripts/deploy-monitoring.sh
./src/scripts/fix-monitoring.sh
```

</details>

## 🎯 Deployment Options

### 1. **Local Development**
Perfect for development and testing:
```bash
./src/scripts/run-app.sh local
# Access: http://localhost:3000
```

### 2. **Docker Development**
Full-stack with database:
```bash
./src/scripts/run-app.sh docker-dev --logs
# Access: http://localhost:3000
```

### 3. **Kubernetes (Minikube)**
Production-like deployment:
```bash
./src/scripts/run-app.sh kubernetes --build
# Access: curl -H 'Host: inputly.local' http://$(minikube ip)/
```

### 4. **Full Stack with Monitoring**
Everything including Grafana and Prometheus:
```bash
./src/scripts/run-app.sh all
# App: curl -H 'Host: inputly.local' http://$(minikube ip)/
# Grafana: http://grafana.local (admin/admin123)
```

## 🔧 Available Scripts

### Development
```bash
npm run dev              # Start development server
npm run start            # Start production server
npm run test             # Run tests
npm run lint             # Lint code
npm run format           # Format code with Prettier
```

### Database
```bash
npm run db:generate      # Generate migrations
npm run db:migrate       # Run migrations
npm run db:studio        # Open Drizzle Studio
```

### Docker
```bash
npm run dev:docker       # Start with Docker Compose (dev)
npm run prod:docker      # Start with Docker Compose (prod)
```

### Kubernetes
```bash
npm run k8s:setup        # Setup Minikube
npm run k8s:build        # Build container images
npm run k8s:deploy       # Deploy to Kubernetes (with monitoring)
npm run k8s:quick-deploy # Quick Kubernetes-only deployment
npm run k8s:destroy      # Destroy deployment
npm run k8s:status       # Check deployment status
npm run k8s:logs         # View API logs
npm run k8s:port-forward # Setup port forwarding
npm run k8s:stop-forward # Stop port forwarding
npm run k8s:restart      # Restart deployments
npm run k8s:scale        # Scale to 2 replicas
```

### Setup
```bash
npm run setup:environment          # Install local dependencies
npm run setup:prerequisites        # Full monitoring setup
npm run setup:quick                # Complete quick start
```

### Monitoring
```bash
npm run monitoring:deploy           # Deploy Prometheus + Grafana
npm run monitoring:port-forward     # Access Grafana
npm run monitoring:troubleshoot     # Debug monitoring issues
```

## 📡 API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout

### User Management (Admin only)
- `GET /api/users` - List all users
- `GET /api/users/:id` - Get user by ID
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user

### System
- `GET /` - Application status
- `GET /health` - Health check with system metrics
- `GET /metrics` - Prometheus metrics

## 🔐 Environment Variables

Create `.env.development` for local development:

```bash
NODE_ENV=development
PORT=3000
DATABASE_URL=postgres://user:pass@localhost:5432/inputly
JWT_SECRET=your-super-secret-jwt-key
ARCJET_KEY=your-arcjet-api-key
```

For production, create `.env.production` with production values.

## 📊 Monitoring & Observability

### Access Monitoring Tools

**Grafana Dashboard:**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 80:80
# Visit: http://grafana.local
# Login: admin / admin123
```

**Prometheus Metrics:**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Visit: http://localhost:9090
```

### Custom Metrics
- `http_requests_total` - Total HTTP requests by method, route, status
- `http_request_duration_seconds` - Request duration histogram
- `http_errors_total` - HTTP error counter
- `active_requests` - Current active requests gauge

### Health Checks
- **Liveness Probe**: `GET /health`
- **Readiness Probe**: `GET /health`
- **Metrics Endpoint**: `GET /metrics`

## 🧪 Testing

Run the test suite:
```bash
npm test                    # Run all tests
npm run test:watch          # Run tests in watch mode
npm run test:coverage       # Run tests with coverage report
```

The test suite includes:
- API endpoint testing
- Authentication flow testing
- Error handling validation
- Health check verification

## 🐳 Docker Support

### Development
```bash
docker-compose -f docker-compose.dev.yml up --build
```

### Production
```bash
docker-compose -f docker-compose.prod.yml up --build -d
```

### Multi-stage Builds
The Dockerfiles use multi-stage builds for optimization:
- **Base**: Production dependencies only
- **Dev**: All dependencies + development tools
- **Prod**: Optimized production build

## ☸️ Kubernetes Deployment

### Helm Charts
The application includes production-ready Helm charts:

```bash
deploy/helm/
├── inputly-api/           # Backend API service
├── inputly-frontend/      # Frontend React app
└── inputly-ingress/       # Ingress controller setup
```

### Terraform Infrastructure
Infrastructure as Code with Terraform:

```bash
infra/terraform/
├── main.tf               # Main infrastructure
├── monitoring.tf         # Prometheus + Grafana
└── variables.tf          # Configuration variables
```

### Deploy to Kubernetes
```bash
# Full deployment
./src/scripts/deploy-minikube.sh

# Just the monitoring stack
./src/scripts/deploy-monitoring.sh

# Fix monitoring configuration
./src/scripts/fix-monitoring.sh
```

## 🛠️ Development

### Project Structure
```
inputly/
├── src/                   # Backend source code
│   ├── config/           # Configuration files
│   ├── controllers/      # Route controllers
│   ├── middleware/       # Express middleware
│   ├── models/           # Database models
│   ├── routes/           # API routes
│   ├── services/         # Business logic
│   ├── utils/            # Helper functions
│   └── validations/      # Input validation
├── client/               # Frontend React app
├── deploy/               # Kubernetes deployments
├── infra/                # Infrastructure as Code
├── tests/                # Test files
├── docs/                 # Documentation
└── coverage/             # Test coverage reports
```

### Code Quality
- **ESLint**: Code linting with modern rules
- **Prettier**: Code formatting
- **Zod**: Runtime type validation
- **Jest**: Testing framework

### Adding New Features
1. Add route in `src/routes/`
2. Create controller in `src/controllers/`
3. Add business logic in `src/services/`
4. Add validation in `src/validations/`
5. Write tests in `tests/`

## 📚 Documentation

- 📖 [Architecture Guide](./docs/architecture.md) - Detailed system architecture
- 🔐 [Security Guide](./docs/security.md) - Security features and best practices
- 📊 [Monitoring Guide](./docs/monitoring.md) - Monitoring and observability
- 🚀 [Deployment Guide](./docs/deployment.md) - Production deployment guide
- 📝 [API Documentation](./docs/api.md) - Complete API reference

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup
```bash
git clone https://github.com/thulanibango/Inputly.git
cd Inputly
npm install
npm run dev
```

## 📄 License

This project is licensed under the ISC License - see the [LICENSE](LICENSE) file for details.

## 🆘 Troubleshooting

### Common Issues

**Minikube not starting:**
```bash
minikube delete
minikube start --driver=docker
```

**Grafana not accessible:**
```bash
./src/scripts/setup-grafana-access.sh
```

**Metrics not showing:**
```bash
./src/scripts/troubleshoot-monitoring.sh
```

**Database connection issues:**
```bash
# Check your .env.development file
# Ensure DATABASE_URL is correct
```

### Get Help

- 🐛 [Report Issues](https://github.com/thulanibango/Inputly/issues)
- 💬 [Discussions](https://github.com/thulanibango/Inputly/discussions)
- 📧 Contact: [your-email@example.com]

## 🙏 Acknowledgments

- [Arcjet](https://arcjet.com/) for security features
- [Neon](https://neon.tech/) for serverless PostgreSQL
- [Prometheus](https://prometheus.io/) and [Grafana](https://grafana.com/) for monitoring
- The amazing open-source community

---

**⭐ If you find this project helpful, please give it a star!**

Built with ❤️ by [Tulani Bango](https://github.com/thulanibango)

---

## Legacy Docker Documentation

This project includes first-class Docker support for both development with Neon Local and production with Neon Cloud.

### Files
- `Dockerfile` — Multi-stage container with `dev` and `prod` targets.
- `docker-compose.dev.yml` — Runs the app and Neon Local proxy (for ephemeral branches) in development.
- `docker-compose.prod.yml` — Runs the app only, connecting to Neon Cloud via `DATABASE_URL`.
- `.env.development.example` — Template for local development.
- `.env.production.example` — Template for production deployment.

### Development with Neon Local
Neon Local runs a local proxy to your Neon project and can create ephemeral branches for development/testing.

1) Copy and fill your environment
```
cp .env.development.example .env.development
# Set NEON_API_KEY, NEON_PROJECT_ID, optional PARENT_BRANCH_ID
# Optionally adjust DATABASE_URL (service hostname must be `neon-local` inside compose)
```

2) Start the stack
```
docker compose -f docker-compose.dev.yml up --build
```

This brings up two services:
- `neon-local` (image `neondatabase/neon_local:latest`) on port 5432
- `app` (Inputly) on port 3000

The app uses `DATABASE_URL=postgres://neon:npg@neon-local:5432/app?sslmode=require` inside the compose network. For JavaScript Postgres clients, Neon Local uses a self-signed certificate; ensure your driver config allows it (e.g., `ssl: { rejectUnauthorized: false }` if needed by your client library).

3) Access the app
```
http://localhost:3000
```

Stop with Ctrl+C and remove containers if needed:
```
docker compose -f docker-compose.dev.yml down
```

### Production with Neon Cloud
In production, connect directly to your Neon Cloud database. No Neon Local container is used.

1) Copy and fill your environment
```
cp .env.production.example .env.production
# Set DATABASE_URL to your Neon Cloud URL, e.g.
# postgres://user:password@your-project-name.region.neon.tech/dbname?sslmode=require
```

2) Start the app
```
docker compose -f docker-compose.prod.yml up --build -d
```

This starts only the `app` service. Ensure your production infra handles TLS termination and secrets management appropriately. For orchestration (e.g., ECS, Kubernetes), use the same Dockerfile and inject environment variables via your platform’s secret store.

### Switching environments
- Development Compose reads from `.env.development` and sets `DATABASE_URL` to Neon Local by default.
- Production Compose reads from `.env.production` and uses the Neon Cloud `DATABASE_URL` you provide.

Environment precedence can be overridden by passing variables inline:
```
DATABASE_URL=postgres://... docker compose -f docker-compose.prod.yml up -d
```

## API
Base path may be `/auth` depending on how routes are mounted in your `src/index.js`/app setup. The route definitions are in `src/routes/auth.routes.js`.

All auth responses set an httpOnly cookie named `token` on success. For security, the token is not returned in the JSON body.

### Register
POST `/auth/register`
Request body:
```
{
  "name": "Alice",
  "email": "alice@example.com",
  "password": "secret123",
  "role": "user"
}
```
Response 201:
```
{
  "message": "User registered successfully",
  "user": {
    "id": 1,
    "name": "Alice",
    "email": "alice@example.com",
    "role": "user",
    "createdAt": "2025-09-23T00:00:00.000Z"
  }
}
```
Sets cookie: `token` (httpOnly, sameSite=strict, secure in production).

Errors:
- 400 validation error (Zod)
- 409 user already exists

### Login
POST `/auth/login`
Request body:
```
{
  "email": "alice@example.com",
  "password": "secret123"
}
```
Response 200:
```
{
  "message": "Login successful",
  "user": {
    "id": 1,
    "name": "Alice",
    "email": "alice@example.com",
    "role": "user",
    "createdAt": "2025-09-23T00:00:00.000Z"
  }
}
```
Sets cookie: `token`.

Errors:
- 400 validation error (Zod)
- 401 invalid credentials

### Logout
POST `/auth/logout`
Response 200:
```
{ "message": "Logged out successfully" }
```
Clears cookie: `token`.

## Implementation Notes
- `src/controllers/auth.controller.js` contains controllers for Register, Login, Logout.
- `src/services/auth.service.js` contains:
  - `createUser()` with conflict check and password hashing
  - `findUserByEmail()` and `authenticateUser()` for login
- `src/validations/auth.validation.js` defines `registerSchema` and `loginSchema` (Zod).
- `src/utils/cookies.js` centralizes cookie options (httpOnly, sameSite, maxAge, secure in production).
- JWTs are created by `src/utils/jwt.js` and stored in httpOnly cookies for better security.

## Scripts
- `npm run dev` — start server with watch
- `npm run lint` — run ESLint
- `npm run format` — run Prettier write
- `npm run db:generate` — generate migrations (drizzle-kit)
- `npm run db:migrate` — run migrations (drizzle-kit)
- `npm run db:studio` — open Drizzle Studio

## Security
- httpOnly cookies prevent JavaScript access to tokens
- `sameSite: strict` reduces CSRF risk (consider CSRF tokens for state-changing requests)
- `secure: true` in production requires HTTPS
- Store strong `JWT_SECRET` and rotate periodically

## Troubleshooting
- ReferenceError about variables in controller catch blocks usually indicates trying to access try-scoped variables in catch; return generic info or pass data explicitly.
- Ensure `DATABASE_URL` is correct and reachable; for Neon, enable IP allow rules if needed.
- If cookie isn’t set in development, check domain/port and that you’re not mixing HTTPS/HTTP.
- When using Neon Local, confirm your env has `NEON_API_KEY` and `NEON_PROJECT_ID`, and that your app uses the compose service hostname `neon-local` in `DATABASE_URL`.

## License
ISC
