import prisma from '../utils/prisma.js';

export const checkShopOwnership = async (req, res, next) => {
  try {
    if (req.user.role === 'superuser') {
      return next(); // Superuser can access everything
    }

    if (req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Admin access required' });
    }

    // Get admin's shop
    const shop = await prisma.shop.findUnique({
      where: { adminId: req.user.id }
    });

    if (!shop) {
      return res.status(403).json({ error: 'No shop assigned to this admin' });
    }

    req.userShop = shop;
    next();
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
};

export const logAdminActivity = async (adminId, action, details = null, targetId = null, targetType = null) => {
  try {
    await prisma.adminLog.create({
      data: {
        adminId,
        action,
        details,
        targetId,
        targetType
      }
    });
  } catch (error) {
    console.error('Failed to log admin activity:', error);
  }
};
