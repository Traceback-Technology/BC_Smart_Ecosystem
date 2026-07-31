const mongoose = require('mongoose');
const orderSchema = new mongoose.Schema({
  orderNumber: { type: String, unique: true, required: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  items: [{
    foodId: { type: mongoose.Schema.Types.ObjectId, ref: 'Food', required: true },
    name: String, price: Number, quantity: { type: Number, min: 1, required: true }, notes: String
  }],
  subtotal: { type: Number, required: true },
  deliveryFee: { type: Number, default: 0 },
  total: { type: Number, required: true },
  deliveryAddress: { type: String, required: true },
  deliveryNotes: String,
  status: { type: String, enum: ['pending', 'preparing', 'ready', 'out_for_delivery', 'delivered', 'cancelled'], default: 'pending' },
  estimatedArrival: Date,
  tracking: {
    distanceKm: { type: Number, default: 0.8 },
    minutesAway: { type: Number, default: 8 },
    routeLabel: { type: String, default: 'Fast Route' },
    courierLat: Number, courierLng: Number
  }
}, { timestamps: true });
module.exports = mongoose.model('Order', orderSchema);
