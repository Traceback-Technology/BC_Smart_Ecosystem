/**
 * User model.
 *
 * Stores registered students, restaurant users, administrators,
 * and drone operators. Anonymous guests are stored in the Guest collection.
 */

const mongoose = require('mongoose');

// Reusable delivery address structure for a user.
const addressSchema = new mongoose.Schema({
  label: {
    type: String,
    trim: true,
    default: 'Home'
  },
  address: {
    type: String,
    required: true,
    trim: true
  },
  latitude: Number,
  longitude: Number,
  isDefault: {
    type: Boolean,
    default: false
  }
}, { _id: true });

const userSchema = new mongoose.Schema({
  // Application role controls access to protected backend functionality.
  role: {
    type: String,
    enum: ['customer', 'restaurant', 'admin', 'drone_operator'],
    default: 'customer',
    index: true
  },

  name: {
    type: String,
    trim: true,
    default: 'User'
  },

  fullName: {
    type: String,
    trim: true
  },

  // Email is optional for some registered-user flows.
  email: {
    type: String,
    unique: true,
    sparse: true,
    lowercase: true,
    trim: true,
    index: true
  },

  // Microsoft object ID is used to link a student to their Microsoft account.
  microsoftId: {
    type: String,
    unique: true,
    sparse: true,
    index: true
  },

  tenantId: String,

  // Password is still available for the existing email/password flow.
  password: {
    type: String,
    select: false
  },

  // Optional phone number for registered-user profiles. Guest identities are
  // stored separately in the Guest collection.
  phone: {
    type: String,
    trim: true,
    index: true
  },

  avatarUrl: String,
  profileImage: String,

  deliveryAddress: {
    type: String,
    trim: true
  },

  addresses: [addressSchema],

  notificationSettings: {
    orderUpdates: {
      type: Boolean,
      default: true
    },
    promotions: {
      type: Boolean,
      default: true
    },
    systemAlerts: {
      type: Boolean,
      default: true
    }
  },

  language: {
    type: String,
    default: 'en'
  },

  theme: {
    type: String,
    enum: ['light', 'dark', 'system'],
    default: 'system'
  },

  favourites: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Food'
  }],

  verified: {
    type: Boolean,
    default: false
  }
}, { timestamps: true });

// Keep fullName populated when only name was supplied.
userSchema.pre('save', function setFullName(next) {
  if (!this.fullName) {
    this.fullName = this.name;
  }

  next();
});

module.exports = mongoose.model('User', userSchema);
