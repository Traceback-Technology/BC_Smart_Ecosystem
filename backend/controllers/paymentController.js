const Payment = require('../models/paymentModel');
const Order = require('../models/orderModel');
const { createNotification } = require('../services/notificationService');
const { stripe, sandboxEnabled } = require('../services/stripeService');

const toPaymentStatus = (stripeStatus) => {
  if (stripeStatus === 'succeeded') return 'succeeded';
  if (stripeStatus === 'requires_action' || stripeStatus === 'requires_confirmation') return 'requires_action';
  if (stripeStatus === 'canceled') return 'failed';
  return 'pending';
};

// Stripe's ready-made test PaymentMethods; they only exist in sandbox/test mode.
// https://docs.stripe.com/testing#cards
const SANDBOX_TEST_CARDS = {
  visa: 'pm_card_visa',
  mastercard: 'pm_card_mastercard',
  declined: 'pm_card_chargeDeclined',
  insufficient_funds: 'pm_card_chargeDeclinedInsufficientFunds',
  expired_card: 'pm_card_chargeDeclinedExpiredCard',
  '3ds': 'pm_card_authenticationRequired',
};

const PAYMENT_NOTIFICATIONS = {
  succeeded: (o) => ({ title: 'Payment successful', message: `Payment received for order ${o.orderNumber}.` }),
  failed: (o) => ({ title: 'Payment failed', message: `Payment for order ${o.orderNumber} did not go through. You have not been charged.` }),
};

// Copies a Stripe PaymentIntent's state onto our Payment and confirms the order
// once it is paid. The webhook, sync and sandbox confirm all go through here so
// they always agree. Returns { order }, or { mismatch: true } when Stripe's
// amount/currency differs from what we charged (the payment is left untouched).
async function applyIntent(payment, intent) {
  const previous = payment.status;
  // Stripe may deliver events out of order; never downgrade a settled payment.
  const settled = previous === 'refunded' || (previous === 'succeeded' && intent.status !== 'succeeded');
  if (!settled) {
    if (intent.status === 'succeeded') {
      if (intent.amount !== Math.round(payment.amount * 100) || intent.currency.toLowerCase() !== payment.currency.toLowerCase()) {
        console.error(`Stripe amount/currency mismatch for payment ${payment._id}`);
        return { mismatch: true };
      }
      payment.status = 'succeeded';
    } else if (intent.status === 'canceled' || intent.last_payment_error) payment.status = 'failed';
    else payment.status = toPaymentStatus(intent.status);
    await payment.save();
  }
  const order = await Order.findById(payment.orderId);
  if (order && payment.status === 'succeeded' && order.status === 'pending') {
    order.status = 'confirmed';
    await order.save();
  }
  if (order && payment.status !== previous && PAYMENT_NOTIFICATIONS[payment.status]) {
    const { title, message } = PAYMENT_NOTIFICATIONS[payment.status](order);
    await createNotification(payment.userId, title, message, 'payment', { orderId: order._id, paymentId: payment._id })
      .catch((error) => console.error('Payment notification failed:', error.message));
  }
  return { order };
}

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

// Re-reads the PaymentIntent from Stripe. The app calls this straight after the
// PaymentSheet closes, and it is the fallback when webhooks cannot reach the
// server (e.g. local sandbox testing without the Stripe CLI).
exports.syncPayment = async (req, res, next) => {
  try {
    if (!stripe) return res.status(503).json({ success: false, message: 'Stripe is not configured' });
    const payment = await Payment.findOne({ _id: req.params.id, userId: req.user.userId });
    if (!payment?.paymentIntentId) return res.status(404).json({ success: false, message: 'Payment not found' });
    const intent = await stripe.paymentIntents.retrieve(payment.paymentIntentId);
    const result = await applyIntent(payment, intent);
    if (result.mismatch) return res.status(409).json({ success: false, message: 'Payment amount or currency does not match the order' });
    res.json({ success: true, data: payment, orderStatus: result.order?.status });
  } catch (error) { next(error); }
};

// SANDBOX ONLY: pays the PaymentIntent with one of Stripe's test cards so the
// whole flow can be exercised from Postman without the mobile app.
exports.sandboxConfirm = async (req, res, next) => {
  try {
    if (!sandboxEnabled()) return res.status(403).json({ success: false, message: 'Sandbox payments need PAYMENT_MODE=sandbox and a Stripe sandbox key (sk_test_...)' });
    const testCard = req.body.testCard || 'visa';
    if (!Object.prototype.hasOwnProperty.call(SANDBOX_TEST_CARDS, testCard)) return res.status(400).json({ success: false, message: `testCard must be one of: ${Object.keys(SANDBOX_TEST_CARDS).join(', ')}` });
    const payment = await Payment.findOne({ _id: req.params.id, userId: req.user.userId });
    if (!payment?.paymentIntentId) return res.status(404).json({ success: false, message: 'Payment not found' });
    if (['succeeded', 'refunded'].includes(payment.status)) return res.status(409).json({ success: false, message: 'This payment has already been completed' });
    let intent;
    let declineMessage = null;
    try {
      intent = await stripe.paymentIntents.confirm(payment.paymentIntentId, {
        payment_method: SANDBOX_TEST_CARDS[testCard],
        // Required by Stripe for server-side confirms; only used by the 3DS card.
        return_url: `${process.env.PUBLIC_API_URL || `${req.protocol}://${req.get('host')}`}/api/payments/sandbox/return`,
      });
    } catch (error) {
      // Declined test cards throw; the intent itself records the failure.
      if (error.type !== 'StripeCardError') throw error;
      declineMessage = error.message;
      intent = await stripe.paymentIntents.retrieve(payment.paymentIntentId);
    }
    const result = await applyIntent(payment, intent);
    if (result.mismatch) return res.status(409).json({ success: false, message: 'Payment amount or currency does not match the order' });
    const nextActionUrl = intent.next_action?.redirect_to_url?.url;
    const message = declineMessage || (nextActionUrl ? 'Open nextActionUrl in a browser to complete 3D Secure.' : `Stripe status: ${intent.status}`);
    res.status(declineMessage ? 402 : 200).json({ success: !declineMessage, message, testCard, data: payment, orderStatus: result.order?.status, ...(nextActionUrl ? { nextActionUrl } : {}) });
  } catch (error) { next(error); }
};

// SANDBOX ONLY: where Stripe sends the browser after the 3D Secure test page.
// Unauthenticated, but it only pulls the real status from Stripe.
exports.sandboxReturn = async (req, res, next) => {
  try {
    if (!sandboxEnabled()) return res.status(403).json({ success: false, message: 'Sandbox payments are disabled' });
    const payment = req.query.payment_intent && await Payment.findOne({ paymentIntentId: String(req.query.payment_intent) });
    if (!payment) return res.status(404).json({ success: false, message: 'Payment not found' });
    const intent = await stripe.paymentIntents.retrieve(payment.paymentIntentId);
    const result = await applyIntent(payment, intent);
    if (result.mismatch) return res.status(409).json({ success: false, message: 'Payment amount or currency does not match the order' });
    res.json({ success: payment.status === 'succeeded', message: `3D Secure finished; payment is ${payment.status}. You can close this tab.`, orderStatus: result.order?.status });
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
    if (['payment_intent.succeeded', 'payment_intent.payment_failed', 'payment_intent.canceled'].includes(event.type)) {
      const intent = event.data.object;
      const payment = await Payment.findOne({ paymentIntentId: intent.id });
      if (payment) {
        const result = await applyIntent(payment, intent);
        if (result.mismatch) return res.status(400).json({ received: false, message: 'Payment amount or currency mismatch' });
      }
    }
    res.json({ received: true });
  } catch (error) {
    console.error('Stripe webhook processing failed:', error);
    res.status(500).json({ received: false });
  }
};
