// Run with: node --test test/   (no database needed: the Route model is stubbed)
process.env.TOKEN_SECRET = 'x'.repeat(40);
const test = require('node:test');
const assert = require('node:assert/strict');

const Route = require('../models/routeModel');
const nav = require('../controllers/navigationController');

const USER_ID = '650000000000000000000009';
const GUEST_ID = '650000000000000000000010';
const ROUTE_ID = '650000000000000000000020';

const fakeRes = () => {
  const res = { statusCode: 200, body: null };
  res.status = (code) => { res.statusCode = code; return res; };
  res.json = (body) => { res.body = body; return res; };
  return res;
};

const userReq = (body = {}, extra = {}) => ({ user: { userId: USER_ID }, body, query: {}, params: {}, ...extra });
const guestReq = (body = {}) => ({ user: { guestId: GUEST_ID, role: 'guest' }, body, query: {}, params: {} });
const valid = { origin: 'Main Gate', destination: 'Tuck Shop', distanceMeters: 412.6, estimatedMinutes: 5.2 };

test('recordHistory rejects a request without a destination', async () => {
  const res = fakeRes();
  await nav.recordHistory(userReq({ ...valid, destination: '  ' }), res, assert.ifError);
  assert.equal(res.statusCode, 400);
});

test('recordHistory rejects invalid distance and minutes', async () => {
  for (const bad of [{ distanceMeters: -1 }, { distanceMeters: 'abc' }, { estimatedMinutes: 9999 }, { estimatedMinutes: null }]) {
    const res = fakeRes();
    await nav.recordHistory(userReq({ ...valid, ...bad }), res, assert.ifError);
    assert.equal(res.statusCode, 400, JSON.stringify(bad));
  }
});

test('recordHistory stores the real metrics for the user and closes stale active routes', async (t) => {
  let closed = null;
  let created = null;
  t.mock.method(Route, 'updateMany', async (filter, update) => { closed = { filter, update }; return {}; });
  t.mock.method(Route, 'create', async (doc) => { created = doc; return { _id: ROUTE_ID, ...doc }; });

  const res = fakeRes();
  await nav.recordHistory(userReq({ ...valid, originNodeId: 'N1', destinationNodeId: 'N9' }), res, assert.ifError);

  assert.equal(res.statusCode, 201);
  assert.equal(created.userId, USER_ID);
  assert.equal(created.guestId, undefined);
  assert.equal(created.status, 'active');
  assert.equal(created.distanceKm, 0.413);
  assert.equal(created.estimatedMinutes, 5);
  assert.equal(created.destinationNodeId, 'N9');
  // Only walking routes of this owner that are still active get closed.
  assert.deepEqual(closed.filter, { userId: USER_ID, droneId: null, orderId: null, status: 'active' });
  assert.equal(closed.update.status, 'cancelled');
});

test('recordHistory links a guest route to guestId', async (t) => {
  let created = null;
  t.mock.method(Route, 'updateMany', async () => ({}));
  t.mock.method(Route, 'create', async (doc) => { created = doc; return { _id: ROUTE_ID, ...doc }; });

  const res = fakeRes();
  await nav.recordHistory(guestReq(valid), res, assert.ifError);

  assert.equal(res.statusCode, 201);
  assert.equal(created.guestId, GUEST_ID);
  assert.equal(created.userId, undefined);
});

test('updateHistoryStatus only accepts completed or cancelled', async () => {
  const res = fakeRes();
  await nav.updateHistoryStatus(userReq({ status: 'active' }, { params: { id: ROUTE_ID } }), res, assert.ifError);
  assert.equal(res.statusCode, 400);
});

test('updateHistoryStatus returns 404 for a bad id or a route that is not active', async (t) => {
  t.mock.method(Route, 'findOneAndUpdate', async () => null);

  let res = fakeRes();
  await nav.updateHistoryStatus(userReq({ status: 'completed' }, { params: { id: 'nope' } }), res, assert.ifError);
  assert.equal(res.statusCode, 404);

  res = fakeRes();
  await nav.updateHistoryStatus(userReq({ status: 'completed' }, { params: { id: ROUTE_ID } }), res, assert.ifError);
  assert.equal(res.statusCode, 404);
});

test('updateHistoryStatus is scoped to the owner and to active walking routes', async (t) => {
  let seen = null;
  t.mock.method(Route, 'findOneAndUpdate', async (filter, update) => { seen = { filter, update }; return { _id: ROUTE_ID, status: update.status }; });

  const res = fakeRes();
  await nav.updateHistoryStatus(userReq({ status: 'completed' }, { params: { id: ROUTE_ID } }), res, assert.ifError);

  assert.equal(res.statusCode, 200);
  assert.deepEqual(seen.filter, { _id: ROUTE_ID, userId: USER_ID, droneId: null, orderId: null, status: 'active' });
  assert.equal(seen.update.status, 'completed');
  assert.ok(seen.update.endedAt instanceof Date);
});

test('listHistory paginates newest-first, clamps limit and excludes previews and delivery routes', async (t) => {
  let filter = null;
  let skipped = null;
  let limited = null;
  const rows = [{ _id: 'a' }, { _id: 'b' }];
  t.mock.method(Route, 'find', (f) => {
    filter = f;
    const chain = {
      select: () => chain,
      sort: () => chain,
      skip: (n) => { skipped = n; return chain; },
      limit: (n) => { limited = n; return chain; },
      lean: async () => rows
    };
    return chain;
  });
  t.mock.method(Route, 'countDocuments', async () => 7);

  const res = fakeRes();
  await nav.listHistory(userReq({}, { query: { page: '2', limit: '500' } }), res, assert.ifError);

  assert.equal(limited, 50);
  assert.equal(skipped, 50);
  assert.deepEqual(filter.status, { $in: ['active', 'completed', 'cancelled'] });
  assert.equal(filter.userId, USER_ID);
  assert.equal(filter.droneId, null);
  assert.equal(filter.orderId, null);
  assert.deepEqual(res.body.pagination, { page: 2, limit: 50, total: 7, hasMore: false });
  assert.equal(res.body.data.length, 2);
});

test('listHistory defaults to the first page of 20 and reports hasMore', async (t) => {
  t.mock.method(Route, 'find', () => {
    const chain = { select: () => chain, sort: () => chain, skip: () => chain, limit: () => chain, lean: async () => [] };
    return chain;
  });
  t.mock.method(Route, 'countDocuments', async () => 45);

  const res = fakeRes();
  await nav.listHistory(guestReq(), res, assert.ifError);

  assert.deepEqual(res.body.pagination, { page: 1, limit: 20, total: 45, hasMore: true });
});
