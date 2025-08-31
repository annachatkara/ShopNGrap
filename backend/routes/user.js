import express from 'express';
import userController from '../controllers/user.js';
import { verifyToken } from '../middleware/auth.js';

const router = express.Router();

router.post('/register', userController.register);
router.post('/login', userController.login);
router.get('/profile', verifyToken, userController.getProfile);
router.patch('/profile', verifyToken, userController.updateProfile);

export default router;
