import prisma from '../utils/prisma.js';
import { logAdminActivity } from '../middleware/admin.js';

// Get all active coupons (customer)
export const getActiveCoupons = async (req, res) => {
  try {
    const coupons = await prisma.coupon.findMany({
      where: {
        isActive: true,
        expiryDate: {
          gte: new Date()
        },
        OR: [
          { usageLimit: null },
          { usedCount: { lt: prisma.raw('usage_limit') } }
        ]
      },
      select: {
        id: true,
        code: true,
        discount: true,
        type: true,
        expiryDate: true,
        minOrder: true,
        maxDiscount: true
      },
      orderBy: { discount: 'desc' }
    });

    res.json({ coupons });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch coupons', details: error.message });
  }
};

// Validate coupon
export const validateCoupon = async (req, res) => {
  try {
    const { code, orderAmount } = req.body;

    const coupon = await prisma.coupon.findUnique({
      where: { code: code.toUpperCase() }
    });

    if (!coupon) {
      return res.status(404).json({ error: 'Invalid coupon code' });
    }

    if (!coupon.isActive) {
      return res.status(400).json({ error: 'Coupon is not active' });
    }

    if (new Date() > coupon.expiryDate) {
      return res.status(400).json({ error: 'Coupon has expired' });
    }

    if (coupon.minOrder > orderAmount) {
      return res.status(400).json({ 
        error: `Minimum order amount is ₹${coupon.minOrder}` 
      });
    }

    if (coupon.usageLimit && coupon.usedCount >= coupon.usageLimit) {
      return res.status(400).json({ error: 'Coupon usage limit exceeded' });
    }

    // Calculate discount
    let discount = 0;
    if (coupon.type === 'percentage') {
      discount = (orderAmount * coupon.discount) / 100;
      if (coupon.maxDiscount && discount > coupon.maxDiscount) {
        discount = coupon.maxDiscount;
      }
    } else {
      discount = coupon.discount;
    }

    res.json({
      valid: true,
      coupon: {
        id: coupon.id,
        code: coupon.code,
        discount: coupon.discount,
        type: coupon.type,
        calculatedDiscount: discount
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to validate coupon', details: error.message });
  }
};

// SUPERUSER ONLY ENDPOINTS

// Get all coupons (superuser)
export const getAllCoupons = async (req, res) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (status === 'active') where.isActive = true;
    if (status === 'expired') where.expiryDate = { lt: new Date() };

    const coupons = await prisma.coupon.findMany({
      where,
      skip: parseInt(skip),
      take: parseInt(limit),
      orderBy: { createdAt: 'desc' }
    });

    const total = await prisma.coupon.count({ where });

    res.json({
      coupons,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch coupons', details: error.message });
  }
};

// Create coupon (superuser)
export const createCoupon = async (req, res) => {
  try {
    const { 
      code, 
      discount, 
      type = 'percentage', 
      expiryDate, 
      minOrder = 0, 
      maxDiscount, 
      usageLimit 
    } = req.body;

    const coupon = await prisma.coupon.create({
      data: {
        code: code.toUpperCase(),
        discount: parseFloat(discount),
        type,
        expiryDate: new Date(expiryDate),
        minOrder: parseFloat(minOrder),
        maxDiscount: maxDiscount ? parseFloat(maxDiscount) : null,
        usageLimit: usageLimit ? parseInt(usageLimit) : null
      }
    });

    // Log activity
    await logAdminActivity(
      req.user.id,
      'CREATED_COUPON',
      `Created coupon: ${code}`,
      coupon.id,
      'coupon'
    );

    res.status(201).json({
      message: 'Coupon created successfully',
      coupon
    });
  } catch (error) {
    if (error.code === 'P2002') {
      return res.status(400).json({ error: 'Coupon code already exists' });
    }
    res.status(500).json({ error: 'Failed to create coupon', details: error.message });
  }
};

// Update coupon (superuser)
export const updateCoupon = async (req, res) => {
  try {
    const { id } = req.params;
    const { 
      code, 
      discount, 
      type, 
      expiryDate, 
      minOrder, 
      maxDiscount, 
      usageLimit, 
      isActive 
    } = req.body;

    const coupon = await prisma.coupon.update({
      where: { id: parseInt(id) },
      data: {
        ...(code && { code: code.toUpperCase() }),
        ...(discount && { discount: parseFloat(discount) }),
        ...(type && { type }),
        ...(expiryDate && { expiryDate: new Date(expiryDate) }),
        ...(minOrder !== undefined && { minOrder: parseFloat(minOrder) }),
        ...(maxDiscount !== undefined && { maxDiscount: maxDiscount ? parseFloat(maxDiscount) : null }),
        ...(usageLimit !== undefined && { usageLimit: usageLimit ? parseInt(usageLimit) : null }),
        ...(isActive !== undefined && { isActive })
      }
    });

    // Log activity
    await logAdminActivity(
      req.user.id,
      'UPDATED_COUPON',
      `Updated coupon: ${coupon.code}`,
      coupon.id,
      'coupon'
    );

    res.json({
      message: 'Coupon updated successfully',
      coupon
    });
  } catch (error) {
    if (error.code === 'P2002') {
      return res.status(400).json({ error: 'Coupon code already exists' });
    }
    res.status(500).json({ error: 'Failed to update coupon', details: error.message });
  }
};

// Delete coupon (superuser)
export const deleteCoupon = async (req, res) => {
  try {
    const { id } = req.params;

    const coupon = await prisma.coupon.findUnique({
      where: { id: parseInt(id) }
    });

    if (!coupon) {
      return res.status(404).json({ error: 'Coupon not found' });
    }

    await prisma.coupon.delete({
      where: { id: parseInt(id) }
    });

    // Log activity
    await logAdminActivity(
      req.user.id,
      'DELETED_COUPON',
      `Deleted coupon: ${coupon.code}`,
      parseInt(id),
      'coupon'
    );

    res.json({ message: 'Coupon deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete coupon', details: error.message });
  }
};

// Apply coupon to order
export const applyCoupon = async (couponId, orderAmount) => {
  try {
    const coupon = await prisma.coupon.findUnique({
      where: { id: couponId }
    });

    if (!coupon || !coupon.isActive || new Date() > coupon.expiryDate) {
      throw new Error('Invalid or expired coupon');
    }

    if (coupon.minOrder > orderAmount) {
      throw new Error(`Minimum order amount is ₹${coupon.minOrder}`);
    }

    if (coupon.usageLimit && coupon.usedCount >= coupon.usageLimit) {
      throw new Error('Coupon usage limit exceeded');
    }

    // Calculate discount
    let discount = 0;
    if (coupon.type === 'percentage') {
      discount = (orderAmount * coupon.discount) / 100;
      if (coupon.maxDiscount && discount > coupon.maxDiscount) {
        discount = coupon.maxDiscount;
      }
    } else {
      discount = coupon.discount;
    }

    // Increment usage count
    await prisma.coupon.update({
      where: { id: couponId },
      data: { usedCount: { increment: 1 } }
    });

    return discount;
  } catch (error) {
    throw error;
  }
};
