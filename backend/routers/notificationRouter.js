const router = require('express').Router();
const c = require('../controllers/notificationController');
const { identifier, requireRegisteredUser } = require('../middlewares/identification');

// Notifications belong to registered users only; guests get a clean 403.
router.use(identifier, requireRegisteredUser);

router.get('/', c.getNotifications);
router.get('/unread-count', c.getUnreadCount);
// '/read-all' is declared before '/:id/read' so it can never be mistaken for an id.
router.patch('/read-all', c.markAllRead);
router.patch('/:id/read', c.markRead);

module.exports = router;
