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
const app = express();
app.use(helmet());
app.use(cors());
app.use(cookieParser());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(securityMiddleware);
// Attach req.user if a valid JWT exists (from Authorization bearer or cookies)
app.use(attachUser);
app.use(morgan('combined', { stream: { write: (message) => logger.info(message.trim()) } }));

app.get('/', (res) => {
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
