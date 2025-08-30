// Notification routes
// ...define notification routes here...
const express = require('express');
const notificationController = require('../controllers/notification');
const { validationRules } = require('../middleware/validation');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

// All notification routes require authentication
router.use(verifyToken);

router.get('/', 
  validationRules.pagination, 
  notificationController.getNotifications
);

router.patch('/:id/read', 
  validationRules.markAsRead, 
  notificationController.markAsRead
);

router.patch('/mark-all-read', 
  notificationController.markAllAsRead
);

router.delete('/:id', 
  validationRules.getById, 
  notificationController.deleteNotification
);

router.get('/settings', 
  notificationController.getSettings
);

router.patch('/settings', 
  notificationController.updateSettings
);

module.exports = router;
