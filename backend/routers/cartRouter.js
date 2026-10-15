const router=require('express').Router(),c=require('../controllers/cartController'),{identifier}=require('../middlewares/identification');
router.use(identifier);router.get('/',c.getCart);router.post('/items',c.addItem);router.patch('/items/:itemId',c.updateItem);router.delete('/items/:itemId',c.removeItem);router.delete('/',c.clearCart);module.exports=router;
