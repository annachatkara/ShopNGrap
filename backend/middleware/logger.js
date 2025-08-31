import winston from 'winston';
import morgan from 'morgan';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// ESM equivalent of __filename and __dirname
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Create logs directory if it doesn't exist
const logsDir = path.join(__dirname, '../logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

// Winston logger configuration
export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'flutter-app-backend' },
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
        winston.format.printf(({ level, message, timestamp, stack }) => {
          return `${timestamp} [${level}]: ${stack || message}`;
        })
      ),
      level: process.env.NODE_ENV === 'production' ? 'warn' : 'debug'
    }),
    new winston.transports.File({
      filename: path.join(logsDir, 'error.log'),
      level: 'error',
      maxsize: 5242880,
      maxFiles: 5,
    }),
    new winston.transports.File({
      filename: path.join(logsDir, 'combined.log'),
      maxsize: 5242880,
      maxFiles: 5,
    }),
    new winston.transports.File({
      filename: path.join(logsDir, 'database.log'),
      level: 'debug',
      maxsize: 5242880,
      maxFiles: 3,
    })
  ]
});

// Morgan HTTP logger
export const httpLogger = process.env.NODE_ENV === 'production'
  ? morgan('combined', { stream: { write: (msg) => logger.info(msg.trim()) }, skip: (req) => req.url === '/health' || req.url.startsWith('/static') })
  : morgan('dev', { skip: (req) => req.url === '/health' });

// Request ID middleware
export const requestIdMiddleware = (req, res, next) => {
  req.id = Math.random().toString(36).substr(2, 9);
  res.setHeader('X-Request-ID', req.id);

  const originalLog = logger.log;
  logger.log = function(level, message, meta = {}) {
    meta.requestId = req.id;
    originalLog.call(this, level, message, meta);
  };

  next();
};