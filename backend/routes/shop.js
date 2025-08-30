const express = require('express');
const shopController = require('../controllers/shop');
const { verifyToken, restrictTo } = require('../middleware/auth');

const router = express.Router();

router.get('/', shopController.getShops);
router.get('/:id', shopController.getShopById);
router.post('/', verifyToken, restrictTo('SELLER'), shopController.createShop);

module.exports = router;
