/**
 * Navigation route model.
 *
 * A route can belong to either a registered user or a guest.
 * Exactly one owner is expected:
 * - userId for a registered user
 * - guestId for a guest session
 */

const mongoose = require('mongoose');

const routeSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    index: true
  },

  guestId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Guest',
    index: true
  },

  droneId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Drone'
  },

  orderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Order'
  },

  pickupLocation: {
    address: String,
    latitude: Number,
    longitude: Number
  },

  destinationLocation: {
    address: String,
    latitude: Number,
    longitude: Number
  },

  origin: String,
  destination: String,

  estimatedMinutes: {
    type: Number,
    required: true
  },

  distanceKm: {
    type: Number,
    required: true
  },

  coordinates: [{
    latitude: Number,
    longitude: Number
  }],

  status: {
    type: String,
    enum: ['preview', 'active', 'completed', 'cancelled'],
    default: 'preview'
  }
}, { timestamps: true });

// A route must belong to a registered user or a guest, never neither.
routeSchema.pre('validate', function validateOwner(next) {
  const hasUser = Boolean(this.userId);
  const hasGuest = Boolean(this.guestId);

  if (hasUser === hasGuest) {
    return next(new Error('A route must belong to exactly one user or guest.'));
  }

  next();
});

module.exports = mongoose.model('Route', routeSchema);
