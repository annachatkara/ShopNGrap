import express from 'express';
import {
  getProductReviews,
  createReview,
  updateReview,
  deleteReview,
  getUserReviews
} from '../controllers/reviewController.js';
import { authenticate, requireCustomer } from '../middleware/auth.js';

const router = express.Router();

router.get('/product/:productId', authenticate, getProductReviews);
router.get('/my-reviews', authenticate, requireCustomer, getUserReviews);
router.post('/', authenticate, requireCustomer, createReview);
router.put('/:id', authenticate, requireCustomer, updateReview);
router.delete('/:id', authenticate, requireCustomer, deleteReview);

export default router;
