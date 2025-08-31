import express from 'express';
import shopController from '../controllers/shop.js';
import { verifyToken, restrictTo } from '../middleware/auth.js';

const router = express.Router();

router.get('/', shopController.getShops);
router.get('/:id', shopController.getShopById);
router.post('/', verifyToken, restrictTo('SELLER'), shopController.createShop);

export default router;
