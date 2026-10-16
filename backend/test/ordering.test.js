// Run with: npm test   (no database needed: models are stubbed)
process.env.TOKEN_SECRET = 'x'.repeat(40);
const test = require('node:test');
const assert = require('node:assert/strict');

const Order = require('../models/orderModel');
const Food = require('../models/foodModel');
const Payment = require('../models/paymentModel');
const Activity = require('../models/activityModel');
const Notification = require('../models/notificationModel');
const Coupon = require('../models/couponModel');
const orders = require('../controllers/orderController');

const FOOD_ID = '650000000000000000000001';
const USER_ID = '650000000000000000000009';

const fakeRes = () => {
  const res = { statusCode: 200, body: null };
  res.status = (code) => { res.statusCode = code; return res; };
  res.json = (body) => { res.body = body; return res; };
  return res;
};

function stubCommon(t) {
  const calls = { payments: [], deleted: [], orderFilter: null, paymentUpdates: [] };
  t.mock.method(Food, 'findById', async () => ({ _id: FOOD_ID, name: 'Burger', price: 50, available: true }));
  t.mock.method(Activity, 'create', async () => ({}));
  t.mock.method(Notification, 'create', async () => ({}));
  t.mock.method(Coupon, 'updateOne', async () => ({ modifiedCount: 1 }));
  t.mock.method(Order, 'create', async (doc) => ({ _id: 'order1', ...doc, status: 'pending', save: async function () { return this; } }));
  t.mock.method(Order, 'findByIdAndDelete', async (id) => { calls.deleted.push(id); });
  t.mock.method(Payment, 'create', async (doc) => { calls.payments.push(doc); return { _id: 'pay1', ...doc }; });
  t.mock.method(Payment, 'updateOne', async (...args) => { calls.paymentUpdates.push(args); return {}; });
  return calls;
}

const body = (extra = {}) => ({
  items: [{ foodId: FOOD_ID, quantity: 2 }],
  deliveryAddress: 'Campus Tuck Shop',
  deliveryType: 'pickup',
  ...extra,
});
const create = async (b) => {
  const res = fakeRes();
  await orders.createOrder({ body: b, user: { userId: USER_ID } }, res, (e) => { throw e; });
  return res;
};

test('cash pickup order is confirmed immediately with a pending cash payment', async (t) => {
  const calls = stubCommon(t);
  process.env.PAYMENT_MODE = 'stripe';
  const res = await create(body({ paymentMethod: 'cash', contact: { name: 'Thabang', phone: '0820000000' } }));
  assert.equal(res.statusCode, 201);
  assert.equal(res.body.data.status, 'confirmed');
  assert.equal(res.body.data.paymentMethod, 'cash');
  assert.deepEqual(res.body.data.contact, { name: 'Thabang', phone: '0820000000' });
  assert.equal(calls.payments[0].provider, 'cash');
  assert.equal(calls.payments[0].status, 'pending');
  assert.equal(res.body.data.total, 105); // 2*50 + service fee 5
});

test('cash is rejected for drone delivery', async (t) => {
  stubCommon(t);
  const res = await create(body({ paymentMethod: 'cash', deliveryType: 'drone' }));
  assert.equal(res.statusCode, 400);
  assert.match(res.body.message, /Cash/);
});

test('scheduledFor in the past is rejected', async (t) => {
  stubCommon(t);
  const res = await create(body({ scheduledFor: new Date(Date.now() - 60000).toISOString() }));
  assert.equal(res.statusCode, 400);
});

test('placeholder mode auto-pays and confirms card orders', async (t) => {
  const calls = stubCommon(t);
  process.env.PAYMENT_MODE = 'placeholder';
  const res = await create(body({ paymentMethod: 'card' }));
  assert.equal(res.body.data.status, 'confirmed');
  assert.equal(calls.payments[0].status, 'succeeded');
  assert.equal(calls.payments[0].metadata.simulated, true);
});

test('stripe mode leaves a card order pending for the PaymentSheet', async (t) => {
  const calls = stubCommon(t);
  process.env.PAYMENT_MODE = 'stripe';
  const res = await create(body({ paymentMethod: 'card' }));
  assert.equal(res.body.data.status, 'pending');
  assert.equal(calls.payments.length, 0);
});

test('payment policy failure removes the order instead of leaving a ghost', async (t) => {
  const calls = stubCommon(t);
  process.env.PAYMENT_MODE = 'placeholder';
  t.mock.method(Payment, 'create', async () => { throw new Error('db down'); });
  await assert.rejects(create(body()), /db down/);
  assert.deepEqual(calls.deleted, ['order1']);
});

test('staff queue defaults to confirmed/preparing/ready, oldest first', async (t) => {
  let filter, sort;
  const chain = { populate() { return chain; }, sort(s) { sort = s; return chain; }, skip() { return chain; }, limit() { return Promise.resolve([{ _id: 'o1' }]); } };
  t.mock.method(Order, 'find', (f) => { filter = f; return chain; });
  t.mock.method(Order, 'countDocuments', async () => 1);
  const res = fakeRes();
  await orders.getStaffOrders({ query: {} }, res, (e) => { throw e; });
  assert.deepEqual(filter, { status: { $in: ['confirmed', 'preparing', 'ready'] } });
  assert.deepEqual(sort, { createdAt: 1 });
  assert.equal(res.body.count, 1);

  const bad = fakeRes();
  await orders.getStaffOrders({ query: { status: 'nonsense' } }, bad, (e) => { throw e; });
  assert.equal(bad.statusCode, 400);
});

test('delivering a cash order settles its cash payment', async (t) => {
  const calls = stubCommon(t);
  const order = { _id: 'o1', status: 'ready', deliveryType: 'pickup', paymentMethod: 'cash', userId: USER_ID, orderNumber: 'BC-1', save: async () => {} };
  t.mock.method(Order, 'findById', async () => order);
  t.mock.method(Payment, 'findOne', async () => null);
  const res = fakeRes();
  await orders.updateStatus({ params: { id: 'o1' }, body: { status: 'delivered' } }, res, (e) => { throw e; });
  assert.equal(res.statusCode, 200);
  assert.equal(order.status, 'delivered');
  assert.equal(calls.paymentUpdates.length, 1);
  assert.deepEqual(calls.paymentUpdates[0][1], { status: 'succeeded' });
});
