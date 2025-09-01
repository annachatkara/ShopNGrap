import prisma from '../utils/prisma.js';
import { logAdminActivity } from '../middleware/admin.js';
import bcrypt from 'bcrypt';

// SUPERUSER ONLY ENDPOINTS

// Get all users (superuser only)
export const getAllUsers = async (req, res) => {
  try {
    const { page = 1, limit = 10, role, status } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (role) where.role = role;
    if (status === 'active') where.isActive = true;
    if (status === 'blocked') where.isBlocked = true;

    const users = await prisma.user.findMany({
      where,
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        isActive: true,
        isBlocked: true,
        createdAt: true,
        shop: {
          select: { id: true, name: true }
        }
      },
      skip: parseInt(skip),
      take: parseInt(limit),
      orderBy: { createdAt: 'desc' }
    });

    const total = await prisma.user.count({ where });

    res.json({
      users,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch users', details: error.message });
  }
};

// Create shop with admin (superuser only)
export const createShop = async (req, res) => {
  try {
    const { 
      shopName, 
      shopDescription, 
      shopAddress, 
      shopPhone, 
      shopEmail,
      adminName, 
      adminEmail, 
      adminPassword, 
      adminPhone 
    } = req.body;

    // Check if admin email already exists
    const existingUser = await prisma.user.findUnique({
      where: { email: adminEmail }
    });

    if (existingUser) {
      return res.status(400).json({ error: 'Admin email already exists' });
    }

    // Hash admin password
    const passwordHash = await bcrypt.hash(adminPassword, 10);

    // Create shop with admin
    const shop = await prisma.shop.create({
      data: {
        name: shopName,
        description: shopDescription,
        address: shopAddress,
        phone: shopPhone,
        email: shopEmail,
        admin: {
          create: {
            name: adminName,
            email: adminEmail,
            passwordHash,
            phone: adminPhone,
            role: 'admin'
          }
        }
      },
      include: {
        admin: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            role: true
          }
        }
      }
    });

    // Log activity
    await logAdminActivity(
      req.user.id,
      'CREATED_SHOP',
      `Created shop: ${shopName} with admin: ${adminEmail}`,
      shop.id,
      'shop'
    );

    res.status(201).json({
      message: 'Shop and admin created successfully',
      shop
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to create shop', details: error.message });
  }
};

// Get all shops (superuser only)
export const getAllShops = async (req, res) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (status === 'active') where.isActive = true;
    if (status === 'visible') where.isVisible = true;

    const shops = await prisma.shop.findMany({
      where,
      include: {
        admin: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            isActive: true,
            isBlocked: true
          }
        },
        _count: {
          select: {
            products: true,
            categories: true
          }
        }
      },
      skip: parseInt(skip),
      take: parseInt(limit),
      orderBy: { createdAt: 'desc' }
    });

    const total = await prisma.shop.count({ where });

    res.json({
      shops,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch shops', details: error.message });
  }
};

// Update shop visibility (superuser only)
export const updateShopVisibility = async (req, res) => {
  try {
    const { id } = req.params;
    const { isVisible, isActive } = req.body;

    const shop = await prisma.shop.update({
      where: { id: parseInt(id) },
      data: {
        ...(isVisible !== undefined && { isVisible }),
        ...(isActive !== undefined && { isActive })
      },
      include: {
        admin: {
          select: { name: true, email: true }
        }
      }
    });

    // Log activity
    await logAdminActivity(
      req.user.id,
      'UPDATED_SHOP_VISIBILITY',
      `Updated shop ${shop.name}: visible=${shop.isVisible}, active=${shop.isActive}`,
      shop.id,
      'shop'
    );

    res.json({
      message: 'Shop updated successfully',
      shop
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update shop', details: error.message });
  }
};

// Block/Unblock user (superuser only)
export const toggleUserBlock = async (req, res) => {
  try {
    const { id } = req.params;
    const { isBlocked } = req.body;

    const user = await prisma.user.update({
      where: { id: parseInt(id) },
      data: { 
        isBlocked,
        ...(isBlocked && { blockedById: req.user.id })
      },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        isBlocked: true
      }
    });

    // Log activity
    await logAdminActivity(
      req.user.id,
      isBlocked ? 'BLOCKED_USER' : 'UNBLOCKED_USER',
      `${isBlocked ? 'Blocked' : 'Unblocked'} user: ${user.email}`,
      user.id,
      'user'
    );

    res.json({
      message: `User ${isBlocked ? 'blocked' : 'unblocked'} successfully`,
      user
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update user status', details: error.message });
  }
};

// Get admin logs
export const getAdminLogs = async (req, res) => {
  try {
    const { page = 1, limit = 20, adminId, action } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (adminId) where.adminId = parseInt(adminId);
    if (action) where.action = { contains: action, mode: 'insensitive' };

    const logs = await prisma.adminLog.findMany({
      where,
      include: {
        admin: {
          select: { name: true, email: true, role: true }
        }
      },
      skip: parseInt(skip),
      take: parseInt(limit),
      orderBy: { createdAt: 'desc' }
    });

    const total = await prisma.adminLog.count({ where });

    res.json({
      logs,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch admin logs', details: error.message });
  }
};

// ADMIN ENDPOINTS

// Get shop dashboard data
export const getShopDashboard = async (req, res) => {
  try {
    const shopId = req.userShop.id;

    const [
      totalProducts,
      totalCategories,
      totalOrders,
      recentOrders
    ] = await Promise.all([
      prisma.product.count({ where: { shopId } }),
      prisma.category.count({ where: { shopId } }),
      prisma.orderItem.count({
        where: { product: { shopId } }
      }),
      prisma.orderItem.findMany({
        where: { product: { shopId } },
        include: {
          order: {
            include: {
              user: {
                select: { name: true, email: true }
              }
            }
          },
          product: {
            select: { name: true, price: true }
          }
        },
        orderBy: { order: { createdAt: 'desc' } },
        take: 10
      })
    ]);

    res.json({
      dashboard: {
        totalProducts,
        totalCategories,
        totalOrders,
        recentOrders,
        shop: req.userShop
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch dashboard data', details: error.message });
  }
};
