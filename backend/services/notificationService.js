const Notification = require('../models/notificationModel');
const User = require('../models/usersModel');

// Which user setting controls which notification type.
const SETTING_FOR_TYPE = {
  order: 'orderUpdates',
  payment: 'orderUpdates',
  drone: 'orderUpdates',
  promotion: 'promotions',
  system: 'systemAlerts',
};

// Creates a notification unless the user switched that category off.
// Returns the notification, or null when it was skipped.
async function createNotification(userId, title, message, type = 'system', metadata = {}) {
  const settingKey = SETTING_FOR_TYPE[type];
  if (settingKey) {
    const user = await User.findById(userId).select('notificationSettings').lean();
    if (!user) return null;
    if (user.notificationSettings?.[settingKey] === false) return null;
  }
  return Notification.create({ userId, title, message, type, metadata });
}

// Only statuses listed here send a notification; all others stay silent.
// Each entry is a FUNCTION: (o) => ({ ... }), so `o` (the order) only
// exists when the function is called.
const ORDER_STATUS_NOTIFICATIONS = {
  pending: (o) => ({
    title: 'Order received',
    message: `We have received your order ${o.orderNumber}.`,
  }),
  preparing: (o) => ({
    title: 'Order being prepared',
    message: `Your order ${o.orderNumber} is being prepared.`,
  }),
  ready: (o) => ({
    title: 'Order ready',
    message: o.deliveryType === 'pickup'
      ? `Your order ${o.orderNumber} is ready for collection.`
      : `Your order ${o.orderNumber} is ready and will be sent out by drone.`,
  }),
};

async function notifyOrderStatus(order) {
  const build = ORDER_STATUS_NOTIFICATIONS[order.status];
  if (!build) return null;
  const { title, message } = build(order);
  return createNotification(order.userId, title, message, 'order', {
    orderId: order._id,
    status: order.status,
  });
}

module.exports = { createNotification, notifyOrderStatus };