const OrderItem = require('../models/OrderItem');
const createCrudController = require('./CRUDFactory');

const base = createCrudController(OrderItem);

const getItemByOrder = async (orderId) => {
    return OrderItem.find({ orderId });
};

//this does not touch the database, it just builds a snapshot of the order item based on the menu item and quantity
const buildSnapshot = (orderId, menuItem, quantity) => {
    return {
        orderId,
        menuItemId: menuItem._id,
        menuItemName: menuItem.name,
        unitPrice: menuItem.unitPrice,
        quantity,
        lineTotal: menuItem.unitPrice * quantity
    };
};

module.exports = {
    ...base,
    getItemByOrder,
    buildSnapshot
};