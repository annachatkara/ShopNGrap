import express from 'express';
import {
  getCart,
  addToCart,
  updateCartItem,
  removeFromCart,
  clearCart
} from '../controllers/cartController.js';
import { authenticate, requireCustomer } from '../middleware/auth.js';

const router = express.Router();

router.get('/', authenticate, requireCustomer, getCart);
router.post('/', authenticate, requireCustomer, addToCart);
router.put('/:id', authenticate, requireCustomer, updateCartItem);
router.delete('/:id', authenticate, requireCustomer, removeFromCart);
router.delete('/', authenticate, requireCustomer, clearCart);

export default router;
