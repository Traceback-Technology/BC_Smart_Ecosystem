const Payment = require('../models/paymentModel');
const Order = require('../models/orderModel');
let stripe = null;
try { if (process.env.STRIPE_SECRET_KEY) stripe = require('stripe')(process.env.STRIPE_SECRET_KEY); } catch (_) {}

const toPaymentStatus = (stripeStatus) => {
  if (stripeStatus === 'succeeded') return 'succeeded';
  if (stripeStatus === 'requires_action' || stripeStatus === 'requires_confirmation') return 'requires_action';
  if (stripeStatus === 'canceled') return 'failed';
  return 'pending';
};

exports.createPaymentIntent = async (req, res, next) => {
  try {
    if (!stripe) return res.status(503).json({ success: false, message: 'Stripe is not configured. Set STRIPE_SECRET_KEY.' });
    if (!req.body.orderId) return res.status(400).json({ success: false, message: 'orderId is required' });
    const order = await Order.findOne({ _id: req.body.orderId, userId: req.user.userId });
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
    if (order.status !== 'pending') return res.status(409).json({ success: false, message: 'Only pending orders can be paid' });
    if (!Number.isFinite(order.total) || order.total <= 0) return res.status(400).json({ success: false, message: 'Order total must be greater than zero to use card payment' });
    let payment = await Payment.findOne({ orderId: order._id });
    if (payment?.status === 'succeeded') return res.status(409).json({ success: false, message: 'This order has already been paid' });
    if (payment?.paymentIntentId) {
      const existingIntent = await stripe.paymentIntents.retrieve(payment.paymentIntentId);
      if (existingIntent.status === 'succeeded') return res.status(409).json({ success: false, message: 'This order has already been paid' });
      if (existingIntent.status === 'canceled') return res.status(409).json({ success: false, message: 'The payment attempt was cancelled. Cancel this order and create a new order to retry.' });
      // Stripe permits retrying an intent in requires_payment_method with another payment method.
      payment.status = toPaymentStatus(existingIntent.status);
      await payment.save();
      return res.json({ success: true, clientSecret: existingIntent.client_secret, paymentIntentId: existingIntent.id, data: payment });
    }
    const currency = (process.env.STRIPE_CURRENCY || 'zar').toLowerCase();
    const intent = await stripe.paymentIntents.create({
      amount: Math.round(order.total * 100), currency,
      metadata: { orderId: order._id.toString(), userId: req.user.userId.toString(), orderNumber: order.orderNumber },
      description: `BC Eats order ${order.orderNumber}`,
    }, { idempotencyKey: `bc-order-${order._id.toString()}` });
    payment = await Payment.create({ userId: req.user.userId, orderId: order._id, amount: order.total, currency, paymentIntentId: intent.id, status: toPaymentStatus(intent.status), provider: 'stripe' });
    order.stripePaymentIntentId = intent.id;
    order.paymentId = payment._id;
    await order.save();
    res.status(201).json({ success: true, clientSecret: intent.client_secret, paymentIntentId: intent.id, data: payment });
  } catch (error) { next(error); }
};

exports.getPayments = async (req, res, next) => {
  try {
    const data = await Payment.find({ userId: req.user.userId }).populate('orderId', 'orderNumber total status').sort({ createdAt: -1 });
    res.json({ success: true, data });
  } catch (error) { next(error); }
};
exports.getPayment = async (req, res, next) => {
  try {
    const payment = await Payment.findOne({ _id: req.params.id, userId: req.user.userId });
    if (!payment) return res.status(404).json({ success: false, message: 'Payment not found' });
    res.json({ success: true, data: payment });
  } catch (error) { next(error); }
};
exports.refundPayment = async (req, res, next) => {
  try {
    if (!stripe) return res.status(503).json({ success: false, message: 'Stripe is not configured' });
    const payment = await Payment.findById(req.params.id);
    if (!payment?.paymentIntentId) return res.status(404).json({ success: false, message: 'Payment not found' });
    if (payment.status !== 'succeeded') return res.status(409).json({ success: false, message: 'Only successful payments can be refunded' });
    let amount;
    if (req.body.amount !== undefined) {
      const requested = Number(req.body.amount);
      const refundable = Math.round((payment.amount - (payment.refundAmount || 0)) * 100) / 100;
      if (!Number.isFinite(requested) || requested <= 0 || requested > refundable) return res.status(400).json({ success: false, message: `Refund amount must be greater than zero and no more than the remaining refundable amount (${refundable})` });
      amount = Math.round(requested * 100);
    }
    const refund = await stripe.refunds.create({ payment_intent: payment.paymentIntentId, ...(amount ? { amount } : {}) });
    payment.refundAmount = (payment.refundAmount || 0) + (refund.amount || 0) / 100;
    if (payment.refundAmount >= payment.amount) payment.status = 'refunded';
    await payment.save();
    res.json({ success: true, data: payment });
  } catch (error) { next(error); }
};

exports.webhook = async (req, res) => {
  try {
    if (!stripe) return res.status(503).send('Stripe not configured');
    if (!process.env.STRIPE_WEBHOOK_SECRET) return res.status(503).send('Stripe webhook secret not configured');
    let event;
    try { event = stripe.webhooks.constructEvent(req.body, req.headers['stripe-signature'], process.env.STRIPE_WEBHOOK_SECRET); }
    catch (error) { return res.status(400).send(`Webhook Error: ${error.message}`); }
    const intent = event.data.object;
    if (['payment_intent.succeeded', 'payment_intent.payment_failed', 'payment_intent.canceled'].includes(event.type)) {
      const payment = await Payment.findOne({ paymentIntentId: intent.id });
      if (payment) {
        // Stripe may deliver events out of order; never downgrade a successful payment.
        if (payment.status === 'succeeded' && event.type !== 'payment_intent.succeeded') return res.json({ received: true });
        if (event.type === 'payment_intent.succeeded') {
          if (intent.amount !== Math.round(payment.amount * 100) || intent.currency.toLowerCase() !== payment.currency.toLowerCase()) {
            console.error(`Stripe amount/currency mismatch for payment ${payment._id}`);
            return res.status(400).json({ received: false, message: 'Payment amount or currency mismatch' });
          }
          payment.status = 'succeeded';
        } else if (event.type === 'payment_intent.payment_failed') payment.status = 'failed';
        else payment.status = 'failed';
        await payment.save();
        const order = await Order.findById(payment.orderId);
        if (order && payment.status === 'succeeded' && order.status === 'pending') {
          order.status = 'confirmed';
          await order.save();
        }
      }
    }
    res.json({ received: true });
  } catch (error) {
    console.error('Stripe webhook processing failed:', error);
    res.status(500).json({ received: false });
  }
};
