const { prisma } = require('../config/database');
const { catchAsync, AppError } = require('../middleware/errorHandler');

class OrderController {
  createOrder = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { orderItems, totalAmount, reservedUntil } = req.body; // orderItems = [{ itemId, quantity }, ...]

    if (!orderItems || orderItems.length === 0) {
      throw new AppError('At least one item must be ordered', 400);
    }

    const order = await prisma.order.create({
      data: {
        userId,
        totalAmount,
        reservedUntil: reservedUntil ? new Date(reservedUntil) : null,
        orderItems: {
          create: orderItems.map(({ itemId, quantity }) => ({ itemId, quantity })),
        },
      },
      include: { orderItems: true },
    });

    res.status(201).json({ success: true, order });
  });

  getOrdersByUser = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const orders = await prisma.order.findMany({
      where: { userId },
      include: { orderItems: true, payment: true },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, orders });
  });
}

module.exports = new OrderController();
