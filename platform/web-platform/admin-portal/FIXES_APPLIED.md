# Frontend changes applied

- Added a central configurable REST client (`API_BASE_URL`).
- BC Eats menu uses backend `/api/foods` data when records exist, supports database image URLs, and falls back to bundled demo products when the API is offline or the database menu is empty. Categories follow the active data source.
- Inventory now fetches/saves/updates/deletes backend food records and supports an image URL or a selected image file upload. Protected admin operations use the token from backend sign-in.
- Student access supports backend email/password sign-in while preserving name-only offline preview mode. Registered-user token is attached to live API requests. Guests remain in BC Ways and BC Eats selection opens navigation to Tuck Shop, not the ordering interface.
- Checkout uses Stripe PaymentSheet when the backend, a registered-user token, and `STRIPE_PUBLISHABLE_KEY` are configured. If the backend is unreachable, it uses the existing local preview. If backend is online but the session is not authenticated, it refuses to pretend that a live order was placed. The payment action is replaced with a processing indicator during submission.
- Added Flutter HTTP/Stripe dependencies, Android Internet permission and `FlutterFragmentActivity` for Stripe PaymentSheet.

## Required configuration and verification

Run `flutter pub get`, configure `API_BASE_URL` and `STRIPE_PUBLISHABLE_KEY`, and test on supported devices. This environment had no Flutter/Dart SDK, so `flutter analyze`, platform builds, and live Stripe testing could not be run. The existing order confirmation/tracking screen remains local-state UI; connect it to backend order polling before treating tracking status as live.
