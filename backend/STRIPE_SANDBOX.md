# Stripe Sandbox payments

BC Eats takes card payments through Stripe. During development everything runs
against a **Stripe Sandbox**: a separate test account where no real money moves
and Stripe's test cards decide each outcome. The code is the same as live
Stripe; only the keys differ.

## How a card payment flows

1. `POST /api/orders` creates the order as `pending`.
2. `POST /api/payments/intent` with `{ "orderId" }` creates a Stripe PaymentIntent for the
   order total (amount comes from the server, never the client) and returns `clientSecret`.
3. The app opens the Stripe PaymentSheet with that `clientSecret`; the card goes straight to Stripe.
4. Stripe reports the result. Either path confirms the order (`pending` → `confirmed`) and
   sends a "Payment successful" / "Payment failed" notification:
   - **Webhook** `POST /api/payments/webhook` (signature-verified), or
   - **Sync** `POST /api/payments/:id/sync`, which the app calls after the sheet closes.

**Cash** (`"paymentMethod": "cash"` on `POST /api/orders`) skips Stripe entirely. It is
pickup-only (400 for drone orders). The order is `confirmed` immediately with a `pending`
cash payment that becomes `succeeded` when staff mark the order `delivered`, or `failed` if
it is cancelled. Orders default to `card`.

The payment is only marked `succeeded` if Stripe's amount and currency match the order.
A succeeded or refunded payment is never downgraded by a late or out-of-order update.

## One-time setup

1. In the [Stripe Dashboard](https://dashboard.stripe.com), open the account switcher and
   create (or select) a **sandbox**.
2. In the sandbox, go to **Developers → API keys** and copy the
   **Secret key** (`sk_test_...`) and **Publishable key** (`pk_test_...`).
3. In `backend/.env` (never commit it):

   ```env
   PAYMENT_MODE=sandbox
   STRIPE_SECRET_KEY=sk_test_...
   STRIPE_PUBLISHABLE_KEY=pk_test_...
   STRIPE_CURRENCY=zar
   ```

With `PAYMENT_MODE=sandbox` the server **refuses to start with a live key** (`sk_live_...`),
so a copy/paste mistake cannot charge a real card. It also refuses to start if the two keys
come from different accounts. On startup it logs which Stripe mode it is in.

The app gets the publishable key from `GET /api/payments/config`, so it never has to be built
with the key, and changing keys only needs a backend restart.

### Render

In the Render service, open **Environment** and add the same variables as above
(`PAYMENT_MODE`, `STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`, `STRIPE_CURRENCY`), plus
`STRIPE_WEBHOOK_SECRET` from the webhook endpoint described below. Save, and let Render redeploy.
Check it with `https://<your-api>/api/payments/config`: it should return `"enabled": true`.

### Webhooks (optional in sandbox)

Without a webhook secret, sandbox mode still works: the sync endpoint pulls the result from
Stripe. To test the real webhook path too:

- **Local machine:** install the [Stripe CLI](https://docs.stripe.com/stripe-cli), then
  ```sh
  stripe login
  stripe listen --forward-to localhost:8000/api/payments/webhook
  ```
  Copy the `whsec_...` it prints into `STRIPE_WEBHOOK_SECRET` and restart the server.
  Leave `stripe listen` running while you test.
- **Deployed backend (Render):** in the sandbox go to **Developers → Webhooks → Add endpoint**,
  URL `https://<your-api>/api/payments/webhook`, events `payment_intent.succeeded`,
  `payment_intent.payment_failed`, `payment_intent.canceled`. Put that endpoint's signing
  secret in the Render env vars along with the sandbox keys above.

## Testing from Postman (no app needed)

Use the **12 - Payments** folder in `postman/BC-Eats-API.postman_collection.json`.

1. Sign in as `student@bceats.test` / `Password1` (after `node seed.js`) and set `{{token}}`.
2. Create an order and set `{{orderId}}`.
3. **Create Stripe PaymentIntent** and set `{{paymentId}}` from `data._id`.
4. **Sandbox: pay with a test card** with a body such as `{ "testCard": "visa" }`.
   The response shows the payment status and the order status (`confirmed` on success).

| `testCard`           | Result                                                        |
|----------------------|---------------------------------------------------------------|
| `visa`, `mastercard` | Succeeds; order becomes `confirmed`                           |
| `declined`           | 402, generic decline; payment `failed`, order stays `pending` |
| `insufficient_funds` | 402, insufficient funds decline                               |
| `expired_card`       | 402, expired card decline                                     |
| `3ds`                | Returns `nextActionUrl`; open it, click **Complete** or **Fail** |

After a decline, call **Create Stripe PaymentIntent** again for the same order and retry
with another card. This endpoint returns 403 unless `PAYMENT_MODE=sandbox` and the key is `sk_test_`.

## Testing in the app

A plain `flutter run` works: the app talks to the deployed backend and fetches the publishable
key from it. To use a local backend instead, add `--dart-define=API_BASE_URL=http://10.0.2.2:8000`
(`10.0.2.2` is your PC as seen from the Android emulator). Sign in, pay by card, and enter a
[Stripe test card](https://docs.stripe.com/testing#cards) in the PaymentSheet:

| Card number           | Result                       |
|-----------------------|------------------------------|
| `4242 4242 4242 4242` | Succeeds                     |
| `4000 0000 0000 0002` | Declined                     |
| `4000 0000 0000 9995` | Insufficient funds           |
| `4000 0027 6000 3184` | Asks for 3D Secure           |

Use any future expiry date, any 3-digit CVC and any postal code.

If you pass `--dart-define=STRIPE_PUBLISHABLE_KEY=...` it overrides the server's key, and it
**must come from the same sandbox** as the server's secret key, or the PaymentSheet fails
with "No such payment_intent".

## Refunds

Admins can refund with `POST /api/payments/:id/refund` (`{ "amount": 20 }` for partial,
empty body for full). Refunds appear under **Payments** in the sandbox dashboard.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `PAYMENT_MODE=sandbox requires a Stripe sandbox secret key` on startup | `STRIPE_SECRET_KEY` is empty, a placeholder or a live key. Use the sandbox `sk_test_...`. |
| `Stripe is not configured` (503) | `STRIPE_SECRET_KEY` is not set. |
| App says "Card payments are unavailable" | `STRIPE_PUBLISHABLE_KEY` is not set on the backend (check `/api/payments/config`). |
| `/api/payments/config` says "Authentication token required" | The server is running code from before this endpoint existed. Redeploy the latest branch. |
| Order stays `pending` after paying | No webhook reached the server. Call **Sync payment with Stripe**, or run `stripe listen`. |
| Webhook returns `400 Webhook Error` | `STRIPE_WEBHOOK_SECRET` doesn't match the `stripe listen` session or dashboard endpoint. |
| `amount_too_small` from Stripe | The order total is under Stripe's minimum charge. Add more items. |
