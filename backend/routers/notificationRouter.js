const router=require('express').Router(),c=require('../controllers/notificationController'),{identifier}=require('../middlewares/identification');
router.use(identifier);router.get('/',c.getNotifications);router.patch('/:id/read',c.markRead);router.patch('/read-all',c.markAllRead);module.exports=router;
