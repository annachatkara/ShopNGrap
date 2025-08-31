import express from 'express';
import orderController from '../controllers/order.js';
import { verifyToken } from '../middleware/auth.js';

const router = express.Router();

router.post('/', verifyToken, orderController.createOrder);
router.get('/my-orders', verifyToken, orderController.getOrdersByUser);

export default router;
