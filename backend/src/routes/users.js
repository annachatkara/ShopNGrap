import express from 'express';
import {
  getProfile,
  updateProfile,
  changePassword,
  getUserStats
} from '../controllers/userController.js';
import { authenticate, requireCustomer } from '../middleware/auth.js';

const router = express.Router();

router.get('/profile', authenticate, requireCustomer, getProfile);
router.put('/profile', authenticate, requireCustomer, updateProfile);
router.put('/change-password', authenticate, requireCustomer, changePassword);
router.get('/stats', authenticate, requireCustomer, getUserStats);

export default router;
