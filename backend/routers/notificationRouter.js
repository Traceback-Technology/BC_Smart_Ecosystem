const router = require('express').Router();
const c = require('../controllers/notificationController');
const {identifier, requireRegisteredUser} = require('../middlewares/identification');

router.use(identifier);router.get('/',c.getNotifications);
router.get('/', c.getNotifications);
router.get('/unread-count', c.getUnreadCount);
router.patch('/:id/read',c.markRead);
router.patch('/read-all',c.markAllRead);module.exports=router;
