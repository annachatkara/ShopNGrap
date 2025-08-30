const express = require('express');
const itemController = require('../controllers/item');
const { verifyToken, restrictTo } = require('../middleware/auth');

const router = express.Router();

router.get('/shop/:shopId', itemController.getItemsByShop);
router.get('/:id', itemController.getItemById);
router.post('/', verifyToken, restrictTo('SELLER'), itemController.createItem);

module.exports = router;
