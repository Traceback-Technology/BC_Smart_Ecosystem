/**
 * JWT token helpers.
 *
 * This file has one responsibility:
 * create authentication tokens for registered users and guests.
 *
 * Both token types use the same TOKEN_SECRET so the authentication
 * middleware can validate either type without keeping server-side sessions.
 */

const jwt = require('jsonwebtoken');

function getTokenSecret() {
  const secret = process.env.TOKEN_SECRET;

  if (!secret) {
    throw new Error('TOKEN_SECRET is not configured.');
  }

  return secret;
}

function makeUserToken(user) {
  return jwt.sign(
    {
      userId: user._id.toString(),
      email: user.email,
      role: user.role
    },
    getTokenSecret(),
    {
      expiresIn: process.env.JWT_EXPIRES_IN || '8h'
    }
  );
}

function makeGuestToken(guest) {
  return jwt.sign(
    {
      guestId: guest._id.toString(),
      role: 'guest'
    },
    getTokenSecret(),
    {
      expiresIn: process.env.JWT_GUEST_EXPIRES_IN || '7d'
    }
  );
}

module.exports = {
  makeUserToken,
  makeGuestToken
};
