/**
 * Map authorization middleware.
 *
 * Map/navigation features can be used by both registered users and guests.
 * The authentication middleware must run first so req.user is available.
 */

exports.requireMapAccess = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({
      success: false,
      message: 'Authentication required'
    });
  }

  const hasRegisteredUser = Boolean(req.user.userId);
  const hasGuest = Boolean(req.user.guestId) && req.user.role === 'guest';

  if (!hasRegisteredUser && !hasGuest) {
    return res.status(403).json({
      success: false,
      message: 'Map access is not available for this identity'
    });
  }

  next();
};
