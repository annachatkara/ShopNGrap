const express = require('express');
const userController = require('../controllers/user');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

router.post('/register', userController.register);
router.post('/login', userController.login);
router.get('/profile', verifyToken, userController.getProfile);
router.patch('/profile', verifyToken, userController.updateProfile);

module.exports = router;
