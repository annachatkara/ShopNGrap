const { prisma } = require('../config/database');
const { catchAsync, AppError } = require('../middleware/errorHandler');

class ShopController {
  createShop = catchAsync(async (req, res) => {
    const { name, address, description, imageUrl } = req.body;
    const ownerId = req.user.id;

    const shop = await prisma.shop.create({
      data: { name, address, description, imageUrl, ownerId },
    });

    res.status(201).json({ success: true, shop });
  });

  getShops = catchAsync(async (_, res) => {
    const shops = await prisma.shop.findMany({ include: { items: true } });
    res.json({ success: true, shops });
  });

  getShopById = catchAsync(async (req, res) => {
    const shop = await prisma.shop.findUnique({
      where: { id: req.params.id },
      include: { items: true }
    });
    if (!shop) throw new AppError('Shop not found', 404);
    res.json({ success: true, shop });
  });
}

module.exports = new ShopController();
