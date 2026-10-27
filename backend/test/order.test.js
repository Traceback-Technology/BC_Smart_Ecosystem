// Run with: npm test   (no database needed: models are stubbed)
process.env.TOKEN_SECRET = 'x'.repeat(40);
process.env.PAYMENT_MODE = 'sandbox';
const test = require('node:test');
const assert = require('node:assert/strict');

const Food = require('../models/foodModel');
const Order = require('../models/orderModel');
const Payment = require('../models/paymentModel');
const Activity = require('../models/activityModel');
const Notification = require('../models/notificationModel');
const User = require('../models/usersModel');
const orders = require('../controllers/orderController');

const USER_ID = '650000000000000000000009';
const FOOD_ID = '650000000000000000000050';
const ORDER_ID = '650000000000000000000040';

const fakeRes = () => {
  const res = { statusCode: 200, body: null };
  res.status = (code) => { res.statusCode = code; return res; };
  res.json = (body) => { res.body = body; return res; };
  return res;
};
const orderReq = (body) => ({ user: { userId: USER_ID }, body: { items: [{ foodId: FOOD_ID, quantity: 1 }], deliveryAddress: 'Campus Tuck Shop', ...body } });

// Stubs the models createOrder touches; returns what was written.
function setup(t) {
  const written = { order: null, payments: [], notifications: [], deleted: [] };
  t.mock.method(Food, 'findById', async () => ({ _id: FOOD_ID, name: 'Wors Roll', price: 62, available: true }));
  t.mock.method(Order, 'create', async (doc) => {
    written.order = { _id: ORDER_ID, status: 'pending', ...doc, async save() { return this; } };
    return written.order;
  });
  t.mock.method(Payment, 'create', async (doc) => { written.payments.push(doc); return { _id: 'pay1', ...doc }; });
  t.mock.method(Payment, 'deleteOne', async (filter) => { written.deleted.push(['payment', filter]); });
  t.mock.method(Order, 'findByIdAndDelete', async (id) => { written.deleted.push(['order', id]); });
  t.mock.method(Activity, 'create', async () => ({}));
  t.mock.method(User, 'findById', () => ({ select: () => ({ lean: async () => ({ notificationSettings: {} }) }) }));
  t.mock.method(Notification, 'create', async (n) => { written.notifications.push(n); return n; });
  return written;
}

test('cash is refused for drone delivery', async (t) => {
  const written = setup(t);
  const res = fakeRes();
  await orders.createOrder(orderReq({ paymentMethod: 'cash', deliveryType: 'drone' }), res, assert.ifError);
  assert.equal(res.statusCode, 400);
  assert.equal(written.order, null);
});

test('cash pickup is confirmed at once with a pending cash payment', async (t) => {
  const written = setup(t);
  const res = fakeRes();
  await orders.createOrder(orderReq({ paymentMethod: 'cash', deliveryType: 'pickup' }), res, assert.ifError);
  assert.equal(res.statusCode, 201);
  assert.equal(written.order.paymentMethod, 'cash');
  assert.equal(written.order.status, 'confirmed');
  assert.equal(written.payments.length, 1);
  assert.equal(written.payments[0].provider, 'cash');
  assert.equal(written.payments[0].status, 'pending');
  assert.match(written.notifications[0].message, /Pay with cash when you collect it/);
});

test('card orders stay pending for Stripe and create no payment yet', async (t) => {
  const written = setup(t);
  const res = fakeRes();
  await orders.createOrder(orderReq({ deliveryType: 'pickup' }), res, assert.ifError);
  assert.equal(res.statusCode, 201);
  assert.equal(written.order.paymentMethod, 'card');
  assert.equal(written.order.status, 'pending');
  assert.equal(written.payments.length, 0);
});

test('a failing payment step removes the order instead of leaving a ghost', async (t) => {
  const written = setup(t);
  t.mock.method(Payment, 'create', async () => { throw new Error('db down'); });
  let passedOn = null;
  await orders.createOrder(orderReq({ paymentMethod: 'cash', deliveryType: 'pickup' }), fakeRes(), (error) => { passedOn = error; });
  assert.equal(passedOn.message, 'db down');
  assert.deepEqual(written.deleted, [['payment', { orderId: ORDER_ID }], ['order', ORDER_ID]]);
});
