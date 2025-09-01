import prisma from '../utils/prisma.js';
import { logAdminActivity } from '../middleware/admin.js';

// Get all products (for customers - only visible shops)
export const getAllProducts = async (req, res) => {
  try {
    const { page = 1, limit = 10, category, shop, search } = req.query;
    const skip = (page - 1) * limit;

    const where = {
      isActive: true,
      shop: {
        isVisible: true,
        isActive: true
      }
    };

    if (category) {
      where.categoryId = parseInt(category);
    }

    if (shop) {
      where.shopId = parseInt(shop);
    }

    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } }
      ];
    }

    const products = await prisma.product.findMany({
      where,
      include: {
        category: true,
        shop: {
          select: { id: true, name: true }
        },
        reviews: {
          select: { rating: true }
        }
      },
      skip: parseInt(skip),
      take: parseInt(limit),
      orderBy: { createdAt: 'desc' }
    });

    const total = await prisma.product.count({ where });

    res.json({
      products,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch products', details: error.message });
  }
};

// Get products for admin (only their shop)
export const getMyProducts = async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const skip = (page - 1) * limit;

    const where = {
      shopId: req.userShop.id
    };

    const products = await prisma.product.findMany({
      where,
      include: {
        category: true,
        reviews: {
          select: { rating: true }
        }
      },
      skip: parseInt(skip),
      take: parseInt(limit),
      orderBy: { createdAt: 'desc' }
    });

    const total = await prisma.product.count({ where });

    res.json({
      products,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch products', details: error.message });
  }
};

// Create product (admin only)
export const createProduct = async (req, res) => {
  try {
    const { name, description, price, stock, categoryId, imageUrl } = req.body;

    // Verify category belongs to admin's shop
    const category = await prisma.category.findFirst({
      where: {
        id: parseInt(categoryId),
        shopId: req.userShop.id
      }
    });

    if (!category) {
      return res.status(400).json({ error: 'Invalid category or category not in your shop' });
    }

    const product = await prisma.product.create({
      data: {
        name,
        description,
        price: parseFloat(price),
        stock: parseInt(stock),
        categoryId: parseInt(categoryId),
        shopId: req.userShop.id,
        imageUrl
      },
      include: {
        category: true,
        shop: {
          select: { id: true, name: true }
        }
      }
    });

    // Log activity
    await logAdminActivity(
      req.user.id,
      'CREATED_PRODUCT',
      `Created product: ${name}`,
      product.id,
      'product'
    );

    res.status(201).json({
      message: 'Product created successfully',
      product
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to create product', details: error.message });
  }
};

// Update product (admin only)
export const updateProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, price, stock, categoryId, imageUrl, isActive } = req.body;

    // Check if product belongs to admin's shop
    const existingProduct = await prisma.product.findFirst({
      where: {
        id: parseInt(id),
        shopId: req.userShop.id
      }
    });

    if (!existingProduct) {
      return res.status(404).json({ error: 'Product not found or access denied' });
    }

    // If categoryId is provided, verify it belongs to admin's shop
    if (categoryId) {
      const category = await prisma.category.findFirst({
        where: {
          id: parseInt(categoryId),
          shopId: req.userShop.id
        }
      });

      if (!category) {
        return res.status(400).json({ error: 'Invalid category or category not in your shop' });
      }
    }

    const product = await prisma.product.update({
      where: { id: parseInt(id) },
      data: {
        ...(name && { name }),
        ...(description && { description }),
        ...(price && { price: parseFloat(price) }),
        ...(stock !== undefined && { stock: parseInt(stock) }),
        ...(categoryId && { categoryId: parseInt(categoryId) }),
        ...(imageUrl && { imageUrl }),
        ...(isActive !== undefined && { isActive })
      },
      include: {
        category: true,
        shop: {
          select: { id: true, name: true }
        }
      }
    });

    // Log activity
    await logAdminActivity(
      req.user.id,
      'UPDATED_PRODUCT',
      `Updated product: ${product.name}`,
      product.id,
      'product'
    );

    res.json({
      message: 'Product updated successfully',
      product
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update product', details: error.message });
  }
};

// Delete product (admin only)
export const deleteProduct = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if product belongs to admin's shop
    const existingProduct = await prisma.product.findFirst({
      where: {
        id: parseInt(id),
        shopId: req.userShop.id
      }
    });

    if (!existingProduct) {
      return res.status(404).json({ error: 'Product not found or access denied' });
    }

    await prisma.product.delete({
      where: { id: parseInt(id) }
    });

    // Log activity
    await logAdminActivity(
      req.user.id,
      'DELETED_PRODUCT',
      `Deleted product: ${existingProduct.name}`,
      parseInt(id),
      'product'
    );

    res.json({ message: 'Product deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete product', details: error.message });
  }
};

// Get single product
export const getProduct = async (req, res) => {
  try {
    const { id } = req.params;

    const product = await prisma.product.findUnique({
      where: { id: parseInt(id) },
      include: {
        category: true,
        shop: {
          select: { id: true, name: true, isVisible: true }
        },
        reviews: {
          include: {
            user: {
              select: { id: true, name: true }
            }
          }
        }
      }
    });

    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }

    // Check if customer can access this product
    if (req.user.role === 'customer' && (!product.shop.isVisible || !product.isActive)) {
      return res.status(404).json({ error: 'Product not found' });
    }

    res.json({ product });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch product', details: error.message });
  }
};
