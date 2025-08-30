// Notification handling logic
// ...implement notification handling logic here...
const { prisma } = require('../config/database');
const { catchAsync, AppError } = require('../middleware/errorHandler');
const { logger } = require('../middleware/logger');

class NotificationController {
  // Get user's notifications
  getNotifications = catchAsync(async (req, res, next) => {
    const userId = req.user.id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const type = req.query.type || '';
    const unreadOnly = req.query.unread === 'true';
    const skip = (page - 1) * limit;

    const whereClause = {
      userId,
      ...(type && { type }),
      ...(unreadOnly && { isRead: false }),
      ...(req.query.since && { 
        createdAt: { gte: new Date(req.query.since) }
      })
    };

    const [notifications, total, unreadCount] = await Promise.all([
      prisma.notification.findMany({
        where: whereClause,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' }
      }),
      prisma.notification.count({ where: whereClause }),
      prisma.notification.count({ 
        where: { userId, isRead: false } 
      })
    ]);

    res.json({
      success: true,
      data: {
        notifications,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        },
        unreadCount
      }
    });
  });

  // Mark notification as read
  markAsRead = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const userId = req.user.id;

    const notification = await prisma.notification.findFirst({
      where: { id, userId }
    });

    if (!notification) {
      return next(new AppError('Notification not found', 404));
    }

    await prisma.notification.update({
      where: { id },
      data: { 
        isRead: true, 
        readAt: new Date() 
      }
    });

    res.json({
      success: true,
      message: 'Notification marked as read'
    });
  });

  // Mark all notifications as read
  markAllAsRead = catchAsync(async (req, res, next) => {
    const userId = req.user.id;

    await prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { 
        isRead: true, 
        readAt: new Date() 
      }
    });

    logger.info(`All notifications marked as read for user ${userId}`);

    res.json({
      success: true,
      message: 'All notifications marked as read'
    });
  });

  // Delete notification
  deleteNotification = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const userId = req.user.id;

    const notification = await prisma.notification.findFirst({
      where: { id, userId }
    });

    if (!notification) {
      return next(new AppError('Notification not found', 404));
    }

    await prisma.notification.delete({
      where: { id }
    });

    res.json({
      success: true,
      message: 'Notification deleted'
    });
  });

  // Get notification settings
  getSettings = catchAsync(async (req, res, next) => {
    const userId = req.user.id;

    const preferences = await prisma.userPreferences.findUnique({
      where: { userId },
      select: {
        emailNotifications: true,
        pushNotifications: true,
        smsNotifications: true
      }
    });

    res.json({
      success: true,
      data: { settings: preferences }
    });
  });

  // Update notification settings
  updateSettings = catchAsync(async (req, res, next) => {
    const userId = req.user.id;
    const { emailNotifications, pushNotifications, smsNotifications } = req.body;

    const updatedSettings = await prisma.userPreferences.upsert({
      where: { userId },
      update: {
        emailNotifications,
        pushNotifications,
        smsNotifications
      },
      create: {
        userId,
        emailNotifications,
        pushNotifications,
        smsNotifications
      }
    });

    res.json({
      success: true,
      message: 'Notification settings updated',
      data: { settings: updatedSettings }
    });
  });
}

module.exports = new NotificationController();
