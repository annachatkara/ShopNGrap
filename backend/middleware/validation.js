// Input validation rules middleware
// ...implement validation rules here...
const { body, param, query, validationResult } = require('express-validator');
const { AppError } = require('./errorHandler');

// Handle validation errors
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const errorMessages = errors.array().map(error => ({
      field: error.param,
      message: error.msg,
      value: error.value
    }));

    return next(new AppError(`Validation failed: ${errorMessages.map(e => e.message).join(', ')}`, 400));
  }
  next();
};

// Common validation rules
const validators = {
  // User validation
  email: () => body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email address'),

  password: () => body('password')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters long')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Password must contain at least one uppercase letter, one lowercase letter, and one number'),

  firstName: () => body('firstName')
    .isLength({ min: 2, max: 50 })
    .withMessage('First name must be between 2 and 50 characters')
    .matches(/^[a-zA-Z\s]+$/)
    .withMessage('First name should only contain letters and spaces'),

  lastName: () => body('lastName')
    .isLength({ min: 2, max: 50 })
    .withMessage('Last name must be between 2 and 50 characters')
    .matches(/^[a-zA-Z\s]+$/)
    .withMessage('Last name should only contain letters and spaces'),

  username: () => body('username')
    .optional()
    .isLength({ min: 3, max: 30 })
    .withMessage('Username must be between 3 and 30 characters')
    .matches(/^[a-zA-Z0-9_]+$/)
    .withMessage('Username can only contain letters, numbers, and underscores'),

  phoneNumber: () => body('phoneNumber')
    .optional()
    .matches(/^\+?[1-9]\d{1,14}$/)
    .withMessage('Please provide a valid phone number'),

  // Post validation
  title: () => body('title')
    .optional()
    .isLength({ min: 1, max: 200 })
    .withMessage('Title must be between 1 and 200 characters'),

  content: () => body('content')
    .isLength({ min: 1, max: 5000 })
    .withMessage('Content must be between 1 and 5000 characters'),

  // Comment validation
  commentContent: () => body('content')
    .isLength({ min: 1, max: 1000 })
    .withMessage('Comment must be between 1 and 1000 characters'),

  // General validations
  id: (field = 'id') => param(field)
    .matches(/^[a-zA-Z0-9_-]+$/)
    .withMessage('Invalid ID format'),

  page: () => query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Page must be a positive integer'),

  limit: () => query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100'),

  search: () => query('search')
    .optional()
    .isLength({ min: 1, max: 100 })
    .withMessage('Search query must be between 1 and 100 characters'),
};

// Validation rule sets for different operations
const validationRules = {
  // Authentication
  register: [
    validators.email(),
    validators.password(),
    validators.firstName(),
    validators.lastName(),
    validators.username(),
    validators.phoneNumber(),
    handleValidationErrors
  ],

  login: [
    validators.email(),
    body('password').notEmpty().withMessage('Password is required'),
    handleValidationErrors
  ],

  resetPassword: [
    validators.email(),
    handleValidationErrors
  ],

  changePassword: [
    body('currentPassword').notEmpty().withMessage('Current password is required'),
    validators.password(),
    handleValidationErrors
  ],

  // User profile
  updateProfile: [
    validators.firstName(),
    validators.lastName(),
    validators.username(),
    validators.phoneNumber(),
    body('dateOfBirth')
      .optional()
      .isISO8601()
      .withMessage('Date of birth must be a valid date'),
    handleValidationErrors
  ],

  // Posts
  createPost: [
    validators.title(),
    validators.content(),
    body('imageUrls')
      .optional()
      .isArray()
      .withMessage('Image URLs must be an array'),
    body('imageUrls.*')
      .isURL()
      .withMessage('Each image URL must be valid'),
    handleValidationErrors
  ],

  updatePost: [
    validators.title(),
    validators.content(),
    handleValidationErrors
  ],

  // Comments
  createComment: [
    validators.commentContent(),
    validators.id('postId'),
    handleValidationErrors
  ],

  // General
  getById: [
    validators.id(),
    handleValidationErrors
  ],

  pagination: [
    validators.page(),
    validators.limit(),
    validators.search(),
    handleValidationErrors
  ],

  // Notifications
  markAsRead: [
    validators.id(),
    handleValidationErrors
  ]
};

module.exports = {
  validators,
  validationRules,
  handleValidationErrors
};
