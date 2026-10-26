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

  // BC Ways campus-graph node ids, kept so a past route can be reopened exactly.
  originNodeId: String,
  destinationNodeId: String,

  // Set when a navigation session finishes (completed or cancelled).
  endedAt: Date,

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

// History queries: newest routes first, per owner.
routeSchema.index({ userId: 1, createdAt: -1 });
routeSchema.index({ guestId: 1, createdAt: -1 });

// Guest routes expire with the guest session retention window (see guestModel).
const guestRetentionSeconds = Number(process.env.GUEST_RETENTION_DAYS || 7) * 24 * 60 * 60;
routeSchema.index(
  { createdAt: 1 },
  {
    expireAfterSeconds: guestRetentionSeconds,
    partialFilterExpression: { guestId: { $exists: true } }
  }
);

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
