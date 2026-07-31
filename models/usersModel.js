const mongoose = require('mongoose');
const userSchema = new mongoose.Schema({
  name: { type: String, trim: true, default: 'User' },
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  password: { type: String, required: true, select: false },
  phone: { type: String, trim: true },
  avatarUrl: String,
  deliveryAddress: { type: String, trim: true },
  verified: { type: Boolean, default: false }
}, { timestamps: true });
module.exports = mongoose.model('User', userSchema);
