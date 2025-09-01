import express from 'express';
import { 
  getAllProducts, 
  getMyProducts, 
  createProduct, 
  updateProduct, 
  deleteProduct, 
  getProduct 
} from '../controllers/productController.js';
import { authenticate, requireAdmin, requireCustomer } from '../middleware/auth.js';
import { checkShopOwnership } from '../middleware/admin.js';

const router = express.Router();

// Public/Customer routes
router.get('/', authenticate, requireCustomer, getAllProducts);
router.get('/:id', authenticate, getProduct);

// Admin routes
router.get('/admin/my-products', authenticate, requireAdmin, checkShopOwnership, getMyProducts);
router.post('/', authenticate, requireAdmin, checkShopOwnership, createProduct);
router.put('/:id', authenticate, requireAdmin, checkShopOwnership, updateProduct);
router.delete('/:id', authenticate, requireAdmin, checkShopOwnership, deleteProduct);

export default router;
