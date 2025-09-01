import prisma from '../utils/prisma.js';

// Create order from cart
export const createOrder = async (req, res) => {
  try {
    const { addressId, paymentMethod } = req.body;

    // Verify address belongs to user
    const address = await prisma.address.findFirst({
      where: {
        id: parseInt(addressId),
        userId: req.user.id
      }
    });

    if (!address) {
      return res.status(404).json({ error: 'Address not found' });
    }

    // Get cart items
    const cartItems = await prisma.cart.findMany({
      where: { userId: req.user.id },
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

    if (cartItems.length === 0) {
      return res.status(400).json({ error: 'Cart is empty' });
    }

    // Filter available products and check stock
    const availableItems = [];
    let totalAmount = 0;

    for (const item of cartItems) {
      if (item.product.shop.isVisible && 
          item.product.shop.isActive && 
          item.product.isActive &&
          item.product.stock >= item.quantity) {
        availableItems.push(item);
        totalAmount += item.product.price * item.quantity;
      }
    }

    if (availableItems.length === 0) {
      return res.status(400).json({ error: 'No available items in cart' });
    }

    // Create order with transaction
    const order = await prisma.$transaction(async (tx) => {
      // Create order
      const newOrder = await tx.order.create({
        data: {
          userId: req.user.id,
          addressId: parseInt(addressId),
          totalAmount,
          status: 'pending'
        }
      });

      // Create order items and update stock
      const orderItems = [];
      for (const item of availableItems) {
        const orderItem = await tx.orderItem.create({
          data: {
            orderId: newOrder.id,
            productId: item.productId,
            quantity: item.quantity,
            price: item.product.price
          }
        });
        orderItems.push(orderItem);

        // Update product stock
        await tx.product.update({
          where: { id: item.productId },
          data: { stock: { decrement: item.quantity } }
        });
      }

      // Create payment record
      await tx.payment.create({
        data: {
          orderId: newOrder.id,
          method: paymentMethod,
          amount: totalAmount,
          status: 'pending'
        }
      });

      // Clear cart items that were ordered
      await tx.cart.deleteMany({
        where: {
          userId: req.user.id,
          productId: { in: availableItems.map(item => item.productId) }
        }
      });

      return newOrder;
    });

    // Fetch complete order details
    const completeOrder = await prisma.order.findUnique({
      where: { id: order.id },
      include: {
        orderItems: {
          include: {
            product: {
              select: { id: true, name: true, imageUrl: true }
            }
          }
        },
        address: true,
        payments: true
      }
    });

    res.status(201).json({
      message: 'Order created successfully',
      order: completeOrder
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to create order', details: error.message });
  }
};

// Get user orders
export const getUserOrders = async (req, res) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    const skip = (page - 1) * limit;

    const where = { userId: req.user.id };
    if (status) where.status = status;

    const orders = await prisma.order.findMany({
      where,
      include: {
        orderItems: {
          include: {
            product: {
              select: { id: true, name: true, imageUrl: true }
            }
          }
        },
        address: true,
        payments: true
      },
      skip: parseInt(skip),
      take: parseInt(limit),
      orderBy: { createdAt: 'desc' }
    });

    const total = await prisma.order.count({ where });

    res.json({
      orders,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch orders', details: error.message });
  }
};

// Get single order
export const getOrder = async (req, res) => {
  try {
    const { id } = req.params;

    const order = await prisma.order.findFirst({
      where: {
        id: parseInt(id),
        userId: req.user.id
      },
      include: {
        orderItems: {
          include: {
            product: {
              include: {
                shop: {
                  select: { id: true, name: true }
                }
              }
            }
          }
        },
        address: true,
        payments: true
      }
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    res.json({ order });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch order', details: error.message });
  }
};

// Cancel order
export const cancelOrder = async (req, res) => {
  try {
    const { id } = req.params;

    const order = await prisma.order.findFirst({
      where: {
        id: parseInt(id),
        userId: req.user.id
      },
      include: {
        orderItems: true
      }
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    if (order.status !== 'pending') {
      return res.status(400).json({ error: 'Order cannot be cancelled' });
    }

    // Update order and restore stock
    await prisma.$transaction(async (tx) => {
      // Update order status
      await tx.order.update({
        where: { id: parseInt(id) },
        data: { status: 'cancelled' }
      });

      // Update payment status
      await tx.payment.updateMany({
        where: { orderId: parseInt(id) },
        data: { status: 'refunded' }
      });

      // Restore product stock
      for (const item of order.orderItems) {
        await tx.product.update({
          where: { id: item.productId },
          data: { stock: { increment: item.quantity } }
        });
      }
    });

    res.json({ message: 'Order cancelled successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to cancel order', details: error.message });
  }
};

// Get shop orders (admin only)
export const getShopOrders = async (req, res) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    const skip = (page - 1) * limit;

    const where = {
      orderItems: {
        some: {
          product: {
            shopId: req.userShop.id
          }
        }
      }
    };

    if (status) where.status = status;

    const orders = await prisma.order.findMany({
      where,
      include: {
        user: {
          select: { id: true, name: true, email: true, phone: true }
        },
        address: true,
        orderItems: {
          where: {
            product: {
              shopId: req.userShop.id
            }
          },
          include: {
            product: {
              select: { id: true, name: true, imageUrl: true }
            }
          }
        },
        payments: true
      },
      skip: parseInt(skip),
      take: parseInt(limit),
      orderBy: { createdAt: 'desc' }
    });

    const total = await prisma.order.count({ where });

    res.json({
      orders,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch shop orders', details: error.message });
  }
};

// Update order status (admin only)
export const updateOrderStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const validStatuses = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    // Check if order has items from admin's shop
    const order = await prisma.order.findFirst({
      where: {
        id: parseInt(id),
        orderItems: {
          some: {
            product: {
              shopId: req.userShop.id
            }
          }
        }
      }
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found or access denied' });
    }

    const updatedOrder = await prisma.order.update({
      where: { id: parseInt(id) },
      data: { status },
      include: {
        user: {
          select: { name: true, email: true }
        },
        orderItems: {
          where: {
            product: {
              shopId: req.userShop.id
            }
          },
          include: {
            product: {
              select: { name: true }
            }
          }
        }
      }
    });

    res.json({
      message: 'Order status updated successfully',
      order: updatedOrder
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update order status', details: error.message });
  }
};
