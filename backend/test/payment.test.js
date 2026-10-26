// Run with: npm test   (no database or network needed: models and Stripe calls are stubbed)
process.env.TOKEN_SECRET = 'x'.repeat(40);
process.env.STRIPE_SECRET_KEY = 'sk_test_unit';
process.env.STRIPE_WEBHOOK_SECRET = 'whsec_unit';
process.env.PAYMENT_MODE = 'sandbox';
const test = require('node:test');
const assert = require('node:assert/strict');

const Payment = require('../models/paymentModel');
const Order = require('../models/orderModel');
const Notification = require('../models/notificationModel');
const User = require('../models/usersModel');
const { stripe, checkConfig } = require('../services/stripeService');
const pay = require('../controllers/paymentController');

const USER_ID = '650000000000000000000009';
const PAYMENT_ID = '650000000000000000000030';
const ORDER_ID = '650000000000000000000040';

const fakeRes = () => {
  const res = { statusCode: 200, body: null };
  res.status = (code) => { res.statusCode = code; return res; };
  res.json = (body) => { res.body = body; return res; };
  res.send = (body) => { res.body = body; return res; };
  return res;
};
const userReq = (body = {}, extra = {}) => ({ user: { userId: USER_ID }, body, query: {}, params: { id: PAYMENT_ID }, protocol: 'http', get: () => 'localhost:8000', ...extra });
const doc = (fields) => ({ ...fields, saved: 0, async save() { this.saved += 1; return this; } });
const intent = (fields) => ({ id: 'pi_unit', amount: 4500, currency: 'zar', status: 'requires_payment_method', ...fields });

// Wires a pending R45 order + payment and records any notifications.
function setup(t, paymentFields = {}) {
  const payment = doc({ _id: PAYMENT_ID, userId: USER_ID, orderId: ORDER_ID, amount: 45, currency: 'zar', paymentIntentId: 'pi_unit', status: 'pending', ...paymentFields });
  const order = doc({ _id: ORDER_ID, orderNumber: 'BC-UNIT-1', status: 'pending' });
  const notifications = [];
  t.mock.method(Payment, 'findOne', async () => payment);
  t.mock.method(Order, 'findById', async () => order);
  t.mock.method(User, 'findById', () => ({ select: () => ({ lean: async () => ({ notificationSettings: {} }) }) }));
  t.mock.method(Notification, 'create', async (n) => { notifications.push(n); return n; });
  return { payment, order, notifications };
}

test('sandbox mode refuses to start with a live key', () => {
  assert.match(checkConfig({ PAYMENT_MODE: 'sandbox', STRIPE_SECRET_KEY: 'sk_live_abc' }).error, /sandbox secret key/);
  assert.equal(checkConfig({ PAYMENT_MODE: 'sandbox', STRIPE_SECRET_KEY: 'sk_test_abc' }).error, undefined);
  // Sandbox can run without a webhook secret (sync covers it); real Stripe cannot.
  assert.equal(checkConfig({ PAYMENT_MODE: 'stripe', STRIPE_SECRET_KEY: 'sk_live_abc' }).error, 'STRIPE_WEBHOOK_SECRET is required when Stripe is enabled');
});

test('the publishable key must come from the same sandbox as the secret key', () => {
  const base = { PAYMENT_MODE: 'sandbox', STRIPE_SECRET_KEY: 'sk_test_51AccountAAAAAAAAsecret' };
  assert.equal(checkConfig({ ...base, STRIPE_PUBLISHABLE_KEY: 'pk_test_51AccountAAAAAAAApublic' }).error, undefined);
  assert.match(checkConfig({ ...base, STRIPE_PUBLISHABLE_KEY: 'pk_test_51AccountBBBBBBBBpublic' }).error, /same Stripe sandbox/);
  assert.match(checkConfig({ ...base, STRIPE_PUBLISHABLE_KEY: 'pk_live_51AccountAAAAAAAApublic' }).error, /same Stripe sandbox/);
  assert.match(checkConfig(base).notice, /STRIPE_PUBLISHABLE_KEY is not set/);
});

test('config serves the publishable key to the app', (t) => {
  process.env.STRIPE_PUBLISHABLE_KEY = 'pk_test_unit';
  t.after(() => { delete process.env.STRIPE_PUBLISHABLE_KEY; });
  const res = fakeRes();
  pay.getConfig({}, res);
  assert.deepEqual(res.body.data, { enabled: true, publishableKey: 'pk_test_unit', currency: 'zar', sandbox: true });

  delete process.env.STRIPE_PUBLISHABLE_KEY;
  const off = fakeRes();
  pay.getConfig({}, off);
  assert.equal(off.body.data.enabled, false);
  assert.equal(off.body.data.publishableKey, null);
});

test('sync marks the payment succeeded, confirms the order and notifies once', async (t) => {
  const { payment, order, notifications } = setup(t);
  t.mock.method(stripe.paymentIntents, 'retrieve', async () => intent({ status: 'succeeded' }));
  const res = fakeRes();
  await pay.syncPayment(userReq(), res, assert.ifError);
  assert.equal(res.statusCode, 200);
  assert.equal(payment.status, 'succeeded');
  assert.equal(order.status, 'confirmed');
  assert.equal(res.body.orderStatus, 'confirmed');
  assert.equal(notifications.length, 1);
  assert.equal(notifications[0].type, 'payment');

  await pay.syncPayment(userReq(), fakeRes(), assert.ifError);
  assert.equal(notifications.length, 1, 'a repeat sync must not notify again');
});

test('sync refuses an amount mismatch and leaves the payment untouched', async (t) => {
  const { payment, order } = setup(t);
  t.mock.method(stripe.paymentIntents, 'retrieve', async () => intent({ status: 'succeeded', amount: 100 }));
  const res = fakeRes();
  await pay.syncPayment(userReq(), res, assert.ifError);
  assert.equal(res.statusCode, 409);
  assert.equal(payment.status, 'pending');
  assert.equal(payment.saved, 0);
  assert.equal(order.status, 'pending');
});

test('sync never downgrades a succeeded or refunded payment', async (t) => {
  for (const status of ['succeeded', 'refunded']) {
    const { payment } = setup(t, { status });
    t.mock.method(stripe.paymentIntents, 'retrieve', async () => intent({ status: 'canceled' }));
    await pay.syncPayment(userReq(), fakeRes(), assert.ifError);
    assert.equal(payment.status, status);
    t.mock.restoreAll();
  }
  // A late `succeeded` event must not resurrect a refunded payment either.
  const { payment } = setup(t, { status: 'refunded' });
  t.mock.method(stripe.paymentIntents, 'retrieve', async () => intent({ status: 'succeeded' }));
  await pay.syncPayment(userReq(), fakeRes(), assert.ifError);
  assert.equal(payment.status, 'refunded');
});

test('sandbox confirm pays with the chosen Stripe test card', async (t) => {
  const { payment, order } = setup(t);
  let confirmArgs = null;
  t.mock.method(stripe.paymentIntents, 'confirm', async (id, params) => { confirmArgs = { id, params }; return intent({ status: 'succeeded' }); });
  const res = fakeRes();
  await pay.sandboxConfirm(userReq({ testCard: 'mastercard' }), res, assert.ifError);
  assert.equal(res.statusCode, 200);
  assert.equal(confirmArgs.id, 'pi_unit');
  assert.equal(confirmArgs.params.payment_method, 'pm_card_mastercard');
  assert.equal(confirmArgs.params.return_url, 'http://localhost:8000/api/payments/sandbox/return');
  assert.equal(payment.status, 'succeeded');
  assert.equal(order.status, 'confirmed');
});

test('sandbox confirm reports a declined test card as a failed payment', async (t) => {
  const { payment, order, notifications } = setup(t);
  t.mock.method(stripe.paymentIntents, 'confirm', async () => { const e = new Error('Your card was declined.'); e.type = 'StripeCardError'; throw e; });
  t.mock.method(stripe.paymentIntents, 'retrieve', async () => intent({ last_payment_error: { code: 'card_declined' } }));
  const res = fakeRes();
  await pay.sandboxConfirm(userReq({ testCard: 'declined' }), res, assert.ifError);
  assert.equal(res.statusCode, 402);
  assert.equal(res.body.message, 'Your card was declined.');
  assert.equal(payment.status, 'failed');
  assert.equal(order.status, 'pending');
  assert.equal(notifications[0].title, 'Payment failed');
});

test('sandbox confirm returns the 3D Secure URL for the 3ds card', async (t) => {
  const { payment } = setup(t);
  t.mock.method(stripe.paymentIntents, 'confirm', async () => intent({ status: 'requires_action', next_action: { type: 'redirect_to_url', redirect_to_url: { url: 'https://hooks.stripe.com/3ds' } } }));
  const res = fakeRes();
  await pay.sandboxConfirm(userReq({ testCard: '3ds' }), res, assert.ifError);
  assert.equal(res.body.nextActionUrl, 'https://hooks.stripe.com/3ds');
  assert.equal(payment.status, 'requires_action');
});

test('sandbox confirm rejects unknown cards, and is off outside sandbox mode', async (t) => {
  setup(t);
  const bad = fakeRes();
  await pay.sandboxConfirm(userReq({ testCard: '4242424242424242' }), bad, assert.ifError);
  assert.equal(bad.statusCode, 400);

  process.env.PAYMENT_MODE = 'stripe';
  t.after(() => { process.env.PAYMENT_MODE = 'sandbox'; });
  const off = fakeRes();
  await pay.sandboxConfirm(userReq({ testCard: 'visa' }), off, assert.ifError);
  assert.equal(off.statusCode, 403);
});

test('webhook verifies the Stripe signature before confirming the order', async (t) => {
  const { payment, order } = setup(t);
  const body = JSON.stringify({ id: 'evt_unit', type: 'payment_intent.succeeded', data: { object: intent({ status: 'succeeded' }) } });

  const forged = fakeRes();
  await pay.webhook({ body: Buffer.from(body), headers: { 'stripe-signature': 't=1,v1=bad' } }, forged);
  assert.equal(forged.statusCode, 400);
  assert.equal(payment.status, 'pending');

  const signature = stripe.webhooks.generateTestHeaderString({ payload: body, secret: process.env.STRIPE_WEBHOOK_SECRET });
  const res = fakeRes();
  await pay.webhook({ body: Buffer.from(body), headers: { 'stripe-signature': signature } }, res);
  assert.deepEqual(res.body, { received: true });
  assert.equal(payment.status, 'succeeded');
  assert.equal(order.status, 'confirmed');
});
