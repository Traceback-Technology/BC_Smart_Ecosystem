# Step 1 — Ordering core (MVP)

Built on top of `ORDERING_INTEGRATION_REPORT.md`. Only the gaps that blocked a full
order → kitchen → handover flow were filled.

## What changed

**Backend**
- `GET /api/orders/staff` (admin / restaurant / drone_operator): the kitchen queue.
  Default = `confirmed,preparing,ready`, oldest first. `?status=all` or `?status=a,b`,
  `?deliveryType=pickup|drone`. Customer name/phone are populated.
- Orders now store `paymentMethod`, `contact {name, phone}` and `scheduledFor`
  (the checkout UI already collected them; they were being dropped).
- `services/paymentService.js` — the single payment seam (see below).
- Cash is pickup-only (400 otherwise). Delivering a cash order marks its cash
  `Payment` as `succeeded`.
- If the payment policy fails after the order row is created, the order is removed
  and the coupon use released (no ghost orders).
- `npm test` — 8 stubbed tests (no database needed) for the above.

**Flutter (`Frontend/`)**
- Checkout has one live path: create order → (pay only if the server says `pending`)
  → open the persisted order. Cash pickup and `PAYMENT_MODE=placeholder` now work
  without Stripe keys. Sends `paymentMethod`, `contact`, `scheduledFor`.
- Tracking screen polls the backend every 8 s (`widgets/order_live_sync.dart`).
- Order history shows the real payment method / scheduled time.
- Staff `live_orders_screen.dart` loads `/api/orders/staff`, polls every 10 s, alerts
  on new orders and advances status via `PATCH /api/orders/:id/status`.
  Not signed in → the original hardcoded demo queue still shows.

## Payment modes (`PAYMENT_MODE` in `backend/.env`)

| Mode | Behaviour |
|---|---|
| `stripe` (code default) | Card order stays `pending`; PaymentSheet + webhook confirm it. |
| `placeholder` (in `.env.example`) | Non-cash orders are auto-paid with a simulated Payment. **Dev/demo only.** |
| `sandbox` | **Step 2.** Currently behaves like `stripe`. |
| (cash, any mode) | Pickup only; confirmed immediately; paid on collection. |

## Placeholders for the next steps
- **Step 2:** `paymentService.applyPaymentPolicy` → `case 'sandbox'`, and
  `_payWithStripe` in `bc_eats_checkout_screen.dart` (marked `STEP 2 SEAM`).
  The sandbox only has to create a `Payment`, mark it `succeeded`, and set the order
  to `confirmed` — same contract as the Stripe webhook.
- **Step 3:** staff "ready → drone orders" currently PATCHes `drone_assigned` with no
  drone attached; replace with `POST /api/drones/assign/:orderId`. Delivery OTP /
  handover is still local-only preview behaviour for live orders.

## Quick manual test
1. `PAYMENT_MODE=placeholder`, `npm run seed`, `npm run dev`.
2. Sign in as `student@bceats.test`, order (pickup, card or cash) → tracking shows "confirmed".
3. Sign in as `restaurant@bceats.test` → Live Orders shows it → tap through Preparing → Ready → Completed.
4. Student's tracking screen follows within ~8 s.
