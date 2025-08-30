// JWT authentication middleware
// ...implement JWT authentication here...
const jwt = require('jsonwebtoken');
const { prisma } = require('../config/database');
const { AppError, catchAsync } = require('./errorHandler');
const { logger } = require('./logger');

// Generate JWT token
const generateToken = (payload) => {
  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE || '7d',
  });
};

// Generate refresh token
const generateRefreshToken = (payload) => {
  return jwt.sign(payload, process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_REFRESH_EXPIRE || '30d',
  });
};

// Verify JWT token
const verifyToken = catchAsync(async (req, res, next) => {
  // 1) Check if token exists
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  } else if (req.cookies?.jwt) {
    token = req.cookies.jwt;
  }

  if (!token) {
    return next(new AppError('You are not logged in! Please log in to get access.', 401));
  }

  // 2) Verify token
  let decoded;
  try {
    decoded = jwt.verify(token, process.env.JWT_SECRET);
  } catch (err) {
    return next(new AppError('Invalid token. Please log in again.', 401));
  }

  // 3) Check if user still exists
  const user = await prisma.user.findUnique({
    where: { id: decoded.userId },
    select: {
      id: true,
      email: true,
      username: true,
      firstName: true,
      lastName: true,
      isActive: true,
      isEmailVerified: true,
      lastLoginAt: true,
    }
  });

  if (!user) {
    return next(new AppError('The user belonging to this token no longer exists.', 401));
  }

  if (!user.isActive) {
    return next(new AppError('Your account has been deactivated. Please contact support.', 401));
  }

  // 4) Check if session is valid
  const session = await prisma.userSession.findFirst({
    where: {
      userId: user.id,
      sessionToken: token,
      isActive: true,
      expiresAt: {
        gt: new Date()
      }
    }
  });

  if (!session) {
    return next(new AppError('Invalid session. Please log in again.', 401));
  }

  // 5) Update last used time for session
  await prisma.userSession.update({
    where: { id: session.id },
    data: { lastUsedAt: new Date() }
  });

  // Grant access to protected route
  req.user = user;
  req.session = session;
  next();
});

// Optional authentication (doesn't throw error if no token)
const optionalAuth = catchAsync(async (req, res, next) => {
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  if (token) {
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await prisma.user.findUnique({
        where: { id: decoded.userId },
        select: {
          id: true,
          email: true,
          username: true,
          firstName: true,
          lastName: true,
          isActive: true,
        }
      });

      if (user && user.isActive) {
        req.user = user;
      }
    } catch (err) {
      // Continue without user if token is invalid
      logger.debug('Optional auth failed:', err.message);
    }
  }

  next();
});

// Check if user is email verified
const requireEmailVerification = (req, res, next) => {
  if (!req.user.isEmailVerified) {
    return next(new AppError('Please verify your email address to continue.', 403));
  }
  next();
};

// Role-based access control
const restrictTo = (...roles) => {
  return catchAsync(async (req, res, next) => {
    // For now, we don't have roles in schema, but you can extend this
    // This is a placeholder for future role implementation
    if (!req.user) {
      return next(new AppError('You are not logged in!', 401));
    }

    // You can add role checking logic here when you implement roles
    next();
  });
};

// Check if user owns the resource
const checkOwnership = (model, idField = 'id', userField = 'userId') => {
  return catchAsync(async (req, res, next) => {
    const resourceId = req.params[idField];

    if (!resourceId) {
      return next(new AppError('Resource ID is required', 400));
    }

    const resource = await prisma[model].findUnique({
      where: { id: resourceId },
      select: { [userField]: true }
    });

    if (!resource) {
      return next(new AppError('Resource not found', 404));
    }

    if (resource[userField] !== req.user.id) {
      return next(new AppError('You can only access your own resources', 403));
    }

    next();
  });
};

// Rate limiting middleware
const createRateLimiter = (windowMs = 15 * 60 * 1000, max = 100, message) => {
  const rateLimit = require('express-rate-limit');

  return rateLimit({
    windowMs,
    max,
    message: message || 'Too many requests from this IP, please try again later.',
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res, next) => {
      logger.warn(`Rate limit exceeded for IP: ${req.ip}`, {
        ip: req.ip,
        url: req.url,
        userAgent: req.get('User-Agent')
      });
      next(new AppError('Too many requests, please try again later.', 429));
    }
  });
};

module.exports = {
  generateToken,
  generateRefreshToken,
  verifyToken,
  optionalAuth,
  requireEmailVerification,
  restrictTo,
  checkOwnership,
  createRateLimiter
};
