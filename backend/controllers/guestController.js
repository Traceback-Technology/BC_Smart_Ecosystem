/**
 * Guest session controller.
 *
 * This controller creates anonymous guest sessions.
 *
 * The database creates the guest _id. We do not create UUIDs, counters,
 * phone-based IDs, or any other custom identifier.
 */

const Guest = require('../models/guestModel');
const { makeGuestToken } = require('../utils/tokens');

exports.createSession = async (req, res, next) => {
  try {
    // MongoDB generates the unique _id when this document is created.
    const guest = await Guest.create({});

    // The JWT contains the same MongoDB _id as the guest identifier.
    const token = makeGuestToken(guest);

    return res.status(201).json({
      success: true,
      message: 'Guest session created',
      token,
      data: {
        guestId: guest._id
      }
    });
  } catch (error) {
    return next(error);
  }
};

exports.getSession = async (req, res) => {
  return res.json({
    success: true,
    data: {
      guestId: req.user.guestId,
      role: req.user.role
    }
  });
};
