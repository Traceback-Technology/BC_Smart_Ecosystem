# BC Eats frontend integration

## API URL

Set the API base URL at build/run time rather than hard-coding a production host:

- Android emulator: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000`
- iOS simulator: `flutter run --dart-define=API_BASE_URL=http://localhost:8000`
- Physical device: use the computer/server LAN address or HTTPS deployment URL.

The menu fetches `/api/foods`. If the API cannot be reached or the database has no food records, it uses the bundled demo products. As soon as at least one database product is returned, the menu displays database products instead of the demo list. Image fields accept backend `imageUrl`/`image` URL values or bundled asset paths. Categories are derived from the active product data.

## Admin product image support

The inventory add-product dialog accepts an image URL or an image file. Files are sent as multipart field `image` to `POST /api/foods/upload-image`, and the resulting URL is saved with the product. Admin API calls require a valid backend admin/restaurant bearer token. The student access screen now supports backend email/password sign-in as well as name-only offline preview. On successful sign-in, its bearer token is handed to the API client. Admin users can use their admin account to authenticate the protected inventory operations. Do not embed an admin token in the app build.

## Guest behaviour

Guest sessions can use BC Ways navigation. Choosing BC Eats routes a guest to BC Ways with Tuck Shop selected and does not open the ordering UI. Orders are restricted to registered-user JWTs on the backend.

## Checkout/payment status

The existing checkout remains a local preview when no authenticated backend checkout/payment client is available. Backend Stripe payment intents and webhook handling are hardened against repeated intent creation, and the pay button is replaced by a processing indicator while the local submit action is in progress. When a registered user signs in and `STRIPE_PUBLISHABLE_KEY` is configured at build time, checkout creates a database order, requests a backend PaymentIntent, and opens Stripe PaymentSheet. When the API is unreachable it uses the local preview. If the API is online but the session is unauthenticated, checkout stops rather than silently pretending a live order was placed. Never put Stripe secret keys in Flutter. The existing confirmation/tracking screen remains local-state UI; order status/payment truth is the backend and Stripe webhook until live tracking is connected.
