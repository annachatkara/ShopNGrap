import express from 'express';
import itemController from '../controllers/item.js';
import { verifyToken, restrictTo } from '../middleware/auth.js';

const router = express.Router();

router.get('/shop/:shopId', itemController.getItemsByShop);
router.get('/:id', itemController.getItemById);
router.post('/', verifyToken, restrictTo('SELLER'), itemController.createItem);

export default router;
