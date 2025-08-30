const express = require('express');
const cookieParser = require('cookie-parser');
require('dotenv').config();

// Import configurations and middleware
const { connectDB, disconnectDB } = require('./config/database');
const { setupSecurity, rateLimiters } = require('./middleware/security');
const { logger, httpLogger, requestIdMiddleware } = require('./middleware/logger');
const { globalErrorHandler, handleNotFound } = require('./middleware/errorHandler');

// Import marketplace-specific routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/user');
const shopRoutes = require('./routes/shop');
const itemRoutes = require('./routes/item');
const orderRoutes = require('./routes/order');
const paymentRoutes = require('./routes/payment');

class Server {
  constructor() {
    this.app = express();
    this.port = process.env.PORT || 3000;
    this.setupMiddleware();
    this.setupRoutes();
    this.setupErrorHandling();
  }

  setupMiddleware() {
    // Trust proxy for accurate IP addresses (important for rate limiting)
    this.app.set('trust proxy', 1);

    // Security middleware
    setupSecurity(this.app);

    // Request logging and tracking
    this.app.use(requestIdMiddleware);
    this.app.use(httpLogger);

    // Body parsing middleware
    this.app.use(express.json({ 
      limit: '10mb',
      verify: (req, res, buf) => {
        try {
          JSON.parse(buf);
        } catch (e) {
          res.status(400).json({ 
            success: false, 
            message: 'Invalid JSON format' 
          });
          throw new Error('Invalid JSON');
        }
      }
    }));

    this.app.use(express.urlencoded({ 
      extended: true, 
      limit: '10mb' 
    }));

    // Cookie parsing
    this.app.use(cookieParser());

    // Additional security headers
    this.app.use((req, res, next) => {
      res.removeHeader('X-Powered-By');
      res.setHeader('X-Content-Type-Options', 'nosniff');
      res.setHeader('X-Frame-Options', 'DENY');
      res.setHeader('X-XSS-Protection', '1; mode=block');
      next();
    });

    // Request logging for development
    if (process.env.NODE_ENV === 'development') {
      this.app.use((req, res, next) => {
        logger.debug(`${req.method} ${req.url}`, {
          ip: req.ip,
          userAgent: req.get('User-Agent'),
          body: req.method === 'POST' || req.method === 'PATCH' ? req.body : undefined
        });
        next();
      });
    }
  }

  setupRoutes() {
    // Health check endpoint (should be before rate limiting)
    this.app.get('/health', (req, res) => {
      res.status(200).json({
        success: true,
        message: 'Server is healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        version: process.env.npm_package_version || '1.0.0',
        environment: process.env.NODE_ENV || 'development'
      });
    });

    // API info endpoint
    this.app.get('/api', (req, res) => {
      res.json({
        success: true,
        message: 'Flutter App Backend API',
        version: 'v1.0.0',
        documentation: '/api/docs',
        endpoints: {
          auth: '/api/auth',
          users: '/api/users',
          shops: '/api/shops',
          items: '/api/items',
          orders: '/api/orders',
          payments: '/api/payments'
        }
      });
    });

    // Rate limiting for API routes
    this.app.use('/api', rateLimiters.api);

    // API routes for marketplace app
    this.app.use('/api/auth', authRoutes);
    this.app.use('/api/users', userRoutes);
    this.app.use('/api/shops', shopRoutes);
    this.app.use('/api/items', itemRoutes);
    this.app.use('/api/orders', orderRoutes);
    this.app.use('/api/payments', paymentRoutes);

    // Serve static files (for uploaded images, etc.)
    this.app.use('/uploads', express.static('uploads', {
      maxAge: '1d',
      etag: true
    }));

    // API documentation endpoint (placeholder)
    this.app.get('/api/docs', (req, res) => {
      res.json({
        success: true,
        message: 'API Documentation',
        note: 'Implement Swagger/OpenAPI documentation here',
        version: 'v1.0.0'
      });
    });
  }

  setupErrorHandling() {
    // Handle 404 for undefined routes
    this.app.use(handleNotFound);

    // Global error handling middleware
    this.app.use(globalErrorHandler);

    // Handle uncaught exceptions
    process.on('uncaughtException', (err) => {
      logger.error('UNCAUGHT EXCEPTION! 💥 Shutting down...', {
        error: err.name,
        message: err.message,
        stack: err.stack
      });
      process.exit(1);
    });

    // Handle unhandled promise rejections
    process.on('unhandledRejection', (err) => {
      logger.error('UNHANDLED REJECTION! 💥 Shutting down...', {
        error: err.name,
        message: err.message,
        stack: err.stack
      });
      this.server?.close(() => {
        process.exit(1);
      });
    });

    // Graceful shutdown
    process.on('SIGTERM', this.gracefulShutdown.bind(this));
    process.on('SIGINT', this.gracefulShutdown.bind(this));
  }

  async gracefulShutdown(signal) {
    logger.info(`Received ${signal}. Starting graceful shutdown...`);

    // Stop accepting new connections
    if (this.server) {
      this.server.close(async () => {
        logger.info('HTTP server closed');

        try {
          // Close database connection
          await disconnectDB();
          logger.info('Database connection closed');

          logger.info('Graceful shutdown completed');
          process.exit(0);
        } catch (error) {
          logger.error('Error during graceful shutdown:', error);
          process.exit(1);
        }
      });

      // Force close server after 10 seconds
      setTimeout(() => {
        logger.error('Could not close connections in time, forcefully shutting down');
        process.exit(1);
      }, 10000);
    }
  }

  async start() {
    try {
      // Connect to database
      await connectDB();

      // Start server
      this.server = this.app.listen(this.port, () => {
        logger.info(`🚀 Server running on port ${this.port} in ${process.env.NODE_ENV || 'development'} mode`);
        logger.info(`📖 API Documentation: http://localhost:${this.port}/api/docs`);
        logger.info(`🔍 Health Check: http://localhost:${this.port}/health`);

        if (process.env.NODE_ENV === 'development') {
          logger.info(`🎯 API Base URL: http://localhost:${this.port}/api`);
        }
      });

      // Handle server errors
      this.server.on('error', (err) => {
        if (err.code === 'EADDRINUSE') {
          logger.error(`Port ${this.port} is already in use`);
        } else {
          logger.error('Server error:', err);
        }
        process.exit(1);
      });

    } catch (error) {
      logger.error('Failed to start server:', error);
      process.exit(1);
    }
  }
}

// Start server if this file is run directly
if (require.main === module) {
  const server = new Server();
  server.start();
}

module.exports = Server;
