const mongoose = require('mongoose');

const cartItemSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true
        },
        menuItemId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'MenuItem',
            required: true
        },
        quantity: {
            type: Number,
            required: true,
            min: 1
        }
    },
    { timestamps: true, collection: 'cartitems' }
);

module.exports = mongoose.model('CartItem', cartItemSchema);
