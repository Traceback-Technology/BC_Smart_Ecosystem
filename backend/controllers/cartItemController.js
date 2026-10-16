const CartItem = require('../models/CartItem');
const createCrudController = require('./CRUDFactory');

const base = createCrudController(CartItem);

const getCartByUser = async (userId) => {
    return CartItem.find({ userId }).populate('menuItemId');
};

const clearCart = async (userId) => {
    return CartItem.deleteMany({ userId });
};

//update-or-insert a cart item for a user. If the item already exists, update the quantity; if not, create a new cart item.
const upsertItem = async (userId, menuItemId, quantity) => {
    return CartItem.findOneAndUpdate(
        { userId, menuItemId },
        { $set: { quantity } },
        { returnDocument: 'after', upsert: true }
    );
};

module.exports = {
    ...base,
    getCartByUser,
    clearCart,
    upsertItem
};