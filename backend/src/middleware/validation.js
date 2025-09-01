import { body, param, query, validationResult } from 'express-validator';

// Validation error handler
export const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      error: 'Validation failed',
      details: errors.array()
    });
  }
  next();
};

// Auth validations
export const validateRegister = [
  body('name')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Name must be between 2 and 50 characters'),
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Password must contain at least one lowercase letter, one uppercase letter, and one number'),
  body('phone')
    .optional()
    .isMobilePhone('en-IN')
    .withMessage('Please provide a valid Indian phone number'),
  handleValidationErrors
];

export const validateLogin = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('password')
    .notEmpty()
    .withMessage('Password is required'),
  handleValidationErrors
];

// Product validations
export const validateProduct = [
  body('name')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Product name must be between 2 and 100 characters'),
  body('description')
    .optional()
    .trim()
    .isLength({ max: 1000 })
    .withMessage('Description must be less than 1000 characters'),
  body('price')
    .isFloat({ min: 0.01 })
    .withMessage('Price must be a positive number'),
  body('stock')
    .isInt({ min: 0 })
    .withMessage('Stock must be a non-negative integer'),
  body('categoryId')
    .isInt({ min: 1 })
    .withMessage('Category ID must be a positive integer'),
  body('imageUrl')
    .optional()
    .isURL()
    .withMessage('Image URL must be a valid URL'),
  handleValidationErrors
];

// Category validations
export const validateCategory = [
  body('name')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Category name must be between 2 and 50 characters'),
  body('description')
    .optional()
    .trim()
    .isLength({ max: 200 })
    .withMessage('Description must be less than 200 characters'),
  handleValidationErrors
];

// Address validations
export const validateAddress = [
  body('fullName')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Full name must be between 2 and 50 characters'),
  body('phone')
    .isMobilePhone('en-IN')
    .withMessage('Please provide a valid Indian phone number'),
  body('pincode')
    .matches(/^[1-9][0-9]{5}$/)
    .withMessage('Please provide a valid 6-digit pincode'),
  body('street')
    .trim()
    .isLength({ min: 5, max: 100 })
    .withMessage('Street address must be between 5 and 100 characters'),
  body('city')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('City must be between 2 and 50 characters'),
  body('state')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('State must be between 2 and 50 characters'),
  body('country')
    .optional()
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Country must be between 2 and 50 characters'),
  body('isDefault')
    .optional()
    .isBoolean()
    .withMessage('isDefault must be a boolean'),
  handleValidationErrors
];

// Review validations
export const validateReview = [
  body('productId')
    .isInt({ min: 1 })
    .withMessage('Product ID must be a positive integer'),
  body('rating')
    .isInt({ min: 1, max: 5 })
    .withMessage('Rating must be between 1 and 5'),
  body('comment')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Comment must be less than 500 characters'),
  handleValidationErrors
];

// Cart validations
export const validateCartItem = [
  body('productId')
    .isInt({ min: 1 })
    .withMessage('Product ID must be a positive integer'),
  body('quantity')
    .isInt({ min: 1, max: 99 })
    .withMessage('Quantity must be between 1 and 99'),
  handleValidationErrors
];

// Order validations
export const validateOrder = [
  body('addressId')
    .isInt({ min: 1 })
    .withMessage('Address ID must be a positive integer'),
  body('paymentMethod')
    .isIn(['card', 'upi', 'netbanking', 'cod', 'wallet'])
    .withMessage('Invalid payment method'),
  handleValidationErrors
];

// Coupon validations
export const validateCoupon = [
  body('code')
    .trim()
    .isLength({ min: 3, max: 20 })
    .matches(/^[A-Z0-9]+$/)
    .withMessage('Coupon code must be 3-20 characters long and contain only uppercase letters and numbers'),
  body('discount')
    .isFloat({ min: 0.01 })
    .withMessage('Discount must be a positive number'),
  body('type')
    .isIn(['percentage', 'fixed'])
    .withMessage('Type must be either percentage or fixed'),
  body('expiryDate')
    .isISO8601()
    .toDate()
    .withMessage('Expiry date must be a valid date'),
  body('minOrder')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Minimum order must be a non-negative number'),
  body('maxDiscount')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Maximum discount must be a non-negative number'),
  body('usageLimit')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Usage limit must be a positive integer'),
  handleValidationErrors
];

// Shop validations
export const validateShop = [
  body('shopName')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Shop name must be between 2 and 100 characters'),
  body('shopDescription')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Shop description must be less than 500 characters'),
  body('shopAddress')
    .optional()
    .trim()
    .isLength({ max: 200 })
    .withMessage('Shop address must be less than 200 characters'),
  body('shopPhone')
    .optional()
    .isMobilePhone('en-IN')
    .withMessage('Please provide a valid Indian phone number'),
  body('shopEmail')
    .optional()
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('adminName')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Admin name must be between 2 and 50 characters'),
  body('adminEmail')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid admin email'),
  body('adminPassword')
    .isLength({ min: 6 })
    .withMessage('Admin password must be at least 6 characters long'),
  body('adminPhone')
    .optional()
    .isMobilePhone('en-IN')
    .withMessage('Please provide a valid Indian phone number'),
  handleValidationErrors
];

// Parameter validations
export const validateId = [
  param('id')
    .isInt({ min: 1 })
    .withMessage('ID must be a positive integer'),
  handleValidationErrors
];

// Query validations
export const validatePagination = [
  query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Page must be a positive integer'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100'),
  handleValidationErrors
];

// Add this to your existing validation.js file
export const validateAdminRequest = [
  body('shopName')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Shop name must be between 2 and 100 characters'),
  body('adminName')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Admin name must be between 2 and 50 characters'),
  body('description')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Description must be less than 500 characters'),
  body('phone')
    .optional()
    .isMobilePhone('en-IN')
    .withMessage('Please provide a valid Indian phone number'),
  body('address')
    .optional()
    .trim()
    .isLength({ max: 200 })
    .withMessage('Address must be less than 200 characters'),
  handleValidationErrors
];
