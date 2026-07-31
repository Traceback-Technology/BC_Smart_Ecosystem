const mongoose = require('mongoose');
const routeSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  origin: { type: String, required: true },
  destination: { type: String, required: true },
  estimatedMinutes: { type: Number, required: true },
  distanceKm: { type: Number, required: true },
  status: { type: String, enum: ['preview', 'active', 'completed', 'cancelled'], default: 'preview' }
}, { timestamps: true });
module.exports = mongoose.model('Route', routeSchema);
