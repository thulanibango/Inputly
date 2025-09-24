# 🔐 Inputly Security Guide

Comprehensive security documentation covering all security features, best practices, and implementation details for Inputly.

## 📋 Table of Contents

- [Security Architecture](#security-architecture)
- [Authentication & Authorization](#authentication--authorization)
- [Multi-layered Protection](#multi-layered-protection)
- [Data Security](#data-security)
- [Infrastructure Security](#infrastructure-security)
- [Security Best Practices](#security-best-practices)
- [Security Configuration](#security-configuration)
- [Vulnerability Management](#vulnerability-management)
- [Security Monitoring](#security-monitoring)
- [Compliance & Audit](#compliance--audit)

## 🏗️ Security Architecture

Inputly implements a **defense-in-depth security strategy** with multiple layers of protection:

```
┌─────────────────────────────────────────────────────────────┐
│                    🌐 Network Layer                         │
│  • Ingress Controller (TLS termination)                    │
│  • Network Policies (Kubernetes)                           │
│  • VPC/Firewall Rules                                      │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                   🛡️ Application Layer                      │
│  • Arcjet Security Platform                                │
│  • Rate Limiting & Bot Detection                           │
│  • Attack Shields & Anomaly Detection                      │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                  🔑 Authentication Layer                    │
│  • JWT Token Authentication                                │
│  • Role-based Access Control (RBAC)                        │
│  • HTTP-only Cookie Security                               │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    💾 Data Layer                            │
│  • Password Hashing (bcrypt)                               │
│  • Database Connection Security                            │
│  • Input Validation & Sanitization                         │
└─────────────────────────────────────────────────────────────┘
```

## 🔑 Authentication & Authorization

### JWT Authentication System

#### Token Structure
```javascript
// JWT Payload
{
  "userId": 1,
  "email": "user@example.com",
  "role": "user",
  "iat": 1640995200,    // Issued at
  "exp": 1641600000     // Expires at (7 days default)
}
```

#### Dual Token Delivery
1. **Authorization Header**: `Bearer <token>`
2. **HTTP-only Cookie**: `authToken` (recommended)

**Implementation** (`src/utils/jwt.js`):
```javascript
export const generateJWT = (payload) => {
  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    issuer: 'inputly-api',
    audience: 'inputly-client'
  });
};
```

### Role-based Access Control (RBAC)

#### User Roles
- **Guest**: Limited access, higher rate limits
- **User**: Standard authenticated user
- **Admin**: Full administrative access

#### Authorization Middleware
**File**: `src/middleware/auth.middleware.js`

```javascript
// Require authentication
export const requireAuth = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({
      status: 'error',
      message: 'Authentication required'
    });
  }
  next();
};

// Require specific role
export const requireRole = (role) => {
  return (req, res, next) => {
    if (!req.user || req.user.role !== role) {
      return res.status(403).json({
        status: 'error',
        message: 'Insufficient permissions'
      });
    }
    next();
  };
};
```

### Cookie Security

**Configuration** (`src/utils/cookies.js`):
```javascript
export const cookieConfig = {
  httpOnly: true,                    // Prevent XSS
  secure: process.env.NODE_ENV === 'production',  // HTTPS only in prod
  sameSite: 'strict',               // CSRF protection
  maxAge: 1000 * 60 * 60 * 24 * 7,  // 7 days
  domain: process.env.COOKIE_DOMAIN  // Explicit domain setting
};
```

## 🛡️ Multi-layered Protection

### Arcjet Security Platform

Inputly integrates **Arcjet** for enterprise-grade security features:

**Configuration** (`src/config/arcjet.js`):
```javascript
import arcjet, { shield, detectBot, slidingWindow } from '@arcjet/node';

const aj = arcjet({
  key: process.env.ARCJET_KEY,
  rules: [
    // Attack protection
    shield({ 
      mode: 'LIVE'  // DRY_RUN for testing
    }),
    
    // Bot detection
    detectBot({ 
      mode: 'LIVE',
      block: ['AUTOMATED']  // Block automated bots
    }),
    
    // Base rate limiting
    slidingWindow({
      mode: 'LIVE',
      interval: '2s',
      max: 5,
      characteristics: ['ip']
    })
  ]
});
```

### Rate Limiting Strategy

#### Role-based Rate Limits
**Implementation** (`src/middleware/security.middleware.js`):

| Role | Rate Limit | Window | Purpose |
|------|------------|---------|---------|
| **Guest** | 5 requests | 2 seconds | Prevent abuse |
| **User** | 10 requests | 1 minute | Normal usage |
| **Admin** | 20 requests | 1 minute | Administrative tasks |

```javascript
const getRateLimit = (userRole) => {
  const limits = {
    guest: { windowMs: 2000, max: 5 },
    user: { windowMs: 60000, max: 10 },
    admin: { windowMs: 60000, max: 20 }
  };
  
  return limits[userRole] || limits.guest;
};
```

### Attack Prevention

#### 1. Shield Protection
- **SQL Injection** detection and blocking
- **XSS Attack** prevention
- **Command Injection** protection
- **Path Traversal** blocking

#### 2. Bot Detection
- **Automated bot** identification
- **Scraping protection**
- **Brute force** mitigation
- **Suspicious pattern** detection

#### 3. Anomaly Detection
- **Traffic pattern** analysis
- **Behavioral anomalies**
- **Geographic anomalies**
- **Request frequency** analysis

## 💾 Data Security

### Password Security

#### Bcrypt Implementation
**File**: `src/services/auth.service.js`

```javascript
import bcrypt from 'bcrypt';

const SALT_ROUNDS = 12;

export const hashPassword = async (password) => {
  return await bcrypt.hash(password, SALT_ROUNDS);
};

export const validatePassword = async (password, hashedPassword) => {
  return await bcrypt.compare(password, hashedPassword);
};
```

#### Password Requirements
- **Minimum length**: 8 characters
- **Recommended**: Mix of uppercase, lowercase, numbers, symbols
- **Storage**: Never stored in plaintext
- **Transmission**: Only over HTTPS

### Input Validation & Sanitization

#### Zod Schema Validation
**File**: `src/validations/auth.validation.js`

```javascript
import { z } from 'zod';

export const registerSchema = z.object({
  name: z.string()
    .min(2, 'Name must be at least 2 characters')
    .max(255, 'Name must be less than 255 characters')
    .trim(),
  
  email: z.string()
    .email('Invalid email format')
    .toLowerCase()
    .trim(),
  
  password: z.string()
    .min(8, 'Password must be at least 8 characters')
    .regex(/[A-Z]/, 'Password must contain uppercase letter')
    .regex(/[a-z]/, 'Password must contain lowercase letter')
    .regex(/[0-9]/, 'Password must contain number'),
  
  role: z.enum(['user', 'admin']).optional().default('user')
});
```

### Database Security

#### Connection Security
```javascript
// Secure database configuration
const databaseConfig = {
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? {
    rejectUnauthorized: true,
    ca: process.env.DB_CA_CERT
  } : false,
  pool: {
    min: 2,
    max: 10,
    createTimeoutMillis: 3000,
    acquireTimeoutMillis: 30000,
    idleTimeoutMillis: 30000,
    reapIntervalMillis: 1000,
    createRetryIntervalMillis: 100
  }
};
```

#### Data Protection
- **Encryption at rest**: Database-level encryption
- **Encryption in transit**: TLS 1.3 for all connections
- **Access control**: Principle of least privilege
- **Audit logging**: All data access logged

## 🏗️ Infrastructure Security

### Kubernetes Security

#### Pod Security Standards
**File**: `deploy/helm/inputly-api/templates/deployment.yaml`

```yaml
apiVersion: v1
kind: Pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: inputly-api
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
      readOnlyRootFilesystem: true
      runAsNonRoot: true
```

#### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: inputly-network-policy
spec:
  podSelector:
    matchLabels:
      app: inputly-api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: inputly
    ports:
    - protocol: TCP
      port: 3000
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 443
```

### Container Security

#### Multi-stage Docker Build
**File**: `Dockerfile`

```dockerfile
# Base stage - production dependencies only
FROM node:20-alpine AS base
RUN addgroup -g 1001 -S nodejs && \
    adduser -S inputly -u 1001 -G nodejs
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force

# Production stage
FROM node:20-alpine AS prod
RUN addgroup -g 1001 -S nodejs && \
    adduser -S inputly -u 1001 -G nodejs

WORKDIR /app
COPY --from=base --chown=inputly:nodejs /app/node_modules ./node_modules
COPY --chown=inputly:nodejs . .

USER inputly
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

CMD ["node", "src/index.js"]
```

#### Container Scanning
```bash
# Scan for vulnerabilities
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v $HOME/Library/Caches:/root/.cache/ \
  aquasec/trivy image inputly:latest

# Scan filesystem
trivy fs --security-checks vuln,config .
```

### TLS/SSL Configuration

#### Certificate Management
```yaml
# cert-manager configuration
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@your-domain.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

## 🔧 Security Configuration

### Environment Variables Security

#### Production Environment
```bash
# Authentication
JWT_SECRET=<64-character-random-string>
JWT_EXPIRES_IN=7d

# Database (use connection pooling in production)
DATABASE_URL=postgres://user:pass@host.neon.tech/db?pgbouncer=true&sslmode=require

# Arcjet Security
ARCJET_KEY=ajkey_<your-key>

# Security Headers
HSTS_MAX_AGE=31536000
CONTENT_SECURITY_POLICY="default-src 'self'; script-src 'self'"

# Cookie Security
COOKIE_DOMAIN=your-domain.com
COOKIE_SECURE=true

# Logging
LOG_LEVEL=warn
AUDIT_LOG_ENABLED=true
```

### Security Headers

**Implementation** (`src/app.js`):
```javascript
import helmet from 'helmet';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'"],
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  },
  noSniff: true,
  xssFilter: true,
  referrerPolicy: { policy: "same-origin" }
}));
```

### CORS Configuration
```javascript
import cors from 'cors';

app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? ['https://your-domain.com', 'https://admin.your-domain.com']
    : ['http://localhost:3000', 'http://localhost:5173'],
  credentials: true,
  optionsSuccessStatus: 200,
  allowedHeaders: ['Content-Type', 'Authorization'],
  methods: ['GET', 'POST', 'PUT', 'DELETE']
}));
```

## 🛠️ Security Best Practices

### Development Security

#### 1. Secure Development Lifecycle
```bash
# Pre-commit security checks
npm install --save-dev @commitlint/cli @commitlint/config-conventional
npm install --save-dev husky lint-staged

# Security linting
npm install --save-dev eslint-plugin-security
```

#### 2. Dependency Security
```bash
# Audit dependencies
npm audit --audit-level high

# Automated dependency updates
npm install --save-dev dependabot

# License checking
npm install --save-dev license-checker
```

#### 3. Code Security Scanning
```bash
# Static analysis
npm install --save-dev semgrep

# Secrets detection
npm install --save-dev detect-secrets
```

### Production Security

#### 1. Secret Management
```bash
# Kubernetes secrets
kubectl create secret generic inputly-secrets \
  --from-literal=jwt-secret="$(openssl rand -base64 64)" \
  --from-literal=database-url="$DATABASE_URL" \
  --from-literal=arcjet-key="$ARCJET_KEY"

# Seal secrets for GitOps
kubeseal -o yaml < secrets.yaml > sealed-secrets.yaml
```

#### 2. Database Security
```sql
-- Create dedicated database user
CREATE USER inputly_app WITH PASSWORD 'secure_password';

-- Grant minimal required permissions
GRANT CONNECT ON DATABASE inputly TO inputly_app;
GRANT USAGE ON SCHEMA public TO inputly_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON users TO inputly_app;

-- Enable row-level security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policy for user access
CREATE POLICY user_policy ON users FOR ALL TO inputly_app
USING (id = current_user_id());
```

#### 3. Monitoring & Alerting
```yaml
# Prometheus alerting rules
groups:
- name: security.rules
  rules:
  - alert: HighFailedAuthRate
    expr: rate(http_requests_total{status_code=~"401|403"}[5m]) > 0.1
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: High failed authentication rate detected
      
  - alert: SuspiciousTrafficPattern
    expr: rate(http_requests_total[1m]) > 100
    for: 30s
    labels:
      severity: critical
    annotations:
      summary: Unusual traffic pattern detected
```

## 🔍 Vulnerability Management

### Security Testing

#### 1. Automated Security Testing
```bash
# OWASP ZAP security testing
docker run -t owasp/zap2docker-stable zap-baseline.py \
  -t http://localhost:3000

# Nuclei vulnerability scanner
nuclei -u http://localhost:3000 -t exposures/,cves/
```

#### 2. Penetration Testing Checklist
- [ ] **Authentication bypass** attempts
- [ ] **Authorization** escalation testing
- [ ] **Input validation** testing (XSS, SQLi)
- [ ] **Rate limiting** effectiveness
- [ ] **Session management** security
- [ ] **API endpoint** security
- [ ] **File upload** security
- [ ] **Error handling** information disclosure

### Incident Response

#### 1. Security Incident Response Plan
```markdown
## Incident Response Procedure

1. **Detection & Analysis**
   - Monitor alerts from Grafana/Prometheus
   - Analyze logs for suspicious patterns
   - Assess impact and severity

2. **Containment**
   - Block malicious IPs via network policies
   - Revoke compromised tokens
   - Scale down affected services if needed

3. **Eradication**
   - Apply security patches
   - Update security configurations
   - Remove malicious artifacts

4. **Recovery**
   - Restore services from clean backups
   - Monitor for continued attacks
   - Gradually restore normal operations

5. **Post-Incident**
   - Document lessons learned
   - Update security procedures
   - Improve monitoring capabilities
```

## 📊 Security Monitoring

### Security Metrics

#### Key Security Indicators
```javascript
// Custom security metrics
export const securityMetrics = {
  failedAuthAttempts: new client.Counter({
    name: 'failed_auth_attempts_total',
    help: 'Total failed authentication attempts',
    labelNames: ['ip', 'user_agent']
  }),
  
  blockedRequests: new client.Counter({
    name: 'blocked_requests_total',
    help: 'Total blocked requests by security layer',
    labelNames: ['reason', 'ip']
  }),
  
  suspiciousActivities: new client.Counter({
    name: 'suspicious_activities_total',
    help: 'Total suspicious activities detected',
    labelNames: ['type', 'severity']
  })
};
```

### Log Analysis

#### Security Event Logging
```javascript
// Security event logging
export const logSecurityEvent = (event) => {
  logger.warn('SECURITY_EVENT', {
    timestamp: new Date().toISOString(),
    event_type: event.type,
    severity: event.severity,
    user_id: event.userId,
    ip_address: event.ip,
    user_agent: event.userAgent,
    details: event.details,
    action_taken: event.actionTaken
  });
};
```

## 📋 Compliance & Audit

### Security Audit Checklist

#### Application Security
- [ ] **Authentication** properly implemented
- [ ] **Authorization** controls in place
- [ ] **Input validation** comprehensive
- [ ] **Output encoding** implemented
- [ ] **Error handling** secure
- [ ] **Session management** secure
- [ ] **Cryptography** properly implemented
- [ ] **Logging** comprehensive

#### Infrastructure Security  
- [ ] **Network security** configured
- [ ] **Container security** implemented
- [ ] **Kubernetes security** policies applied
- [ ] **TLS/SSL** properly configured
- [ ] **Secrets management** secure
- [ ] **Backup security** implemented
- [ ] **Monitoring** comprehensive
- [ ] **Incident response** plan ready

### Regular Security Tasks

#### Weekly
- [ ] Review security alerts and logs
- [ ] Check for dependency vulnerabilities
- [ ] Validate backup integrity
- [ ] Review access logs

#### Monthly
- [ ] Security patch assessment
- [ ] Access control review
- [ ] Security metrics analysis
- [ ] Threat intelligence review

#### Quarterly
- [ ] Penetration testing
- [ ] Security policy review
- [ ] Incident response drill
- [ ] Security training update

## 🆘 Security Support

### Reporting Security Issues

**Security Contact**: security@your-domain.com

**Responsible Disclosure**:
1. **DO NOT** create public GitHub issues for security vulnerabilities
2. **Email** security team with detailed information
3. **Allow** reasonable time for fix before public disclosure
4. **Provide** steps to reproduce if possible

### Security Resources

- 📖 [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- 📚 [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- 🛡️ [Node.js Security Best Practices](https://nodejs.org/en/docs/guides/security/)
- 🔐 [Arcjet Documentation](https://docs.arcjet.com/)

---

**Security is a continuous process, not a destination. Stay vigilant, stay secure!** 🛡️

For security questions or concerns, contact the security team or create an issue on [GitHub](https://github.com/thulanibango/Inputly/issues).