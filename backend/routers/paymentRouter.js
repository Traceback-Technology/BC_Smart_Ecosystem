const router=require('express').Router(),c=require('../controllers/paymentController'),{identifier}=require('../middlewares/identification');
router.use(identifier);router.post('/intent',c.createPaymentIntent);router.get('/',c.getPayments);router.get('/:id',c.getPayment);router.post('/:id/refund',c.refundPayment);module.exports=router;
