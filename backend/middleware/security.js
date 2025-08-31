// Security configurations middleware
// ...implement security configurations here...
import helmet from 'helmet';
import cors from 'cors';
import compression from 'compression';
import { createRateLimiter } from './auth.js';

// CORS configuration
const corsOptions = {
  origin: function (origin, callback) {
    const allowedOrigins = (process.env.ALLOWED_ORIGINS || 'http://localhost:3000').split(',');

    // Allow requests with no origin (mobile apps, etc.)
    if (!origin || allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  exposedHeaders: ['X-Request-ID', 'X-Total-Count']
};

// Helmet configuration for security headers
const helmetOptions = {
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  crossOriginEmbedderPolicy: false,
};

// Rate limiting configurations
const rateLimiters = {
  general: createRateLimiter(15 * 60 * 1000, 100), // 100 requests per 15 minutes
  auth: createRateLimiter(15 * 60 * 1000, 5, 'Too many authentication attempts'), // 5 attempts per 15 minutes
  api: createRateLimiter(60 * 1000, 60), // 60 requests per minute for API
  upload: createRateLimiter(60 * 60 * 1000, 10), // 10 uploads per hour
};

// Security middleware setup
const setupSecurity = (app) => {
  // Trust proxy for accurate IP addresses
  app.set('trust proxy', 1);

  // Helmet for security headers
  app.use(helmet(helmetOptions));

  // CORS
  app.use(cors(corsOptions));

  // Compression
  app.use(compression({
    level: 6,
    threshold: 1024, // Only compress responses > 1KB
    filter: (req, res) => {
      // Don't compress responses with this request header
      if (req.headers['x-no-compression']) {
        return false;
      }

      // Fallback to standard filter function
      return compression.filter(req, res);
    }
  }));

  // General rate limiting
  app.use('/api/', rateLimiters.api);
};

export {
  setupSecurity,
  corsOptions,
  rateLimiters
};
