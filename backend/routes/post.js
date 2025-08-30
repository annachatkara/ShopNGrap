// Post routes
// ...define post routes here...
const express = require('express');
const postController = require('../controllers/post');
const { validationRules } = require('../middleware/validation');
const { verifyToken, optionalAuth, checkOwnership } = require('../middleware/auth');

const router = express.Router();

// Public routes
router.get('/', optionalAuth, validationRules.pagination, postController.getPosts);
router.get('/:id', optionalAuth, validationRules.getById, postController.getPostById);
router.get('/user/:userId', optionalAuth, validationRules.getById, postController.getUserPosts);

// Protected routes
router.use(verifyToken);

router.post('/', validationRules.createPost, postController.createPost);

router.patch('/:id', 
  validationRules.getById,
  checkOwnership('post', 'id', 'authorId'),
  validationRules.updatePost, 
  postController.updatePost
);

router.delete('/:id', 
  validationRules.getById,
  checkOwnership('post', 'id', 'authorId'),
  postController.deletePost
);

router.post('/:id/like', 
  validationRules.getById, 
  postController.toggleLike
);

router.patch('/:id/pin', 
  validationRules.getById,
  checkOwnership('post', 'id', 'authorId'),
  postController.togglePin
);

module.exports = router;
