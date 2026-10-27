const router=require('express').Router(),c=require('../controllers/paymentController'),{identifier,requireRegisteredUser}=require('../middlewares/identification');
// Stripe redirects the browser here after a sandbox 3D Secure test, so it carries no token.
router.get('/sandbox/return',c.sandboxReturn);
router.get('/config',c.getConfig);
router.use(identifier,requireRegisteredUser);router.post('/intent',c.createPaymentIntent);router.get('/',c.getPayments);router.get('/:id',c.getPayment);router.post('/:id/sync',c.syncPayment);router.post('/:id/sandbox/confirm',c.sandboxConfirm);router.post('/:id/refund',require('../middlewares/role').requireRoles('admin'),c.refundPayment);module.exports=router;
