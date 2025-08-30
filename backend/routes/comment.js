// Comment routes
// ...define comment routes here...
const express = require('express');
const commentController = require('../controllers/comment');
const { validationRules } = require('../middleware/validation');
const { verifyToken, checkOwnership } = require('../middleware/auth');

const router = express.Router();

// All comment routes require authentication
router.use(verifyToken);

// Comment management
router.post('/posts/:postId/comments', 
  validationRules.getById,
  validationRules.createComment, 
  commentController.createComment
);

router.get('/posts/:postId/comments', 
  validationRules.getById,
  validationRules.pagination, 
  commentController.getPostComments
);

router.get('/:commentId/replies', 
  validationRules.getById,
  validationRules.pagination, 
  commentController.getCommentReplies
);

router.patch('/:id', 
  validationRules.getById,
  checkOwnership('comment', 'id', 'authorId'),
  validationRules.createComment, 
  commentController.updateComment
);

router.delete('/:id', 
  validationRules.getById,
  checkOwnership('comment', 'id', 'authorId'),
  commentController.deleteComment
);

router.post('/:id/like', 
  validationRules.getById, 
  commentController.toggleLike
);

module.exports = router;
