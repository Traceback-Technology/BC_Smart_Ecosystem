const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');

// Swap this import path for wherever your team's actual auth middleware lives
const { protect } = require('../middleware/authMiddleware');

router.post('/', protect, orderController.createOrder);
router.post('/:orderId/items', protect, orderController.addItem);
router.patch('/:orderId/items/:menuItemId', protect, orderController.updateItemQuantity);
router.delete('/:orderId/items/:menuItemId', protect, orderController.removeItem);
router.post('/:orderId/finalize', protect, orderController.finalizeOrder);
router.post('/:orderId/cancel', protect, orderController.cancelOrder);

module.exports = router;
