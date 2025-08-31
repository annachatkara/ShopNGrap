// Global error handling middleware
// ...implement error handling here...
import { logger } from './logger.js';

// Custom error class
class AppError extends Error {
  constructor(message, statusCode, isOperational = true, stack = '') {
    super(message);
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.isOperational = isOperational;

    if (stack) {
      this.stack = stack;
    } else {
      Error.captureStackTrace(this, this.constructor);
    }
  }
}

// Error response formatter
const formatErrorResponse = (err, req) => {
  const errorResponse = {
    success: false,
    message: err.message,
    timestamp: new Date().toISOString(),
    requestId: req.id,
  };

  if (process.env.NODE_ENV === 'development') {
    errorResponse.stack = err.stack;
    errorResponse.error = err;
  }

  return errorResponse;
};

// Handle Prisma errors
const handlePrismaError = (err) => {
  if (err.code === 'P2002') {
    const field = err.meta?.target?.[0] || 'field';
    return new AppError(`Duplicate value for ${field}`, 400);
  }

  if (err.code === 'P2025') {
    return new AppError('Record not found', 404);
  }

  if (err.code === 'P2003') {
    return new AppError('Foreign key constraint violation', 400);
  }

  if (err.code === 'P2014') {
    return new AppError('Invalid data provided', 400);
  }

  return new AppError('Database operation failed', 500);
};

// Handle JWT errors
const handleJWTError = (err) => {
  if (err.name === 'JsonWebTokenError') {
    return new AppError('Invalid token', 401);
  }

  if (err.name === 'TokenExpiredError') {
    return new AppError('Token expired', 401);
  }

  return new AppError('Authentication failed', 401);
};

// Handle validation errors
const handleValidationError = (err) => {
  const errors = err.errors || [];
  const message = errors.map(error => error.msg).join(', ');
  return new AppError(`Validation failed: ${message}`, 400);
};

// Global error handling middleware
const globalErrorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;

  // Log error
  logger.error(`Error ${err.statusCode || 500}: ${err.message}`, {
    requestId: req.id,
    url: req.url,
    method: req.method,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    stack: err.stack,
    user: req.user?.id || 'anonymous'
  });

  // Handle specific error types
  if (err.name === 'PrismaClientKnownRequestError') {
    error = handlePrismaError(err);
  } else if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
    error = handleJWTError(err);
  } else if (err.array && typeof err.array === 'function') {
    error = handleValidationError(err);
  }

  // Send error response
  res.status(error.statusCode || 500).json(
    formatErrorResponse(error, req)
  );
};

// Catch async errors wrapper
const catchAsync = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

// Handle unhandled routes
const handleNotFound = (req, res, next) => {
  const error = new AppError(`Route ${req.originalUrl} not found`, 404);
  next(error);
};

export {
  AppError,
  globalErrorHandler,
  catchAsync,
  handleNotFound
};
