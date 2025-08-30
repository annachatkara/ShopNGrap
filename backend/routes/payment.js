const express = require('express');
const paymentController = require('../controllers/payment');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

router.post('/', verifyToken, paymentController.createPayment);
router.get('/order/:orderId', verifyToken, paymentController.getPaymentByOrder);

module.exports = router;
