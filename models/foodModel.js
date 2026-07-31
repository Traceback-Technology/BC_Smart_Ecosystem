const mongoose = require('mongoose');
const foodSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  description: { type: String, required: true, trim: true },
  category: { type: String, required: true, enum: ['Burgers', 'Fries', 'Pizza', 'Drinks', 'Tacos', 'Bowls', 'Other'] },
  price: { type: Number, required: true, min: 0 },
  imageUrl: String,
  available: { type: Boolean, default: true },
  popular: { type: Boolean, default: false }
}, { timestamps: true });
module.exports = mongoose.model('Food', foodSchema);
