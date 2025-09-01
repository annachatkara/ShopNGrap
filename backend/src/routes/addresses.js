import express from 'express';
import {
  getAddresses,
  createAddress,
  updateAddress,
  deleteAddress,
  setDefaultAddress
} from '../controllers/addressController.js';
import { authenticate, requireCustomer } from '../middleware/auth.js';

const router = express.Router();

router.get('/', authenticate, requireCustomer, getAddresses);
router.post('/', authenticate, requireCustomer, createAddress);
router.put('/:id', authenticate, requireCustomer, updateAddress);
router.delete('/:id', authenticate, requireCustomer, deleteAddress);
router.put('/:id/default', authenticate, requireCustomer, setDefaultAddress);

export default router;
