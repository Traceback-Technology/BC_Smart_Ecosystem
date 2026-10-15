# Backend changes applied

- Restricted CORS to `CLIENT_ORIGIN` allow-list and added API rate limiting.
- Validates `MONGO_URI` and a unique random `TOKEN_SECRET` at startup; Stripe requires a webhook secret when enabled. Production 5xx responses avoid exposing internal exception messages.
- Added protected multipart food-image upload endpoint (`POST /api/foods/upload-image`), 5 MB image size limit, image MIME allow-list, static `/uploads/` hosting, and `PUBLIC_API_URL` support. Food records support URL-based image fields.
- Validates/whitelists food update payloads.
- Guest JWTs are explicitly forbidden from the orders router; guest sessions are for BC Ways navigation.
- Added unique payment-per-order constraint, Stripe PaymentIntent idempotency key, already-paid checks and service/delivery fee configuration.
- Added `SERVICE_FEE`, `DRONE_DELIVERY_FEE`, and `PUBLIC_API_URL` to `.env.example`.

## Deployment notes

Install dependencies with `npm install`, copy `.env.example` to `.env`, and set all secrets and public URLs. Use persistent/object storage for uploaded images in production rather than ephemeral local disk. Existing databases should be checked for duplicate payment records before enabling the unique `orderId` index. This environment did not have a live MongoDB/Stripe configuration, so integration and migration tests remain required.
