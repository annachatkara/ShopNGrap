import express from 'express';
import paymentController from '../controllers/payment.js';
import { verifyToken } from '../middleware/auth.js';

const router = express.Router();

router.post('/', verifyToken, paymentController.createPayment);
router.get('/order/:orderId', verifyToken, paymentController.getPaymentByOrder);

export default router;
