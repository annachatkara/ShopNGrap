// Winston logging setup
// ...implement logger setup here...
const winston = require('winston');
const morgan = require('morgan');
const path = require('path');
const fs = require('fs');

// Create logs directory if it doesn't exist
const logsDir = path.join(__dirname, '../logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

// Winston logger configuration
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp({
      format: 'YYYY-MM-DD HH:mm:ss'
    }),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'flutter-app-backend' },
  transports: [
    // Console transport with colors for development
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.timestamp({
          format: 'YYYY-MM-DD HH:mm:ss'
        }),
        winston.format.printf(({ level, message, timestamp, stack }) => {
          return `${timestamp} [${level}]: ${stack || message}`;
        })
      ),
      level: process.env.NODE_ENV === 'production' ? 'warn' : 'debug'
    }),

    // Error log file
    new winston.transports.File({
      filename: path.join(logsDir, 'error.log'),
      level: 'error',
      maxsize: 5242880, // 5MB
      maxFiles: 5,
    }),

    // Combined log file
    new winston.transports.File({
      filename: path.join(logsDir, 'combined.log'),
      maxsize: 5242880, // 5MB
      maxFiles: 5,
    }),

    // Separate file for database operations
    new winston.transports.File({
      filename: path.join(logsDir, 'database.log'),
      level: 'debug',
      maxsize: 5242880, // 5MB
      maxFiles: 3,
    })
  ]
});

// Morgan HTTP request logger
const httpLogger = morgan('combined', {
  stream: {
    write: (message) => {
      logger.info(message.trim());
    }
  },
  skip: (req, res) => {
    // Skip logging for health check and static files
    return req.url === '/health' || req.url.startsWith('/static');
  }
});

// Morgan for development with colored output
const devHttpLogger = morgan('dev', {
  skip: (req, res) => {
    return req.url === '/health';
  }
});

// Request ID middleware for tracking requests
const requestIdMiddleware = (req, res, next) => {
  req.id = Math.random().toString(36).substr(2, 9);
  res.setHeader('X-Request-ID', req.id);

  // Add request ID to logger context
  const originalLog = logger.log;
  logger.log = function(level, message, meta = {}) {
    meta.requestId = req.id;
    originalLog.call(this, level, message, meta);
  };

  next();
};

module.exports = {
  logger,
  httpLogger: process.env.NODE_ENV === 'production' ? httpLogger : devHttpLogger,
  requestIdMiddleware
};
