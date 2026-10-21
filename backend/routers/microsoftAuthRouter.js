const router=require('express').Router(),verifyMicrosoftUser=require('../middlewares/microsoftAuth'),c=require('../controllers/authController');
router.post('/login',verifyMicrosoftUser,c.loginWithMicrosoft);
router.get('/profile',verifyMicrosoftUser,(req,res)=>res.json({success:true,profile:req.microsoftUser}));
module.exports=router;
