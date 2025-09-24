# Inputly Architecture Documentation

## 🏗️ Big Picture

**Inputly** is a modern, cloud-native user management web application built with a microservices architecture. It solves the problem of secure, scalable user authentication and management with comprehensive monitoring and security features. Think of it as a production-ready foundation for any web application that needs robust user management with enterprise-grade security and observability.

## 🎯 Core Architecture

Inputly follows a **3-tier microservices architecture** with clear separation of concerns:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend API   │    │   Database      │
│   React + Vite  │◄──►│   Node.js       │◄──►│   PostgreSQL    │
│   (Port 80)     │    │   Express       │    │   (Neon)        │
└─────────────────┘    │   (Port 3000)   │    └─────────────────┘
                       └─────────────────┘
                               │
                       ┌─────────────────┐
                       │   Monitoring    │
                       │   Prometheus    │
                       │   Grafana       │
                       └─────────────────┘
```

### Project Structure
```
inputly/
├── src/                    # Backend API (Node.js + Express)
│   ├── config/            # Database, logging, security config
│   ├── controllers/       # API route handlers
│   ├── middleware/        # Authentication, security, logging
│   ├── models/            # Database schemas (Drizzle ORM)
│   ├── routes/            # API route definitions
│   ├── services/          # Business logic layer
│   ├── utils/             # Helper functions (JWT, cookies, etc.)
│   ├── validations/       # Input validation schemas (Zod)
│   └── scripts/           # Deployment and utility scripts
├── client/                # Frontend React application
├── deploy/helm/           # Kubernetes deployment charts
├── infra/terraform/       # Infrastructure as Code
├── tests/                 # Backend integration tests
└── docs/                  # Documentation (you are here!)
```

## 🧩 Key Components

### 1. **Backend API Server** (`src/`)
- **Purpose**: Handles all business logic, authentication, and data management
- **Key Files**:
  - `src/app.js` - Express app configuration with middleware stack
  - `src/index.js` - Server startup and configuration
  - `src/server.js` - HTTP server setup

**Tech Stack**: Node.js 20, Express 5.x, ES Modules

### 2. **Authentication System** (`src/middleware/`, `src/services/`)
- **Purpose**: Secure user authentication with JWT tokens and role-based access
- **Key Features**:
  - JWT tokens (Bearer + httpOnly cookies)
  - Password hashing with bcrypt
  - Role-based authorization (user/admin)
  - Graceful degradation for guest users

```javascript
// Example: JWT + Cookie authentication flow
const token = generateJWT({ userId, email, role });
res.cookie('authToken', token, {
  httpOnly: true,
  secure: process.env.NODE_ENV === 'production',
  sameSite: 'strict',
  maxAge: 7 * 24 * 60 * 60 * 1000 // 7 days
});
```

### 3. **Security Layer** (`src/middleware/security.middleware.js`)
- **Purpose**: Multi-layered protection against attacks
- **Components**:
  - **Arcjet**: Bot detection, attack shields, basic rate limiting
  - **Role-based Rate Limiting**: Different limits for admin/user/guest
  - **Security Headers**: Helmet.js for HTTP security

```javascript
// Example: Role-based rate limiting
const limits = {
  admin: { windowMs: 60000, max: 20 },    // 20 requests/minute
  user: { windowMs: 60000, max: 10 },     // 10 requests/minute
  guest: { windowMs: 60000, max: 5 }      // 5 requests/minute
};
```

### 4. **Database Layer** (`src/models/`, `src/config/database.js`)
- **Purpose**: Data persistence with type-safe queries
- **Tech**: PostgreSQL via Neon serverless, Drizzle ORM
- **Schema**: Users table with roles, timestamps, email uniqueness

### 5. **Monitoring Stack** (`src/app.js`, `deploy/helm/`)
- **Purpose**: Application observability and health monitoring
- **Components**:
  - **Prometheus Metrics**: Custom HTTP request/duration/error metrics
  - **Health Endpoints**: `/health`, `/metrics`
  - **Grafana Dashboards**: Visual monitoring via Kubernetes

### 6. **Frontend Application** (`client/`)
- **Purpose**: User interface for the application
- **Tech**: React 18, Vite build system, Nginx serving
- **Deployment**: Dockerized with multi-stage builds

### 7. **Infrastructure** (`deploy/`, `infra/`)
- **Purpose**: Cloud-native deployment and scaling
- **Components**:
  - **Kubernetes**: Helm charts for API, frontend, ingress
  - **Terraform**: Infrastructure as Code for reproducible deployments
  - **Monitoring**: Automated Prometheus + Grafana setup

## 📊 Data Flow & Communication

### 1. **User Authentication Flow**
```
User Login Request
     ↓
[Frontend] POST /api/auth/login
     ↓
[Security Middleware] → Arcjet checks → Rate limiting
     ↓
[Auth Controller] → Zod validation
     ↓
[Auth Service] → Password verification (bcrypt)
     ↓
[Database] → User lookup via Drizzle ORM
     ↓
[JWT Utils] → Token generation
     ↓
[Cookie Utils] → Secure cookie setting
     ↓
[Response] → User data (password excluded) + Set-Cookie header
```

### 2. **Protected API Request Flow**
```
API Request with JWT
     ↓
[Security Middleware] → Bot detection, rate limiting
     ↓
[Auth Middleware] → JWT validation (Bearer token or cookie)
     ↓
[Authorization] → Role-based access control
     ↓
[Controller] → Business logic
     ↓
[Service Layer] → Data processing
     ↓
[Database] → CRUD operations
     ↓
[Response] → JSON data + Updated metrics
```

### 3. **Monitoring Data Flow**
```
HTTP Request
     ↓
[Prometheus Middleware] → Metrics collection
     ↓
[Metrics Storage] → In-memory Prometheus registry
     ↓
[/metrics Endpoint] → Prometheus format export
     ↓
[Kubernetes ServiceMonitor] → Automatic scraping
     ↓
[Prometheus Server] → Time-series storage
     ↓
[Grafana] → Visual dashboards and alerts
```

## 🛠️ Tech Stack & Dependencies

### Backend Core
- **Node.js 20** - JavaScript runtime with ES modules
- **Express 5.x** - Web application framework
- **Drizzle ORM** - Type-safe database queries and migrations
- **PostgreSQL** - Primary database via Neon serverless

### Security & Authentication
- **Arcjet** - Modern security platform (bot detection, shields, rate limiting)
- **JWT** - Token-based authentication
- **bcrypt** - Password hashing
- **Helmet** - Security headers
- **Zod** - Runtime type validation

### Monitoring & Logging
- **prom-client** - Prometheus metrics collection
- **Winston** - Structured JSON logging
- **Morgan** - HTTP request logging

### Infrastructure
- **Docker** - Containerization with multi-stage builds
- **Kubernetes** - Container orchestration
- **Helm** - Kubernetes package management
- **Terraform** - Infrastructure as Code
- **Nginx** - Reverse proxy and static file serving

### Frontend
- **React 18** - User interface library
- **Vite** - Build tool and development server

### Development & Testing
- **Jest** - Testing framework
- **Supertest** - HTTP testing
- **ESLint + Prettier** - Code quality and formatting

## 🔄 Execution Flow Examples

### Example 1: User Registration
```
1. User submits registration form
   → POST /api/auth/register { name, email, password }

2. Security checks
   → Arcjet bot detection and rate limiting
   → Input validation with Zod schemas

3. Business logic
   → Check if email already exists
   → Hash password with bcrypt
   → Create user record in database

4. Response
   → Return user data (without password)
   → Set authentication cookies
   → Log successful registration
```

### Example 2: Admin User Management
```
1. Admin requests user list
   → GET /api/users (with Authorization: Bearer <token>)

2. Authentication & Authorization
   → Validate JWT token
   → Check user role = 'admin'
   → Apply admin rate limiting (20 req/min)

3. Data retrieval
   → Query users table via Drizzle ORM
   → Exclude password fields
   → Apply pagination if specified

4. Response
   → Return user list as JSON
   → Update Prometheus metrics
   → Log admin action
```

### Example 3: Health Check & Monitoring
```
1. Prometheus scrapes /metrics endpoint
   → GET /metrics (every 15 seconds)

2. Metrics collection
   → HTTP request counters
   → Response time histograms
   → Active request gauges
   → System resource metrics

3. Data visualization
   → Prometheus stores time-series data
   → Grafana queries Prometheus
   → Displays dashboards with alerts

4. Health monitoring
   → /health endpoint provides system status
   → Database connectivity checks
   → Memory and uptime metrics
```

## 💪 Strengths & Tradeoffs

### ✅ Strengths

1. **Security-First Design**
   - Multi-layered protection with Arcjet
   - Role-based authentication and authorization
   - Secure cookie handling and JWT implementation

2. **Cloud-Native Architecture**
   - Kubernetes-ready with proper health checks
   - Horizontal scaling capabilities
   - Infrastructure as Code with Terraform

3. **Comprehensive Observability**
   - Prometheus metrics for performance monitoring
   - Structured logging with Winston
   - Health endpoints for system status

4. **Modern Development Practices**
   - TypeScript-like safety with Zod validation
   - Clean code organization and separation of concerns
   - Automated testing with Jest

5. **Production-Ready Features**
   - Database migrations with Drizzle
   - Multi-environment deployment scripts
   - Docker multi-stage builds for optimization

### ⚠️ Tradeoffs & Considerations

1. **Complexity for Simple Use Cases**
   - May be over-engineered for basic applications
   - Requires Kubernetes knowledge for deployment

2. **Database Dependency**
   - Tight coupling to PostgreSQL
   - Limited offline capabilities

3. **Single Database Architecture**
   - All data in one database (not microservices data isolation)
   - Potential scaling bottleneck for high-volume applications

4. **Learning Curve**
   - Multiple technologies require diverse skill set
   - DevOps knowledge needed for full deployment

## 🎯 Final Summary

**Inputly is a production-ready, cloud-native user management system that prioritizes security, observability, and scalability.** It combines modern authentication patterns with enterprise-grade monitoring in a Kubernetes-native architecture. **The system is built for teams that need a robust foundation for user management without sacrificing security or operational visibility—perfect for scaling from startup to enterprise while maintaining clean architecture and DevOps best practices.**

---

