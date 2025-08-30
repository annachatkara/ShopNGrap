const express = require('express');
const otpController = require('../controllers/otp');

const router = express.Router();

router.post('/send', otpController.sendOtp);
router.post('/verify', otpController.verifyOtp);

module.exports = router;
