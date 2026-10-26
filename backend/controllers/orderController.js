const mongoose = require('mongoose');
const Order = require('../models/orderModel');
const Food = require('../models/foodModel');
const Activity = require('../models/activityModel');
const Coupon = require('../models/couponModel');
const Drone = require('../models/droneModel');
// const Notification = require('../models/notificationModel');
const {notificationOrderStatus, notifyOrderStatus} = require('../services/notificationService');
const Payment = require('../models/paymentModel');
let stripe = null;
try { if (process.env.STRIPE_SECRET_KEY) stripe = require('stripe')(process.env.STRIPE_SECRET_KEY); } catch (_) {}
const { orderSchema } = require('../middlewares/validator');

const orderNo = () => `BC-${Date.now().toString(36).toUpperCase()}-${Math.floor(100 + Math.random() * 900)}`;
const money = (value) => Math.round((Number(value) + Number.EPSILON) * 100) / 100;
// const notify = async (userId, title, message, type = 'order', metadata = {}) => Notification.create({ userId, title, message, type, metadata });
const statusTransitions = {
  pending: ['confirmed', 'cancelled'],
  confirmed: ['preparing', 'cancelled'],
  preparing: ['ready', 'cancelled'],
  ready: ['drone_assigned', 'out_for_delivery', 'delivered', 'cancelled'],
  drone_assigned: ['drone_launched', 'cancelled'],
  drone_launched: ['out_for_delivery', 'delivered'],
  out_for_delivery: ['delivered'],
  delivered: [],
  cancelled: [],
};

exports.createOrder = async (req, res, next) => {
  try {
    const { error, value } = orderSchema.validate(req.body, { abortEarly: true, stripUnknown: true });
    if (error) return res.status(400).json({ success: false, message: error.details[0].message });
    if (value.items.some((item) => !mongoose.isValidObjectId(item.foodId))) {
      return res.status(400).json({ success: false, message: 'Each item must contain a valid foodId' });
    }
    const items = [];
    let subtotal = 0;
    for (const line of value.items) {
      const food = await Food.findById(line.foodId);
      if (!food || !food.available) return res.status(409).json({ success: false, message: `Food item ${line.foodId} is unavailable` });
      const price = money(food.price);
      items.push({ foodId: food._id, name: food.name, price, quantity: line.quantity, notes: line.notes || '' });
      subtotal += price * line.quantity;
    }
    subtotal = money(subtotal);
    let discount = 0;
    let coupon = null;
    if (value.couponCode) {
      coupon = await Coupon.findOne({ code: value.couponCode.toUpperCase(), active: true });
      if (!coupon) return res.status(400).json({ success: false, message: 'Invalid coupon' });
      if (coupon.expiresAt && coupon.expiresAt <= new Date()) return res.status(400).json({ success: false, message: 'Coupon expired' });
      if (coupon.usageLimit && coupon.usedCount >= coupon.usageLimit) return res.status(409).json({ success: false, message: 'Coupon usage limit reached' });
      if (subtotal < coupon.minOrderAmount) return res.status(400).json({ success: false, message: `Minimum order is ${coupon.minOrderAmount}` });
      discount = coupon.type === 'percentage' ? subtotal * coupon.value / 100 : coupon.value;
      if (coupon.maxDiscount != null) discount = Math.min(discount, coupon.maxDiscount);
      discount = money(Math.min(discount, subtotal));
    }
    const configuredServiceFee = Number(process.env.SERVICE_FEE ?? 5);
    const configuredDeliveryFee = Number(process.env.DRONE_DELIVERY_FEE ?? 15);
    const serviceFee = money(Number.isFinite(configuredServiceFee) ? Math.max(0, configuredServiceFee) : 5);
    const deliveryFee = value.deliveryType === 'drone' ? money(Number.isFinite(configuredDeliveryFee) ? Math.max(0, configuredDeliveryFee) : 15) : 0;
    const total = money(Math.max(0, subtotal + serviceFee + deliveryFee - discount));
    const order = await Order.create({
      orderNumber: orderNo(), userId: req.user.userId, items, subtotal, serviceFee, deliveryFee, discount, total,
      deliveryAddress: value.deliveryAddress.trim(), deliveryNotes: value.deliveryNotes || '', deliveryType: value.deliveryType,
      couponCode: coupon?.code, estimatedArrival: new Date(Date.now() + (value.deliveryType === 'drone' ? 25 : 30) * 60000),
    });
    if (coupon) {
      const usageFilter = { _id: coupon._id, active: true, ...(coupon.usageLimit ? { usedCount: { $lt: coupon.usageLimit } } : {}) };
      const claimed = await Coupon.updateOne(usageFilter, { $inc: { usedCount: 1 } });
      if (!claimed.modifiedCount) {
        await Order.findByIdAndDelete(order._id);
        return res.status(409).json({ success: false, message: 'Coupon usage limit reached; please retry without the coupon' });
      }
    }
    // Notification/activity failures must not turn a persisted order into an
    // apparent checkout failure that could cause duplicate submissions.
    await Promise.allSettled([
      Activity.create({ userId: req.user.userId, type: 'food', title: `Order ${order.orderNumber}`, amount: total, metadata: { orderId: order._id } }),
      // notify(req.user.userId, 'Order placed', `Your order ${order.orderNumber} has been placed.`),
      notificationOrderStatus(order),
    ]);
    res.status(201).json({ success: true, message: 'Order placed', data: order });
  } catch (error) { next(error); }
};

exports.getOrders = async (req, res, next) => {
  try {
    const page = Math.max(Number(req.query.page) || 1, 1);
    const limit = Math.min(Math.max(Number(req.query.limit) || 20, 1), 100);
    const filter = { userId: req.user.userId };
    if (req.query.status) {
      const statuses = String(req.query.status).split(',');
      filter.status = statuses.length > 1 ? { $in: statuses } : statuses[0];
    }
    const [data, total] = await Promise.all([
      Order.find(filter).populate('items.foodId', 'name image imageUrl available').populate('droneId routeId').sort({ createdAt: -1 }).skip((page - 1) * limit).limit(limit),
      Order.countDocuments(filter),
    ]);
    res.json({ success: true, count: data.length, total, page, pages: Math.ceil(total / limit), data });
  } catch (error) { next(error); }
};

exports.getOrder = async (req, res, next) => {
  try {
    const order = await Order.findOne({ _id: req.params.id, userId: req.user.userId }).populate('items.foodId', 'name image imageUrl available').populate('droneId routeId');
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
    res.json({ success: true, data: order });
  } catch (error) { next(error); }
};

exports.updateStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    if (!Object.prototype.hasOwnProperty.call(statusTransitions, status)) return res.status(400).json({ success: false, message: 'Invalid status' });
    if (status === 'cancelled') return res.status(400).json({ success: false, message: 'Use the cancellation workflow so payment state can be checked safely' });
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
    if (status === 'confirmed') {
      const payment = await Payment.findOne({ orderId: order._id });
      if (payment?.status !== 'succeeded') return res.status(409).json({ success: false, message: 'An order can only be confirmed after successful payment' });
    }
    if (!statusTransitions[order.status]?.includes(status)) return res.status(409).json({ success: false, message: `Cannot transition order from ${order.status} to ${status}` });
    order.status = status;
    await order.save();
    if (order.droneId && ['drone_launched', 'out_for_delivery'].includes(status)) await Drone.findByIdAndUpdate(order.droneId, { status: 'in_flight' });
    if (status === 'delivered' && order.droneId) await Drone.findByIdAndUpdate(order.droneId, { status: 'available' });
    // await notify(order.userId, 'Order update', `Order ${order.orderNumber} is now ${order.status}.`, 'order', { orderId: order._id }).catch((error) => console.error('Order notification failed:', error.message));
    await notificationOrderStatus(order).catch((error)=> console.error('Order notification failed', error.message));
    res.json({ success: true, data: order });
  } catch (error) { next(error); }
};

exports.getTracking = async (req, res, next) => {
  try {
    const order = await Order.findOne({ _id: req.params.id, userId: req.user.userId }).select('orderNumber tracking status estimatedArrival droneId routeId deliveryType createdAt updatedAt');
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
    res.json({ success: true, data: order });
  } catch (error) { next(error); }
};

exports.updateTracking = async (req, res, next) => {
  try {
    const allowed = ['distanceKm', 'minutesAway', 'routeLabel', 'courierLat', 'courierLng'];
    const update = {};
    for (const key of allowed) {
      if (req.body[key] === undefined) continue;
      const value = req.body[key];
      if (key === 'routeLabel' && (typeof value !== 'string' || value.length > 100)) return res.status(400).json({ success: false, message: 'routeLabel must be a string of 100 characters or fewer' });
      if (key === 'distanceKm' && (!Number.isFinite(value) || value < 0 || value > 1000)) return res.status(400).json({ success: false, message: 'distanceKm must be between 0 and 1000' });
      if (key === 'minutesAway' && (!Number.isFinite(value) || value < 0 || value > 1440)) return res.status(400).json({ success: false, message: 'minutesAway must be between 0 and 1440' });
      if (key === 'courierLat' && (!Number.isFinite(value) || value < -90 || value > 90)) return res.status(400).json({ success: false, message: 'courierLat must be between -90 and 90' });
      if (key === 'courierLng' && (!Number.isFinite(value) || value < -180 || value > 180)) return res.status(400).json({ success: false, message: 'courierLng must be between -180 and 180' });
      update[`tracking.${key}`] = value;
    }
    if (!Object.keys(update).length) return res.status(400).json({ success: false, message: 'No valid tracking fields supplied' });
    const order = await Order.findByIdAndUpdate(req.params.id, { $set: update }, { new: true, runValidators: true });
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
    res.json({ success: true, data: order });
  } catch (error) { next(error); }
};

exports.updateNotes = async (req, res, next) => {
  try {
    if (typeof req.body.deliveryNotes !== 'string' || req.body.deliveryNotes.length > 300) return res.status(400).json({ success: false, message: 'Delivery notes must be 300 characters or fewer' });
    const order = await Order.findOne({ _id: req.params.id, userId: req.user.userId });
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
    if (!['pending', 'confirmed'].includes(order.status)) return res.status(409).json({ success: false, message: 'Delivery notes can no longer be changed' });
    order.deliveryNotes = req.body.deliveryNotes;
    await order.save();
    res.json({ success: true, data: order });
  } catch (error) { next(error); }
};

exports.cancelOrder = async (req, res, next) => {
  try {
    const order = await Order.findOne({ _id: req.params.id, userId: req.user.userId });
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
    if (!['pending', 'confirmed', 'preparing', 'ready', 'drone_assigned'].includes(order.status)) return res.status(409).json({ success: false, message: 'Order cannot be cancelled at this stage' });
    const payment = await Payment.findOne({ orderId: order._id });
    if (payment?.status === 'succeeded') return res.status(409).json({ success: false, message: 'This order has already been paid. Contact campus support to request a cancellation/refund.' });
    // Prevent a still-payable Stripe intent from charging after the order has
    // been cancelled. If Stripe reports processing, do not guess the outcome.
    if (payment?.paymentIntentId) {
      if (!stripe) return res.status(503).json({ success: false, message: 'Payment provider is unavailable; the order was not cancelled. Please retry shortly.' });
      const intent = await stripe.paymentIntents.retrieve(payment.paymentIntentId);
      if (intent.status === 'succeeded') {
        payment.status = 'succeeded'; await payment.save();
        return res.status(409).json({ success: false, message: 'Payment has succeeded. Contact campus support to request a cancellation/refund.' });
      }
      if (['requires_payment_method', 'requires_confirmation', 'requires_action'].includes(intent.status)) {
        await stripe.paymentIntents.cancel(intent.id);
      } else if (intent.status !== 'canceled') {
        return res.status(409).json({ success: false, message: 'Payment is still processing; the order cannot safely be cancelled yet.' });
      }
      payment.status = 'failed';
      await payment.save();
    }
    order.status = 'cancelled';
    await order.save();
    if (order.couponCode) await Coupon.updateOne({ code: order.couponCode, usedCount: { $gt: 0 } }, { $inc: { usedCount: -1 } });
    if (order.droneId) await Drone.findByIdAndUpdate(order.droneId, { status: 'available' });
    // await notify(order.userId, 'Order cancelled', `Order ${order.orderNumber} was cancelled.`).catch((error) => console.error('Cancellation notification failed:', error.message));
    await notifyOrderStatus(order).catch((error)=> console.error('Cancellation notification failed:', error.message))
    res.json({ success: true, message: 'Order cancelled', data: order });
  } catch (error) { next(error); }
};

exports.reorder = async (req, res, next) => {
  try {
    const old = await Order.findOne({ _id: req.params.id, userId: req.user.userId });
    if (!old) return res.status(404).json({ success: false, message: 'Order not found' });
    req.body = { items: old.items.map((item) => ({ foodId: item.foodId.toString(), quantity: item.quantity, notes: item.notes })), deliveryAddress: old.deliveryAddress, deliveryNotes: old.deliveryNotes, deliveryType: old.deliveryType };
    return exports.createOrder(req, res, next);
  } catch (error) { next(error); }
};
