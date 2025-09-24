# 📊 Inputly Monitoring Guide

Complete guide for setting up, configuring, and using monitoring tools with Inputly including Prometheus, Grafana, and observability best practices.

## 📋 Table of Contents

- [Monitoring Architecture](#monitoring-architecture)
- [Quick Setup](#quick-setup)
- [Prometheus Configuration](#prometheus-configuration)
- [Grafana Setup](#grafana-setup)
- [Custom Metrics](#custom-metrics)
- [Alerting](#alerting)
- [Log Management](#log-management)
- [Health Checks](#health-checks)
- [Performance Monitoring](#performance-monitoring)
- [Troubleshooting](#troubleshooting)

## 🏗️ Monitoring Architecture

Inputly implements a comprehensive observability stack using industry-standard tools:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │───►│   Prometheus    │───►│    Grafana      │
│   (Metrics)     │    │   (Storage)     │    │  (Visualization)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐              │
         │              │  AlertManager   │              │
         │              │   (Alerting)    │              │
         │              └─────────────────┘              │
         │                                               │
         ▼                                               ▼
┌─────────────────┐                            ┌─────────────────┐
│     Logs        │                            │   Dashboards    │
│   (Winston)     │                            │   & Reports     │
└─────────────────┘                            └─────────────────┘
```

### Components Overview

| Component | Purpose | Port | Access |
|-----------|---------|------|---------|
| **Application** | Expose metrics via `/metrics` | 3000 | Internal |
| **Prometheus** | Metrics collection & storage | 9090 | Port-forward |
| **Grafana** | Visualization & dashboards | 80 | grafana.local |
| **AlertManager** | Alert routing & notification | 9093 | Port-forward |

## 🚀 Quick Setup

### Option 1: Automated Setup (Recommended)
```bash
# Complete monitoring stack deployment
./src/scripts/deploy-monitoring.sh
```

### Option 2: One-Command Full Stack
```bash
# Deploy everything including monitoring
./src/scripts/run-app.sh all
```

### Option 3: Fix Existing Monitoring
```bash
# If monitoring is deployed but not working
./src/scripts/fix-monitoring.sh
```

### Option 4: Manual Verification
```bash
# Check monitoring status
./src/scripts/troubleshoot-monitoring.sh
```

## ⚙️ Prometheus Configuration

### ServiceMonitor Configuration

**File**: `deploy/helm/inputly-api/templates/servicemonitor.yaml`

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ .Release.Name }}
  labels:
    app: {{ .Release.Name }}
    release: {{ .Values.metrics.prometheusRelease | default "kube-prometheus-stack" }}
spec:
  selector:
    matchLabels:
      app: {{ .Release.Name }}
      release: {{ .Values.metrics.prometheusRelease | default "kube-prometheus-stack" }}
  endpoints:
    - port: http
      path: /metrics
      interval: 15s
      scrapeTimeout: 10s
```

### Prometheus Values Configuration

**File**: `infra/terraform/monitoring.tf`

```hcl
resource "helm_release" "kps" {
  name       = var.prometheus_release_name
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "58.3.2"

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          serviceMonitorSelectorNilUsesHelmValues = false
          serviceMonitorSelector = {
            matchLabels = {
              release = var.prometheus_release_name
            }
          }
          retention = "15d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "10Gi"
                  }
                }
              }
            }
          }
        }
      }
    })
  ]
}
```

### Access Prometheus

```bash
# Port forward to Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090

# Visit http://localhost:9090
```

## 📈 Grafana Setup

### Automated Grafana Setup

```bash
# Setup Grafana with automatic host configuration
./src/scripts/setup-grafana-access.sh
```

### Manual Grafana Access

#### Option 1: Using grafana.local (Recommended)
```bash
# Add to /etc/hosts
echo "127.0.0.1 grafana.local" | sudo tee -a /etc/hosts

# Port forward
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 80:80

# Visit: http://grafana.local
# Login: admin / admin123
```

#### Option 2: Direct localhost access
```bash
# Port forward to different port
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3001:80

# Visit: http://localhost:3001
# Login: admin / admin123
```

### Grafana Configuration

**Default Settings**:
- **Username**: `admin`
- **Password**: `admin123` (change in production!)
- **Data Source**: Prometheus (auto-configured)

### Import Dashboards

#### 1. Node.js Application Dashboard
```json
{
  "dashboard": {
    "id": null,
    "title": "Inputly Application Metrics",
    "panels": [
      {
        "title": "HTTP Requests per Second",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{method}} {{route}}"
          }
        ]
      },
      {
        "title": "Response Time Distribution",
        "type": "heatmap", 
        "targets": [
          {
            "expr": "rate(http_request_duration_seconds_bucket[5m])",
            "legendFormat": "{{le}}"
          }
        ]
      }
    ]
  }
}
```

#### 2. Popular Dashboard IDs
- **Node.js Application**: Dashboard ID `11159`
- **Kubernetes Cluster**: Dashboard ID `7249`
- **Nginx Ingress**: Dashboard ID `9614`

### Custom Dashboard Creation

1. **Create New Dashboard**: Click `+` → Dashboard
2. **Add Panel**: Click "Add Panel"
3. **Configure Query**:
   ```promql
   # HTTP request rate
   rate(http_requests_total[5m])
   
   # Error rate
   rate(http_errors_total[5m]) / rate(http_requests_total[5m]) * 100
   
   # Average response time
   rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])
   ```

## 📊 Custom Metrics

### Application Metrics Implementation

**File**: `src/app.js`

```javascript
import client from 'prom-client';

// Initialize default metrics collection
collectDefaultMetrics();

// Custom HTTP metrics
export const httpRequestCounter = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

export const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 10]
});

export const httpErrorCounter = new client.Counter({
  name: 'http_errors_total',
  help: 'Total number of HTTP errors (4xx, 5xx)',
  labelNames: ['status_code', 'route']
});

export const activeRequests = new client.Gauge({
  name: 'active_requests',
  help: 'Number of active HTTP requests'
});
```

### Business Metrics

```javascript
// Authentication metrics
export const authMetrics = {
  loginAttempts: new client.Counter({
    name: 'auth_login_attempts_total',
    help: 'Total login attempts',
    labelNames: ['status']
  }),
  
  registrations: new client.Counter({
    name: 'user_registrations_total',
    help: 'Total user registrations',
    labelNames: ['role']
  }),
  
  activeUsers: new client.Gauge({
    name: 'active_users_count',
    help: 'Number of currently active users'
  })
};

// Database metrics
export const dbMetrics = {
  queryDuration: new client.Histogram({
    name: 'db_query_duration_seconds',
    help: 'Database query duration',
    labelNames: ['operation', 'table']
  }),
  
  connectionPool: new client.Gauge({
    name: 'db_connections_active',
    help: 'Active database connections'
  })
};
```

### Metrics Middleware

```javascript
// Request tracking middleware
app.use((req, res, next) => {
  const start = process.hrtime();
  activeRequests.inc(1);
  
  res.on('finish', () => {
    const duration = process.hrtime(start);
    const responseTime = duration[0] + duration[1] / 1e9;
    
    // Record metrics
    httpRequestDuration
      .labels(req.method, req.route?.path || req.path, res.statusCode)
      .observe(responseTime);
      
    httpRequestCounter.inc({
      method: req.method,
      route: req.route?.path || req.path,
      status_code: res.statusCode
    });
    
    if (res.statusCode >= 400) {
      httpErrorCounter.inc({
        status_code: res.statusCode,
        route: req.route?.path || req.path
      });
    }
    
    activeRequests.dec(1);
  });
  
  next();
});
```

## 🔔 Alerting

### AlertManager Configuration

**File**: `alerting-rules.yaml`

```yaml
groups:
- name: inputly.rules
  rules:
  - alert: HighErrorRate
    expr: rate(http_errors_total[5m]) / rate(http_requests_total[5m]) > 0.1
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: High error rate detected
      description: "Error rate is {{ $value | humanizePercentage }} for 2 minutes"

  - alert: HighResponseTime
    expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: High response time detected
      description: "95th percentile response time is {{ $value }}s"

  - alert: ServiceDown
    expr: up{job="inputly-api"} == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: Inputly API service is down
      description: "Service has been down for {{ $value }} minutes"

  - alert: HighMemoryUsage
    expr: (nodejs_heap_size_used_bytes / nodejs_heap_size_total_bytes) > 0.9
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: High memory usage
      description: "Memory usage is at {{ $value | humanizePercentage }}"
```

### Notification Channels

#### Slack Integration
```yaml
# alertmanager.yml
route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
- name: 'web.hook'
  slack_configs:
  - api_url: 'YOUR_SLACK_WEBHOOK_URL'
    channel: '#alerts'
    title: 'Inputly Alert'
    text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
```

#### Email Notifications
```yaml
receivers:
- name: 'email-notifications'
  email_configs:
  - to: 'admin@your-domain.com'
    from: 'alerts@your-domain.com'
    smarthost: 'smtp.gmail.com:587'
    auth_username: 'alerts@your-domain.com'
    auth_password: 'your-app-password'
    subject: 'Inputly Alert: {{ .GroupLabels.alertname }}'
    body: |
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      {{ end }}
```

## 📝 Log Management

### Structured Logging

**File**: `src/config/logger.js`

```javascript
import winston from 'winston';

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'inputly-api' },
  transports: [
    new winston.transports.File({ 
      filename: 'logs/error.log', 
      level: 'error',
      maxsize: 5242880, // 5MB
      maxFiles: 5
    }),
    new winston.transports.File({ 
      filename: 'logs/combined.log',
      maxsize: 5242880,
      maxFiles: 5
    })
  ]
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.combine(
      winston.format.colorize(),
      winston.format.simple()
    )
  }));
}

export default logger;
```

### Log Aggregation

#### Centralized Logging with ELK Stack
```yaml
# filebeat.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /app/logs/*.log
  json.keys_under_root: true
  json.message_key: message

output.elasticsearch:
  hosts: ["elasticsearch:9200"]

setup.kibana:
  host: "kibana:5601"
```

#### Log Analysis Queries

**Prometheus Log Metrics**:
```promql
# Error logs per minute
increase(log_entries{level="error"}[1m])

# Warning logs trend
rate(log_entries{level="warn"}[5m])

# Log volume by service
sum(rate(log_entries[5m])) by (service)
```

## 🏥 Health Checks

### Application Health Endpoint

**Implementation**: `src/app.js`

```javascript
app.get('/health', (req, res) => {
  const healthCheck = {
    status: 'OK',
    message: 'Inputly is running',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memoryUsage: process.memoryUsage(),
    environment: process.env.NODE_ENV,
    nodeVersion: process.version,
    pid: process.pid
  };

  // Add database check
  try {
    // Perform database ping
    healthCheck.database = 'connected';
  } catch (error) {
    healthCheck.database = 'disconnected';
    healthCheck.status = 'ERROR';
  }

  const statusCode = healthCheck.status === 'OK' ? 200 : 503;
  res.status(statusCode).json(healthCheck);
});
```

### Kubernetes Health Checks

**File**: `deploy/helm/inputly-api/templates/deployment.yaml`

```yaml
spec:
  containers:
  - name: inputly-api
    livenessProbe:
      httpGet:
        path: /health
        port: 3000
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
    
    readinessProbe:
      httpGet:
        path: /health
        port: 3000
      initialDelaySeconds: 5
      periodSeconds: 5
      timeoutSeconds: 3
      successThreshold: 1
      failureThreshold: 3
```

### External Health Monitoring

```bash
# Uptime monitoring with curl
while true; do
  if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    echo "$(date): Service is healthy"
  else
    echo "$(date): Service is down!"
  fi
  sleep 30
done
```

## 🚀 Performance Monitoring

### Key Performance Metrics

#### Response Time Monitoring
```promql
# Average response time
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])

# 95th percentile response time
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Response time by endpoint
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{route=~"/api/.*"}[5m])) by (route)
```

#### Throughput Monitoring
```promql
# Requests per second
rate(http_requests_total[5m])

# Requests per second by status code
rate(http_requests_total[5m]) by (status_code)

# Peak traffic analysis
max_over_time(rate(http_requests_total[1m])[24h:1m])
```

#### Error Rate Monitoring
```promql
# Overall error rate
rate(http_errors_total[5m]) / rate(http_requests_total[5m]) * 100

# Error rate by endpoint
rate(http_errors_total[5m]) by (route) / rate(http_requests_total[5m]) by (route) * 100

# 4xx vs 5xx errors
rate(http_requests_total{status_code=~"4.."}[5m]) by (status_code)
```

### Performance Dashboards

#### SLI/SLO Dashboard
```json
{
  "title": "Inputly SLI/SLO Dashboard",
  "panels": [
    {
      "title": "Availability (SLO: 99.9%)",
      "targets": [{
        "expr": "avg_over_time((up{job=\"inputly-api\"})[7d:5m]) * 100"
      }],
      "thresholds": [
        {"value": 99.9, "colorMode": "critical", "op": "lt"}
      ]
    },
    {
      "title": "Latency (SLO: 95% < 500ms)",
      "targets": [{
        "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) * 1000"
      }],
      "thresholds": [
        {"value": 500, "colorMode": "critical", "op": "gt"}
      ]
    }
  ]
}
```

## 🛠️ Troubleshooting

### Common Monitoring Issues

#### 1. Metrics Not Appearing

**Check ServiceMonitor**:
```bash
# Verify ServiceMonitor exists
kubectl get servicemonitor -n inputly

# Check ServiceMonitor configuration
kubectl describe servicemonitor inputly-api -n inputly

# Check service labels
kubectl get svc inputly-api -n inputly --show-labels
```

**Fix ServiceMonitor Issues**:
```bash
# Apply monitoring fixes
./src/scripts/fix-monitoring.sh

# Restart Prometheus
kubectl rollout restart statefulset/prometheus-kube-prometheus-stack-prometheus -n monitoring
```

#### 2. Grafana Access Issues

**Check Grafana Pod**:
```bash
# Check pod status
kubectl get pods -n monitoring | grep grafana

# Check pod logs
kubectl logs -n monitoring deployment/kube-prometheus-stack-grafana

# Check service
kubectl get svc -n monitoring | grep grafana
```

**Fix Grafana Access**:
```bash
# Setup access automatically
./src/scripts/setup-grafana-access.sh

# Manual port forward
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3001:80
```

#### 3. High Memory Usage

**Monitor Memory**:
```promql
# Node.js heap usage
nodejs_heap_size_used_bytes / nodejs_heap_size_total_bytes * 100

# Container memory usage
container_memory_usage_bytes{pod=~"inputly-api-.*"} / container_spec_memory_limit_bytes * 100
```

**Memory Optimization**:
```javascript
// Implement memory monitoring
setInterval(() => {
  const memUsage = process.memoryUsage();
  if (memUsage.heapUsed / memUsage.heapTotal > 0.8) {
    logger.warn('High memory usage detected', memUsage);
  }
}, 60000);
```

### Monitoring Health Check Script

**File**: `src/scripts/monitor-health.sh`

```bash
#!/bin/bash
# Monitoring health check script

echo "🔍 Checking Monitoring Stack Health"

# Check Prometheus
if kubectl get pods -n monitoring | grep prometheus | grep Running; then
  echo "✅ Prometheus is running"
else
  echo "❌ Prometheus issues detected"
fi

# Check Grafana
if kubectl get pods -n monitoring | grep grafana | grep Running; then
  echo "✅ Grafana is running"
else
  echo "❌ Grafana issues detected"
fi

# Check metrics endpoint
if curl -s http://localhost:3000/metrics | grep -q "http_requests_total"; then
  echo "✅ Metrics endpoint working"
else
  echo "❌ Metrics endpoint issues"
fi

# Check ServiceMonitor
if kubectl get servicemonitor inputly-api -n inputly &>/dev/null; then
  echo "✅ ServiceMonitor exists"
else
  echo "❌ ServiceMonitor missing"
fi

echo "🏁 Health check complete"
```

### Debug Commands

```bash
# Check all monitoring resources
kubectl get all -n monitoring

# Check Prometheus configuration
kubectl get prometheus -n monitoring -o yaml

# Check alert rules
kubectl get prometheusrule -n monitoring

# Check service discovery
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Visit http://localhost:9090/service-discovery

# Check targets
# Visit http://localhost:9090/targets
```

## 📊 Monitoring Best Practices

### Metrics Best Practices

1. **Use Appropriate Metric Types**:
   - **Counter**: Monotonically increasing values (requests, errors)
   - **Gauge**: Values that can go up/down (memory, connections)
   - **Histogram**: Distribution of values (response times)
   - **Summary**: Similar to histogram but with quantiles

2. **Label Guidelines**:
   - Keep cardinality low (< 1000 unique combinations)
   - Use meaningful label names
   - Avoid user-specific labels (user_id, session_id)

3. **Naming Conventions**:
   - Use snake_case for metric names
   - Include units in name (`_seconds`, `_bytes`, `_total`)
   - Be consistent across services

### Dashboard Best Practices

1. **Dashboard Organization**:
   - Group related metrics together
   - Use consistent time ranges
   - Add descriptions and documentation

2. **Visualization Guidelines**:
   - Use appropriate chart types
   - Set meaningful Y-axis ranges
   - Add thresholds for SLOs

3. **Alert Guidelines**:
   - Alert on symptoms, not causes
   - Avoid alert fatigue
   - Include runbooks in alert descriptions

## 🔗 Related Documentation

- [Architecture Overview](./architecture.md) - System design and components
- [Security Guide](./security.md) - Security monitoring and best practices  
- [Deployment Guide](./deployment.md) - Monitoring deployment instructions
- [API Documentation](./api.md) - API metrics and health endpoints

---

**Monitoring is the key to reliable operations. Monitor everything that matters!** 📊

For monitoring questions or issues, create an issue on [GitHub](https://github.com/thulanibango/Inputly/issues) or contact the team.