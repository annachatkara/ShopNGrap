import bcrypt from 'bcrypt';
import prisma from '../utils/prisma.js';

// Get user profile
export const getProfile = async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        isActive: true,
        createdAt: true
      }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ user });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch profile', details: error.message });
  }
};

// Update user profile
export const updateProfile = async (req, res) => {
  try {
    const { name, phone } = req.body;

    const user = await prisma.user.update({
      where: { id: req.user.id },
      data: {
        ...(name && { name }),
        ...(phone && { phone })
      },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        updatedAt: true
      }
    });

    res.json({
      message: 'Profile updated successfully',
      user
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update profile', details: error.message });
  }
};

// Change password
export const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    // Get user with password
    const user = await prisma.user.findUnique({
      where: { id: req.user.id }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check current password
    const validPassword = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!validPassword) {
      return res.status(400).json({ error: 'Current password is incorrect' });
    }

    // Hash new password
    const newPasswordHash = await bcrypt.hash(newPassword, 10);

    // Update password
    await prisma.user.update({
      where: { id: req.user.id },
      data: { passwordHash: newPasswordHash }
    });

    res.json({ message: 'Password changed successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to change password', details: error.message });
  }
};

// Get user stats
export const getUserStats = async (req, res) => {
  try {
    const [
      totalOrders,
      totalSpent,
      totalReviews,
      wishlistCount,
      cartCount
    ] = await Promise.all([
      prisma.order.count({ where: { userId: req.user.id } }),
      prisma.order.aggregate({
        where: { 
          userId: req.user.id,
          status: { not: 'cancelled' }
        },
        _sum: { totalAmount: true }
      }),
      prisma.review.count({ where: { userId: req.user.id } }),
      prisma.wishlist.count({ where: { userId: req.user.id } }),
      prisma.cart.count({ where: { userId: req.user.id } })
    ]);

    res.json({
      stats: {
        totalOrders,
        totalSpent: totalSpent._sum.totalAmount || 0,
        totalReviews,
        wishlistCount,
        cartCount
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch user stats', details: error.message });
  }
};
