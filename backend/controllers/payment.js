const { prisma } = require('../config/database');
const { catchAsync, AppError } = require('../middleware/errorHandler');

class PaymentController {
  createPayment = catchAsync(async (req, res) => {
    const { orderId, amount, status, provider, transactionId, receiptUrl } = req.body;

    const existingPayment = await prisma.payment.findUnique({ where: { orderId } });
    if (existingPayment) throw new AppError('Payment for this order already exists', 409);

    const payment = await prisma.payment.create({
      data: {
        orderId,
        amount,
        status,
        provider,
        transactionId,
        receiptUrl,
      },
    });

    res.status(201).json({ success: true, payment });
  });

  getPaymentByOrder = catchAsync(async (req, res) => {
    const { orderId } = req.params;
    const payment = await prisma.payment.findUnique({ where: { orderId } });
    if (!payment) throw new AppError('Payment not found', 404);
    res.json({ success: true, payment });
  });
}

module.exports = new PaymentController();
