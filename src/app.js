import express from 'express';
import logger from '#config/logger.js';
import helmet from 'helmet';
import morgan from 'morgan';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import authRoutes from '#routes/auth.routes.js';
import usersRoutes from '#routes/users.routes.js';
import securityMiddleware from '#middleware/security.middleware.js';
import { attachUser } from '#middleware/auth.middleware.js';
import client from 'prom-client';

const app = express();
app.use(helmet());

// Initialize Prometheus metrics
const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics();

// Define custom metrics
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

// Create a middleware to track requests
app.use((req, res, next) => {
  const start = process.hrtime();
  activeRequests.inc(1);
  
  res.on('finish', () => {
    const duration = process.hrtime(start);
    const responseTime = duration[0] + duration[1] / 1e9; // Convert to seconds
    
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

// Expose /metrics for Prometheus
app.get("/metrics", async (req, res) => {
  try {
    res.set("Content-Type", client.register.contentType);
    const metrics = await client.register.metrics();
    res.status(200).send(metrics);
  } catch (e) {
    res.status(500).send(e.message);
  }
});

// CORS configuration for credentials support
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? ['http://inputly.local', 'https://inputly.local'] // Production domains
    : ['http://localhost:3000', 'http://localhost:5173', 'http://localhost:8080'], // Development domains
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  optionsSuccessStatus: 200
}));
app.use(cookieParser());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(securityMiddleware);
// Attach req.user if a valid JWT exists (from Authorization bearer or cookies)
app.use(attachUser);
app.use(morgan('combined', { stream: { write: (message) => logger.info(message.trim()) } }));

app.get('/', (req, res) => {
  logger.info('Hello from Inputly!');
  res.status(200).send('Hello from Inputly!');
});
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'Inputly is running', timestamp: new Date().toISOString(), uptime: process.uptime(), memoryUsage: process.memoryUsage() });
});
app.get('/api', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'Inputly is running', timestamp: new Date().toISOString(), uptime: process.uptime(), memoryUsage: process.memoryUsage() });
});
app.use('/api/auth', authRoutes);
app.use('/api/users', usersRoutes);

app.use((req, res) => {
  res.status(404).json({ status: 'fail', message: 'route Not found' });
});

app.use((err, req, res, next) => {
  logger.error(err);
  res.status(500).json({ status: 'error', message: 'Internal server error' });
});
export default app;
