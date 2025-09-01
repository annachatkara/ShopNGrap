import express from 'express';
import {
  getAllUsers,
  createShop,
  getAllShops,
  updateShopVisibility,
  toggleUserBlock,
  getAdminLogs,
  getShopDashboard
} from '../controllers/adminController.js';
import { authenticate, requireSuperuser, requireAdmin } from '../middleware/auth.js';
import { checkShopOwnership } from '../middleware/admin.js';

const router = express.Router();

// Superuser only routes
router.get('/users', authenticate, requireSuperuser, getAllUsers);
router.post('/shops', authenticate, requireSuperuser, createShop);
router.get('/shops', authenticate, requireSuperuser, getAllShops);
router.put('/shops/:id/visibility', authenticate, requireSuperuser, updateShopVisibility);
router.put('/users/:id/block', authenticate, requireSuperuser, toggleUserBlock);
router.get('/logs', authenticate, requireSuperuser, getAdminLogs);

// Admin routes
router.get('/dashboard', authenticate, requireAdmin, checkShopOwnership, getShopDashboard);

export default router;
