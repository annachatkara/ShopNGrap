import express from 'express';
import {
  sendAdminRequest,
  getMyRequests,
  getAllRequests,
  approveRequest,
  rejectRequest,
  getRequestStats
} from '../controllers/adminRequestController.js';
import { authenticate, requireCustomer, requireSuperuser } from '../middleware/auth.js';
import { validateAdminRequest, validateId } from '../middleware/validation.js';

const router = express.Router();

// Customer routes
router.post('/', authenticate, requireCustomer, validateAdminRequest, sendAdminRequest);
router.get('/my-requests', authenticate, requireCustomer, getMyRequests);

// Superuser routes
router.get('/', authenticate, requireSuperuser, getAllRequests);
router.put('/:id/approve', authenticate, requireSuperuser, validateId, approveRequest);
router.put('/:id/reject', authenticate, requireSuperuser, validateId, rejectRequest);
router.get('/stats', authenticate, requireSuperuser, getRequestStats);

export default router;
