const router=require('express').Router(),c=require('../controllers/trackingController'),{identifier}=require('../middlewares/identification');
router.use(identifier);router.get('/:orderId',c.getRoute);router.get('/:orderId/latest',c.getLatest);router.post('/:orderId/start',c.startTracking);router.patch('/:orderId/location',c.updateLocation);module.exports=router;
