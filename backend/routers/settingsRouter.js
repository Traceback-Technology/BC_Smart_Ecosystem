const router=require('express').Router(),c=require('../controllers/settingsController'),{identifier}=require('../middlewares/identification');
router.use(identifier);router.get('/',c.getSettings);router.patch('/',c.updateSettings);router.get('/addresses',c.getAddresses);router.post('/addresses',c.addAddress);router.delete('/addresses/:id',c.deleteAddress);module.exports=router;
