const Notification = require('../models/notificationModel');
const User = require('../models/usersModel');

// Only statuses listed here send a notification; all others stay silent.

const ORDER_STATUS_NOTIFICATIONS = {
    pending: (o) = ({
        title: 'Order received',
        message: `We have received your order ${o.orderNumber}.`
    }),
    preparing: (o) => ({
        title: 'Order is being prepared',
        message: `Your order ${o.orderNumber} is being prepared.`
    }),
    ready: (o)=>({
        title: 'Order ready',
        message: o.deliveryType === 'pickup'
        ? `Your order ${o.orderNumber} is ready for collection.`
        : `Your order ${o.orderNumber} is ready and will be sent out by drone.`
    }),
      cancelled: (o) => ({ title: 'Order cancelled', message: `Your order ${o.orderNumber} was cancelled.` }),
};

async function notifyOrderStatus(order){
    const build = ORDER_STATUS_NOTIFICATIONS[order.status];
    if(!build) return null;
    const {title, message} = build(order);
    return createNotification(order.userId, title, message, 'order', {
        orderId: order._id,
        status: order.status,
    })
};

module.exports = {createNotification, notifyOrderStatus}