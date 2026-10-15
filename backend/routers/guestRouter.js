/**
 * Guest routes.
 *
 * POST /api/guests/session creates a new anonymous guest session.
 * GET /api/guests/session reads the identity from an authenticated guest JWT.
 */

const router = require('express').Router();
const controller = require('../controllers/guestController');
const { identifier, requireGuest } = require('../middlewares/identification');

router.post('/session', controller.createSession);
router.get('/session', identifier, requireGuest, controller.getSession);

module.exports = router;
