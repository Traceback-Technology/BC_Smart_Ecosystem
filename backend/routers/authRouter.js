/**
 * Authentication routes for registered users.
 *
 * Guest sessions have their own router at /api/guests.
 */

const router = require('express').Router();
const controller = require('../controllers/authController');
const { identifier } = require('../middlewares/identification');
const verifyMicrosoftUser = require('../middlewares/microsoftAuth');

// Public Microsoft configuration used by the Flutter application.
router.get('/microsoft/config', controller.microsoftConfig);

// Traditional account authentication.
router.post('/', controller.signup);
router.post('/signin', controller.signin);

// Microsoft student authentication.
router.post(
  '/microsoft-login',
  verifyMicrosoftUser,
  controller.loginWithMicrosoft
);

// Authenticated registered-user routes.
router.post('/signout', identifier, controller.signout);
router.get('/me', identifier, controller.me);
router.put('/me', identifier, controller.updateProfile);

module.exports = router;
