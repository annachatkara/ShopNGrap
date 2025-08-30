const express = require('express');
const orderController = require('../controllers/order');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

router.post('/', verifyToken, orderController.createOrder);
router.get('/my-orders', verifyToken, orderController.getOrdersByUser);

module.exports = router;
