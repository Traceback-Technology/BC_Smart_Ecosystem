/**
 * Payment seam for the ordering flow.
 *
 * The order controller never decides "is this order paid?" itself; it calls
 * applyPaymentPolicy() once after creating an order. The `Payment` document is
 * the source of truth (same as the Stripe flow), so cancel/confirm/refund
 * checks elsewhere keep working unchanged.
 *
 * PAYMENT_MODE (env), default `stripe`:
 *   stripe       Real Stripe flow. Order stays `pending` until the webhook marks
 *                its Payment `succeeded` and confirms the order.
 *   placeholder  MVP/dev only. Every non-cash order is auto-paid with a
 *                simulated Payment so the kitchen flow can be demoed with no
 *                gateway. NEVER use in production.
 *   sandbox      STEP 2 (not built yet). Behaves like `stripe`: order waits as
 *                `pending` until the sandbox "confirm payment" call succeeds.
 *
 * Cash (pickup only) works in every mode: confirmed immediately, with a
 * `pending` cash Payment that is settled when the order is handed over.
 */
const Payment = require('../models/paymentModel');

const paymentMode = () => (process.env.PAYMENT_MODE || 'stripe').toLowerCase();

let warnedPlaceholder = false;

async function createPayment(order, fields) {
  const payment = await Payment.create({
    userId: order.userId,
    orderId: order._id,
    amount: order.total,
    currency: process.env.STRIPE_CURRENCY || 'zar',
    ...fields,
  });
  order.paymentId = payment._id;
  return payment;
}

/** Called once, right after an order is created. Decides its initial payment state. */
async function applyPaymentPolicy(order) {
  if (order.paymentMethod === 'cash') {
    await createPayment(order, { provider: 'cash', status: 'pending', metadata: { payOnCollection: true } });
    order.status = 'confirmed';
    await order.save();
    return order;
  }

  switch (paymentMode()) {
    case 'placeholder':
      if (!warnedPlaceholder) {
        console.warn('PAYMENT_MODE=placeholder: orders are auto-paid with NO real payment. Development/demo only.');
        warnedPlaceholder = true;
      }
      await createPayment(order, { provider: 'other', status: 'succeeded', metadata: { simulated: true, mode: 'placeholder' } });
      order.status = 'confirmed';
      await order.save();
      return order;

    case 'sandbox':
      // STEP 2: create a sandbox payment session here and leave the order
      // `pending`. The sandbox confirm endpoint then sets Payment `succeeded`
      // and moves the order to `confirmed` (same as the Stripe webhook does).
      return order;

    case 'stripe':
    default:
      // Customer pays via POST /api/payments/intent; the webhook confirms.
      return order;
  }
}

/** Cash is collected at handover: mark the cash Payment succeeded when the order is delivered. */
async function settleCashPayment(order) {
  if (order.paymentMethod !== 'cash') return;
  await Payment.updateOne({ orderId: order._id, provider: 'cash', status: 'pending' }, { status: 'succeeded' });
}

module.exports = { paymentMode, applyPaymentPolicy, settleCashPayment };
