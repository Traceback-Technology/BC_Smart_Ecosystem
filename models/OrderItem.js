const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema(
    {
        orderId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Order',
            required: true
        },
        menuItemId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'MenuItem',
            required: true
        },
        menuItemName: {
            type: String,
            required: true
        },
        unitPrice: {
            type: Number,
            required: true,
            min: 0
        },
        quantity: {
            type: Number,
            required: true,
            min: 1
        },
        //unitPrice * quantity
        lineTotal: {
            type: Number,
            required: true,
            min: 0
        }
    },
    {
        timestamps: true,
        collection: 'orderitems'
    }
);

module.exports = mongoose.model('OrderItem', orderItemSchema);