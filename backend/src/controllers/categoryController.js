import prisma from '../utils/prisma.js';
import { logAdminActivity } from '../middleware/admin.js';

// Get categories for customers (from visible shops)
export const getAllCategories = async (req, res) => {
  try {
    const categories = await prisma.category.findMany({
      where: {
        shop: {
          isVisible: true,
          isActive: true
        }
      },
      include: {
        shop: {
          select: { id: true, name: true }
        },
        _count: {
          select: { products: true }
        }
      },
      orderBy: { name: 'asc' }
    });

    res.json({ categories });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch categories', details: error.message });
  }
};

// Get categories for admin (only their shop)
export const getMyCategories = async (req, res) => {
  try {
    const categories = await prisma.category.findMany({
      where: {
        shopId: req.userShop.id
      },
      include: {
        _count: {
          select: { products: true }
        }
      },
      orderBy: { name: 'asc' }
    });

    res.json({ categories });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch categories', details: error.message });
  }
};

// Create category (admin only)
export const createCategory = async (req, res) => {
  try {
    const { name, description } = req.body;

    const category = await prisma.category.create({
      data: {
        name,
        description,
        shopId: req.userShop.id
      },
      include: {
        shop: {
          select: { id: true, name: true }
        }
      }
    });

    // Log activity
    await logAdminActivity(
      req.user.id,
      'CREATED_CATEGORY',
      `Created category: ${name}`,
      category.id,
      'category'
    );

    res.status(201).json({
      message: 'Category created successfully',
      category
    });
  } catch (error) {
    if (error.code === 'P2002') {
      return res.status(400).json({ error: 'Category name already exists in your shop' });
    }
    res.status(500).json({ error: 'Failed to create category', details: error.message });
  }
};

// Update category (admin only)
export const updateCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description } = req.body;

    // Check if category belongs to admin's shop
    const existingCategory = await prisma.category.findFirst({
      where: {
        id: parseInt(id),
        shopId: req.userShop.id
      }
    });

    if (!existingCategory) {
      return res.status(404).json({ error: 'Category not found or access denied' });
    }

    const category = await prisma.category.update({
      where: { id: parseInt(id) },
      data: {
        ...(name && { name }),
        ...(description && { description })
      }
    });

    // Log activity
    await logAdminActivity(
      req.user.id,
      'UPDATED_CATEGORY',
      `Updated category: ${category.name}`,
      category.id,
      'category'
    );

    res.json({
      message: 'Category updated successfully',
      category
    });
  } catch (error) {
    if (error.code === 'P2002') {
      return res.status(400).json({ error: 'Category name already exists in your shop' });
    }
    res.status(500).json({ error: 'Failed to update category', details: error.message });
  }
};

// Delete category (admin only)
export const deleteCategory = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if category belongs to admin's shop
    const existingCategory = await prisma.category.findFirst({
      where: {
        id: parseInt(id),
        shopId: req.userShop.id
      }
    });

    if (!existingCategory) {
      return res.status(404).json({ error: 'Category not found or access denied' });
    }

    // Check if category has products
    const productCount = await prisma.product.count({
      where: { categoryId: parseInt(id) }
    });

    if (productCount > 0) {
      return res.status(400).json({ 
        error: 'Cannot delete category with existing products',
        productCount 
      });
    }

    await prisma.category.delete({
      where: { id: parseInt(id) }
    });

    // Log activity
    await logAdminActivity(
      req.user.id,
      'DELETED_CATEGORY',
      `Deleted category: ${existingCategory.name}`,
      parseInt(id),
      'category'
    );

    res.json({ message: 'Category deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete category', details: error.message });
  }
};
