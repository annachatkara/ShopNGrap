import express from 'express';
import {
  getActiveCoupons,
  validateCoupon,
  getAllCoupons,
  createCoupon,
  updateCoupon,
  deleteCoupon
} from '../controllers/couponController.js';
import { authenticate, requireCustomer, requireSuperuser } from '../middleware/auth.js';

const router = express.Router();

// Customer routes
router.get('/active', authenticate, requireCustomer, getActiveCoupons);
router.post('/validate', authenticate, requireCustomer, validateCoupon);

// Superuser routes
router.get('/', authenticate, requireSuperuser, getAllCoupons);
router.post('/', authenticate, requireSuperuser, createCoupon);
router.put('/:id', authenticate, requireSuperuser, updateCoupon);
router.delete('/:id', authenticate, requireSuperuser, deleteCoupon);

export default router;
