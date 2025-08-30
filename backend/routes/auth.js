// Authentication routes
// ...define authentication routes here...
const express = require('express');
const authController = require('../controllers/auth');
const { validationRules } = require('../middleware/validation');
const { verifyToken} = require('../middleware/auth');
const { rateLimiters } = require('../middleware/security');
const router = express.Router();

// Public routes (with rate limiting for security)
router.post('/register', 
  rateLimiters.auth, 
  validationRules.register, 
  authController.register
);

router.post('/login', 
  rateLimiters.auth, 
  validationRules.login, 
  authController.login
);

router.post('/refresh-token', 
  rateLimiters.auth, 
  authController.refreshToken
);

router.post('/forgot-password', 
  rateLimiters.auth, 
  validationRules.resetPassword, 
  authController.requestPasswordReset
);

router.post('/reset-password', 
  rateLimiters.auth, 
  validationRules.changePassword, 
  authController.resetPassword
);

// Protected routes (require authentication)
router.use(verifyToken); // Apply to all routes below

router.post('/logout', authController.logout);
router.get('/profile', authController.getProfile);
router.post('/change-password', 
  validationRules.changePassword, 
  authController.changePassword
);

module.exports = router;
