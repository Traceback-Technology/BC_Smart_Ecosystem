const router=require('express').Router(),c=require('../controllers/supportController'),{identifier}=require('../middlewares/identification');
router.use(identifier);router.post('/',c.createTicket);router.get('/',c.getTickets);router.get('/:id',c.getTicket);router.post('/:id/reply',c.reply);router.post('/chat',c.chatPlaceholder);module.exports=router;
