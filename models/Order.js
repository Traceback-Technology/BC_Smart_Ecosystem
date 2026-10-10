const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema(
    {
        // a reference to the user who placed the order (collection pointing to another collection)
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true
        },
        status: {
            type: String,
            enum: ['pending', 'confirmed', 'preparing', 'out_for_delivery','delivered','cancelled'],
            default: 'pending',
        },
        totalAmount: {
            type: Number,
            required: true,
            min: 0
        },
        deliveryLocation: {
            type: String,
            required: true,
            trim: true
        },
        cancelledReason: {
            type: String,
            default: null
        },
    },
    {
        timestamps: true,
        collection: 'orders'
    }
);

module.exports = mongoose.model('Order', orderSchema);