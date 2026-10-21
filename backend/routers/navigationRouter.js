/**
 * Navigation routes.
 *
 * Registered users and guests can use map/navigation endpoints.
 * The controller stores route ownership using either userId or guestId.
 */

const router = require('express').Router();
const controller = require('../controllers/navigationController');
const { identifier } = require('../middlewares/identification');
const { requireMapAccess } = require('../middlewares/mapAccess');

router.use(identifier, requireMapAccess);
router.post('/preview', controller.preview);
router.patch('/:id/start', controller.start);
router.get('/:id', controller.getRoute);

module.exports = router;
