const mongoose = require('mongoose');

//Fields in the document
const menuItemSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String, default: '', trim: true },
  category: { type: String, required: true, trim: true },
  unitPrice: { type: Number, required: true, min: 0},
  stockQuantity: { type: Number, required: true, default: 0},
  lowStockThreshold: { type: Number, required: true, default: 5 },
  isAvailable: { type: Boolean, default: true },
  imageUrl: { type: String, default: '', trim: true },
},
{timestamps: true,collection: 'menuitems'}
);


module.exports = mongoose.model('MenuItem', menuItemSchema);