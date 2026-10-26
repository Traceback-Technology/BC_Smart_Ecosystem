/**
 * The one Stripe client for the backend, plus the sandbox safety checks.
 *
 * A Stripe Sandbox is an isolated test account: its keys start with
 * `sk_test_` / `pk_test_`, cards are never charged, and Stripe's test cards
 * (https://docs.stripe.com/testing) drive every outcome. The real PaymentIntent
 * + webhook flow runs unchanged against it.
 *
 * PAYMENT_MODE=sandbox (see paymentService.js) additionally:
 *   - refuses to start with a live key, so nobody is charged by accident;
 *   - enables POST /api/payments/:id/sandbox/confirm (pay with a test card
 *     from Postman, no mobile app needed);
 *   - lets the server start without STRIPE_WEBHOOK_SECRET, because
 *     POST /api/payments/:id/sync can pull the result from Stripe instead.
 */
const { paymentMode } = require('./paymentService');

let stripe = null;
try { if (process.env.STRIPE_SECRET_KEY) stripe = require('stripe')(process.env.STRIPE_SECRET_KEY); } catch (_) {}

const isTestKey = (key = process.env.STRIPE_SECRET_KEY) => /^(sk|rk)_test_/.test(key || '');

const sandboxEnabled = () => Boolean(stripe) && paymentMode() === 'sandbox' && isTestKey();

/** Validates the Stripe env at startup. Returns { error } to abort, or { notice } to log. */
function checkConfig(env = process.env) {
  const mode = (env.PAYMENT_MODE || 'stripe').toLowerCase();
  if (!env.STRIPE_SECRET_KEY) return { notice: 'Stripe disabled (no STRIPE_SECRET_KEY): card payments return 503.' };
  if (mode === 'sandbox' && !isTestKey(env.STRIPE_SECRET_KEY)) {
    return { error: 'PAYMENT_MODE=sandbox requires a Stripe sandbox secret key (sk_test_...). Refusing to start with a live key.' };
  }
  if (mode === 'sandbox') {
    return { notice: env.STRIPE_WEBHOOK_SECRET
      ? 'Stripe sandbox (test mode) with webhooks.'
      : 'Stripe sandbox (test mode) without STRIPE_WEBHOOK_SECRET: payments are confirmed through POST /api/payments/:id/sync.' };
  }
  if (!env.STRIPE_WEBHOOK_SECRET) return { error: 'STRIPE_WEBHOOK_SECRET is required when Stripe is enabled' };
  return { notice: `Stripe ${isTestKey(env.STRIPE_SECRET_KEY) ? 'test' : 'LIVE'} mode.` };
}

module.exports = { stripe, isTestKey, sandboxEnabled, checkConfig };
