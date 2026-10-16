/**
 * Authentication middleware.
 *
 * This middleware supports both authentication types used by BC Eats:
 * - registered users: token contains userId
 * - guests: token contains guestId and role=guest
 *
 * JWT verification is stateless. The server does not create a login session
 * in memory and does not need a database lookup just to validate the token.
 */

const jwt = require('jsonwebtoken');

function getToken(req) {
  const authorizationHeader = req.headers.authorization;

  if (authorizationHeader) {
    if (!authorizationHeader.startsWith('Bearer ')) {
      return null;
    }

    return authorizationHeader.slice(7).trim();
  }

  const cookieHeader = req.cookies?.Authorization;

  if (!cookieHeader) {
    return null;
  }

  if (cookieHeader.startsWith('Bearer ')) {
    return cookieHeader.slice(7).trim();
  }

  return cookieHeader.trim();
}

function hasValidIdentity(payload) {
  const hasUserIdentity = Boolean(payload.userId);
  const hasGuestIdentity = Boolean(payload.guestId) && payload.role === 'guest';

  return hasUserIdentity || hasGuestIdentity;
}

exports.identifier = (req, res, next) => {
  const token = getToken(req);

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Authentication token required'
    });
  }

  try {
    const decoded = jwt.verify(token, process.env.TOKEN_SECRET);

    if (!hasValidIdentity(decoded)) {
      return res.status(401).json({
        success: false,
        message: 'Invalid authentication token'
      });
    }

    // Controllers can use req.user.userId for registered users or
    // req.user.guestId for guests.
    req.user = decoded;

    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired token'
    });
  }
};

exports.requireGuest = (req, res, next) => {
  if (!req.user?.guestId || req.user.role !== 'guest') {
    return res.status(403).json({
      success: false,
      message: 'Guest authentication required'
    });
  }

  next();
};

exports.requireRegisteredUser = (req, res, next) => {
  if (!req.user?.userId || req.user.role === 'guest') {
    return res.status(403).json({
      success: false,
      message: 'Registered user authentication required'
    });
  }

  next();
};
