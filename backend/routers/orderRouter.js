const router=require('express').Router(),c=require('../controllers/orderController'),{identifier,requireRegisteredUser}=require('../middlewares/identification'),{requireRoles}=require('../middlewares/role');
router.use(identifier,requireRegisteredUser);
router.get('/',c.getOrders);router.post('/',c.createOrder);router.get('/:id',c.getOrder);router.post('/:id/reorder',c.reorder);router.patch('/:id/notes',c.updateNotes);router.patch('/:id/cancel',c.cancelOrder);router.get('/:id/tracking',c.getTracking);router.patch('/:id/tracking',c.updateTracking);
router.patch('/:id/status',requireRoles('admin','restaurant','drone_operator'),c.updateStatus);
module.exports=router;
