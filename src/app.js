import express from 'express';
import logger from '#config/logger.js';
import helmet from 'helmet';
import morgan from 'morgan';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import authRoutes from '#routes/auth.routes.js';
import securityMiddleware from '#middleware/security.middleware.js';
const app = express();
app.use(helmet());
app.use(cors());
app.use(cookieParser());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(securityMiddleware)
app.use(morgan('combined', { stream: { write: (message) => logger.info(message.trim()) } }));

app.get('/', (req, res) => {
  logger.info("Hello from Inputly!");
  res.status(200).send('Hello from Inputly!');
});
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'Inputly is running', timestamp: new Date().toISOString(), uptime: process.uptime(), memoryUsage: process.memoryUsage() });
})
app.get('/api', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'Inputly is running', timestamp: new Date().toISOString(), uptime: process.uptime(), memoryUsage: process.memoryUsage() });
})
app.use('/api/auth', authRoutes);
export default app;
