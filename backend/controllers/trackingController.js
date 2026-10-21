const Tracking = require('../models/trackingModel');
const Order = require('../models/orderModel');
const Drone = require('../models/droneModel');

const isStaff = (req) => ['admin', 'drone_operator', 'restaurant'].includes(req.user?.role);
const findAccessibleOrder = (req, orderId) => isStaff(req)
  ? Order.findById(orderId)
  : Order.findOne({ _id: orderId, userId: req.user.userId });

exports.startTracking = async (req, res, next) => {
  try {
    const order = await findAccessibleOrder(req, req.params.orderId);
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
    if (order.deliveryType !== 'drone' || !order.droneId) return res.status(409).json({ success: false, message: 'Tracking can only start for an assigned drone delivery' });
    const tracking = await Tracking.create({ orderId: order._id, droneId: order.droneId, status: order.status });
    res.status(201).json({ success: true, data: tracking });
  } catch (error) { next(error); }
};

exports.updateLocation = async (req, res, next) => {
  try {
    const { latitude, longitude, batteryLevel, speed, altitude } = req.body;
    if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90 || !Number.isFinite(longitude) || longitude < -180 || longitude > 180) {
      return res.status(400).json({ success: false, message: 'Valid latitude and longitude are required' });
    }
    if (batteryLevel !== undefined && (!Number.isFinite(batteryLevel) || batteryLevel < 0 || batteryLevel > 100)) return res.status(400).json({ success: false, message: 'batteryLevel must be between 0 and 100' });
    if (speed !== undefined && (!Number.isFinite(speed) || speed < 0)) return res.status(400).json({ success: false, message: 'speed must be zero or greater' });
    if (altitude !== undefined && (!Number.isFinite(altitude) || altitude < 0)) return res.status(400).json({ success: false, message: 'altitude must be zero or greater' });
    const order = await findAccessibleOrder(req, req.params.orderId);
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
    if (order.deliveryType !== 'drone' || !order.droneId) return res.status(409).json({ success: false, message: 'This order has no assigned drone' });
    if (['delivered', 'cancelled'].includes(order.status)) return res.status(409).json({ success: false, message: 'Tracking is closed for this order' });
    const tracking = await Tracking.create({ orderId: order._id, droneId: order.droneId, status: order.status, latitude, longitude, batteryLevel, speed, altitude });
    order.tracking = { ...order.tracking.toObject?.(), courierLat: latitude, courierLng: longitude };
    await order.save();
    await Drone.findByIdAndUpdate(order.droneId, { currentLocation: { latitude, longitude }, ...(batteryLevel !== undefined ? { battery: batteryLevel } : {}), ...(speed !== undefined ? { speed } : {}), ...(altitude !== undefined ? { altitude } : {}) });
    res.json({ success: true, data: tracking });
  } catch (error) { next(error); }
};

exports.getRoute = async (req, res, next) => {
  try {
    const order = await findAccessibleOrder(req, req.params.orderId).populate('routeId');
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
    const tracking = await Tracking.find({ orderId: order._id }).sort({ timestamp: -1 }).limit(100);
    res.json({ success: true, data: { order, tracking, route: order.routeId } });
  } catch (error) { next(error); }
};
exports.getLatest = async (req, res, next) => {
  try {
    const order = await findAccessibleOrder(req, req.params.orderId);
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
    const tracking = await Tracking.findOne({ orderId: order._id }).sort({ timestamp: -1 });
    res.json({ success: true, data: tracking });
  } catch (error) { next(error); }
};
