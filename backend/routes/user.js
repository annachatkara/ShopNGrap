// User routes
// ...define user routes here...
const express = require('express');
const userController = require('../controllers/user');
const { validationRules } = require('../middleware/validation');
const { verifyToken, optionalAuth, checkOwnership } = require('../middleware/auth');

const router = express.Router();

// Public routes
router.get('/', optionalAuth, userController.getUsers);
router.get('/:id', optionalAuth, validationRules.getById, userController.getUserById);
router.get('/:id/followers', validationRules.getById, userController.getFollowers);
router.get('/:id/following', validationRules.getById, userController.getFollowing);

// Protected routes
router.use(verifyToken);

router.patch('/profile', 
  validationRules.updateProfile, 
  userController.updateProfile
);

router.patch('/preferences', 
  userController.updatePreferences
);

router.post('/:id/follow', 
  validationRules.getById, 
  userController.followUser
);

router.delete('/:id/follow', 
  validationRules.getById, 
  userController.unfollowUser
);

router.delete('/account', 
  userController.deactivateAccount
);

module.exports = router;
