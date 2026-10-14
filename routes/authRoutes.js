const router = require('express').Router();
const auth = require('../controllers/authController');
const { authenticate, requireRoleFromDb } = require('../middleware/auth');

router.post('/users', auth.register);
router.post('/users/signin', auth.signin);
router.post('/users/signout', auth.signout);
router.post('/guest/session', auth.guestSession);

// Test endpoints: prove identity and role can be read from a session
router.get('/session/me', authenticate, (req, res) => res.json({ auth: req.auth }));
router.get('/session/admin-check', authenticate, requireRoleFromDb('admin'),
  (req, res) => res.json({ ok: true }));

module.exports = router;