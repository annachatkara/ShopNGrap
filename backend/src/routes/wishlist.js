import express from 'express';
import {
  getWishlist,
  addToWishlist,
  removeFromWishlist,
  removeFromWishlistByProduct,
  clearWishlist,
  moveToCart
} from '../controllers/wishlistController.js';
import { authenticate, requireCustomer } from '../middleware/auth.js';

const router = express.Router();

router.get('/', authenticate, requireCustomer, getWishlist);
router.post('/', authenticate, requireCustomer, addToWishlist);
router.delete('/:id', authenticate, requireCustomer, removeFromWishlist);
router.delete('/product/:productId', authenticate, requireCustomer, removeFromWishlistByProduct);
router.delete('/', authenticate, requireCustomer, clearWishlist);
router.post('/:id/move-to-cart', authenticate, requireCustomer, moveToCart);

export default router;
