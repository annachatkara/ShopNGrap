import express from 'express';
import {
  getAllCategories,
  getMyCategories,
  createCategory,
  updateCategory,
  deleteCategory
} from '../controllers/categoryController.js';
import { authenticate, requireCustomer, requireAdmin } from '../middleware/auth.js';
import { checkShopOwnership } from '../middleware/admin.js';

const router = express.Router();

// Public/Customer routes
router.get('/', authenticate, requireCustomer, getAllCategories);

// Admin routes
router.get('/admin/my-categories', authenticate, requireAdmin, checkShopOwnership, getMyCategories);
router.post('/', authenticate, requireAdmin, checkShopOwnership, createCategory);
router.put('/:id', authenticate, requireAdmin, checkShopOwnership, updateCategory);
router.delete('/:id', authenticate, requireAdmin, checkShopOwnership, deleteCategory);

export default router;
