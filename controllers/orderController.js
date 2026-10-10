const Order = require('../models/Order');
const createCrudController = require('./CRUDFactory');

const base = createCrudController(Order);

const getOrdersByUser = async (userId) => {
    return Order.find({ userId }).sort({ createdAt: -1 });
};

const getOrdersByStatus = async (status) => {
    return Order.find({ status });
}

const updateStatus = async (orderId, status) => {
    return Order.findByIdAndUpdate(orderId, { $set: { status } }, { returnDocument: 'after'});
};

const cancelOrder = async (orderId, reason) => {
    return Order.findByIdAndUpdate(orderId, { $set: { status: 'cancelled', cancelledReason: reason } }, { returnDocument: 'after'});
};

module.exports = {
    ...base,
    getOrdersByUser,
    getOrdersByStatus,
    updateStatus,
    cancelOrder
};