import prisma from '../utils/prisma.js';

// Get user wishlist
export const getWishlist = async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const skip = (page - 1) * limit;

    const wishlist = await prisma.wishlist.findMany({
      where: { userId: req.user.id },
      include: {
        product: {
          include: {
            shop: {
              select: { id: true, name: true, isVisible: true, isActive: true }
            },
            category: {
              select: { id: true, name: true }
            },
            reviews: {
              select: { rating: true }
            }
          }
        }
      },
      skip: parseInt(skip),
      take: parseInt(limit),
      orderBy: { createdAt: 'desc' }
    });

    // Filter out products from invisible shops
    const visibleWishlist = wishlist.filter(item => 
      item.product.shop.isVisible && 
      item.product.shop.isActive && 
      item.product.isActive
    );

    const total = await prisma.wishlist.count({
      where: { userId: req.user.id }
    });

    res.json({
      wishlist: visibleWishlist,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch wishlist', details: error.message });
  }
};

// Add to wishlist
export const addToWishlist = async (req, res) => {
  try {
    const { productId } = req.body;

    // Check if product exists and is available
    const product = await prisma.product.findUnique({
      where: { id: parseInt(productId) },
      include: {
        shop: {
          select: { isVisible: true, isActive: true }
        }
      }
    });

    if (!product || !product.isActive || !product.shop.isVisible || !product.shop.isActive) {
      return res.status(404).json({ error: 'Product not available' });
    }

    // Check if already in wishlist
    const existingItem = await prisma.wishlist.findUnique({
      where: {
        userId_productId: {
          userId: req.user.id,
          productId: parseInt(productId)
        }
      }
    });

    if (existingItem) {
      return res.status(400).json({ error: 'Product already in wishlist' });
    }

    const wishlistItem = await prisma.wishlist.create({
      data: {
        userId: req.user.id,
        productId: parseInt(productId)
      },
      include: {
        product: {
          include: {
            shop: {
              select: { id: true, name: true }
            },
            category: {
              select: { id: true, name: true }
            }
          }
        }
      }
    });

    res.status(201).json({
      message: 'Product added to wishlist successfully',
      wishlistItem
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to add to wishlist', details: error.message });
  }
};

// Remove from wishlist
export const removeFromWishlist = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if wishlist item belongs to user
    const wishlistItem = await prisma.wishlist.findFirst({
      where: {
        id: parseInt(id),
        userId: req.user.id
      }
    });

    if (!wishlistItem) {
      return res.status(404).json({ error: 'Wishlist item not found' });
    }

    await prisma.wishlist.delete({
      where: { id: parseInt(id) }
    });

    res.json({ message: 'Product removed from wishlist successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to remove from wishlist', details: error.message });
  }
};

// Remove by product ID
export const removeFromWishlistByProduct = async (req, res) => {
  try {
    const { productId } = req.params;

    const wishlistItem = await prisma.wishlist.findUnique({
      where: {
        userId_productId: {
          userId: req.user.id,
          productId: parseInt(productId)
        }
      }
    });

    if (!wishlistItem) {
      return res.status(404).json({ error: 'Product not in wishlist' });
    }

    await prisma.wishlist.delete({
      where: { id: wishlistItem.id }
    });

    res.json({ message: 'Product removed from wishlist successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to remove from wishlist', details: error.message });
  }
};

// Clear entire wishlist
export const clearWishlist = async (req, res) => {
  try {
    await prisma.wishlist.deleteMany({
      where: { userId: req.user.id }
    });

    res.json({ message: 'Wishlist cleared successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to clear wishlist', details: error.message });
  }
};

// Move wishlist item to cart
export const moveToCart = async (req, res) => {
  try {
    const { id } = req.params;
    const { quantity = 1 } = req.body;

    // Get wishlist item
    const wishlistItem = await prisma.wishlist.findFirst({
      where: {
        id: parseInt(id),
        userId: req.user.id
      },
      include: {
        product: {
          include: {
            shop: {
              select: { isVisible: true, isActive: true }
            }
          }
        }
      }
    });

    if (!wishlistItem) {
      return res.status(404).json({ error: 'Wishlist item not found' });
    }

    const product = wishlistItem.product;

    if (!product.isActive || !product.shop.isVisible || !product.shop.isActive) {
      return res.status(400).json({ error: 'Product not available' });
    }

    if (product.stock < quantity) {
      return res.status(400).json({ error: 'Insufficient stock' });
    }

    // Check if already in cart
    const existingCartItem = await prisma.cart.findUnique({
      where: {
        userId_productId: {
          userId: req.user.id,
          productId: product.id
        }
      }
    });

    await prisma.$transaction(async (tx) => {
      if (existingCartItem) {
        // Update cart quantity
        const newQuantity = existingCartItem.quantity + parseInt(quantity);
        
        if (product.stock < newQuantity) {
          throw new Error('Insufficient stock');
        }

        await tx.cart.update({
          where: { id: existingCartItem.id },
          data: { quantity: newQuantity }
        });
      } else {
        // Add to cart
        await tx.cart.create({
          data: {
            userId: req.user.id,
            productId: product.id,
            quantity: parseInt(quantity)
          }
        });
      }

      // Remove from wishlist
      await tx.wishlist.delete({
        where: { id: parseInt(id) }
      });
    });

    res.json({ message: 'Product moved to cart successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to move to cart', details: error.message });
  }
};
