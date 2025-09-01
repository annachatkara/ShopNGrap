import prisma from '../utils/prisma.js';

// Get user's cart
export const getCart = async (req, res) => {
  try {
    const cart = await prisma.cart.findMany({
      where: { userId: req.user.id },
      include: {
        product: {
          include: {
            shop: {
              select: { id: true, name: true, isVisible: true, isActive: true }
            },
            category: {
              select: { id: true, name: true }
            }
          }
        }
      }
    });

    // Filter out products from invisible shops
    const visibleCart = cart.filter(item => 
      item.product.shop.isVisible && 
      item.product.shop.isActive && 
      item.product.isActive
    );

    // Calculate totals
    const subtotal = visibleCart.reduce((sum, item) => 
      sum + (item.product.price * item.quantity), 0
    );

    res.json({
      cart: visibleCart,
      summary: {
        itemCount: visibleCart.length,
        totalQuantity: visibleCart.reduce((sum, item) => sum + item.quantity, 0),
        subtotal: subtotal.toFixed(2)
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch cart', details: error.message });
  }
};

// Add item to cart
export const addToCart = async (req, res) => {
  try {
    const { productId, quantity = 1 } = req.body;

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

    if (product.stock < quantity) {
      return res.status(400).json({ error: 'Insufficient stock' });
    }

    // Check if item already in cart
    const existingCartItem = await prisma.cart.findUnique({
      where: {
        userId_productId: {
          userId: req.user.id,
          productId: parseInt(productId)
        }
      }
    });

    let cartItem;

    if (existingCartItem) {
      // Update quantity
      const newQuantity = existingCartItem.quantity + parseInt(quantity);
      
      if (product.stock < newQuantity) {
        return res.status(400).json({ error: 'Insufficient stock' });
      }

      cartItem = await prisma.cart.update({
        where: { id: existingCartItem.id },
        data: { quantity: newQuantity },
        include: {
          product: {
            include: {
              shop: {
                select: { id: true, name: true }
              }
            }
          }
        }
      });
    } else {
      // Add new item
      cartItem = await prisma.cart.create({
        data: {
          userId: req.user.id,
          productId: parseInt(productId),
          quantity: parseInt(quantity)
        },
        include: {
          product: {
            include: {
              shop: {
                select: { id: true, name: true }
              }
            }
          }
        }
      });
    }

    res.status(201).json({
      message: 'Item added to cart successfully',
      cartItem
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to add item to cart', details: error.message });
  }
};

// Update cart item quantity
export const updateCartItem = async (req, res) => {
  try {
    const { id } = req.params;
    const { quantity } = req.body;

    if (quantity <= 0) {
      return res.status(400).json({ error: 'Quantity must be greater than 0' });
    }

    // Check if cart item belongs to user
    const cartItem = await prisma.cart.findFirst({
      where: {
        id: parseInt(id),
        userId: req.user.id
      },
      include: {
        product: true
      }
    });

    if (!cartItem) {
      return res.status(404).json({ error: 'Cart item not found' });
    }

    if (cartItem.product.stock < quantity) {
      return res.status(400).json({ error: 'Insufficient stock' });
    }

    const updatedCartItem = await prisma.cart.update({
      where: { id: parseInt(id) },
      data: { quantity: parseInt(quantity) },
      include: {
        product: {
          include: {
            shop: {
              select: { id: true, name: true }
            }
          }
        }
      }
    });

    res.json({
      message: 'Cart item updated successfully',
      cartItem: updatedCartItem
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update cart item', details: error.message });
  }
};

// Remove item from cart
export const removeFromCart = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if cart item belongs to user
    const cartItem = await prisma.cart.findFirst({
      where: {
        id: parseInt(id),
        userId: req.user.id
      }
    });

    if (!cartItem) {
      return res.status(404).json({ error: 'Cart item not found' });
    }

    await prisma.cart.delete({
      where: { id: parseInt(id) }
    });

    res.json({ message: 'Item removed from cart successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to remove item from cart', details: error.message });
  }
};

// Clear entire cart
export const clearCart = async (req, res) => {
  try {
    await prisma.cart.deleteMany({
      where: { userId: req.user.id }
    });

    res.json({ message: 'Cart cleared successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to clear cart', details: error.message });
  }
};
