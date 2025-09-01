import express from 'express';
import {
  createOrder,
  getUserOrders,
  getOrder,
  cancelOrder,
  getShopOrders,
  updateOrderStatus
} from '../controllers/orderController.js';
import { authenticate, requireCustomer, requireAdmin } from '../middleware/auth.js';
import { checkShopOwnership } from '../middleware/admin.js';

const router = express.Router();

// Customer routes
router.post('/', authenticate, requireCustomer, createOrder);
router.get('/', authenticate, requireCustomer, getUserOrders);
router.get('/:id', authenticate, requireCustomer, getOrder);
router.put('/:id/cancel', authenticate, requireCustomer, cancelOrder);

// Admin routes
router.get('/admin/shop-orders', authenticate, requireAdmin, checkShopOwnership, getShopOrders);
router.put('/admin/:id/status', authenticate, requireAdmin, checkShopOwnership, updateOrderStatus);

export default router;
