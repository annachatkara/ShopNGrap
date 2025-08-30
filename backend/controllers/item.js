const { prisma } = require('../config/database');
const { catchAsync, AppError } = require('../middleware/errorHandler');

class ItemController {
  createItem = catchAsync(async (req, res) => {
    const { name, description, price, quantity, shopId, imageUrl } = req.body;

    const item = await prisma.item.create({
      data: { name, description, price, quantity, shopId, imageUrl },
    });

    res.status(201).json({ success: true, item });
  });

  getItemsByShop = catchAsync(async (req, res) => {
    const shopId = req.params.shopId;
    const items = await prisma.item.findMany({ where: { shopId, isActive: true } });
    res.json({ success: true, items });
  });

  getItemById = catchAsync(async (req, res) => {
    const item = await prisma.item.findUnique({ where: { id: req.params.id } });
    if (!item) throw new AppError('Item not found', 404);
    res.json({ success: true, item });
  });
}

module.exports = new ItemController();
