const router=require('express').Router(); const c=require('../controllers/authController'); const {identifier}=require('../middlewares/identification');
router.post('/',c.signup); router.post('/signin',c.signin); router.post('/signout',identifier,c.signout); router.get('/me',identifier,c.me); router.put('/me',identifier,c.updateProfile); module.exports=router;
