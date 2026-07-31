const mongoose = require('mongoose');
const activitySchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  type: { type: String, enum: ['ride', 'food'], required: true },
  title: { type: String, required: true },
  amount: { type: Number, required: true },
  occurredAt: { type: Date, default: Date.now }
}, { timestamps: true });
module.exports = mongoose.model('Activity', activitySchema);
