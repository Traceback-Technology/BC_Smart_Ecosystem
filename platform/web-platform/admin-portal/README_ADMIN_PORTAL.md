# BC Eats Admin Portal (Flutter Web)

## Local run

```powershell
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=https://YOUR-LIVE-BACKEND-DOMAIN
```

## Build for Vercel

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://YOUR-LIVE-BACKEND-DOMAIN
```

Deploy the contents of `build/web` to Vercel. Configure the backend `CLIENT_ORIGIN` to include the exact deployed Vercel origin (comma-separated with other allowed origins). Do not expose `MONGO_URI`, `TOKEN_SECRET`, or Stripe secret keys in Flutter/Vercel client environment variables.

## Microsoft Entra setup required

1. Configure the backend `MICROSOFT_CLIENT_ID` and `MICROSOFT_AUTHORITY=https://login.microsoftonline.com/common`.
2. In Entra App Registration, configure a **Single-page application** redirect URI for the local origin and deployed Vercel origin.
3. Under **Expose an API**, set the Application ID URI to `api://<MICROSOFT_CLIENT_ID>` and create delegated scope `access_as_user`.
4. Ensure the access token's audience matches `MICROSOFT_CLIENT_ID`, as validated by the backend middleware.
5. Pre-create each administrator in MongoDB with the same verified email and `role: "admin"`. The backend Microsoft login endpoint intentionally refuses unknown/non-admin accounts and does not auto-create admin users.
6. Deploy backend changes alongside frontend changes. Admin writes require the backend-issued JWT returned after Microsoft token verification; the client stores that JWT and attaches it as `Authorization: Bearer ...` to protected API calls.

## Security notes

- Backend authentication is the security boundary; hiding dashboard screens in Flutter is not sufficient.
- Admin portal must only be deployed with HTTPS and the exact CORS allowlist.
- Product stock quantity and threshold fields are persisted on the Food model. Verify the backend validator allows `stockCount` and `threshold` before using stock management in production.
- Inventory now includes API-backed product list/create/edit/delete and availability toggles; stock quantity and low-stock threshold are persisted. Offline fallback remains a local preview only and is never synced until the backend is available. The dashboard summary and live-orders screens may still contain demo/static data and should not be treated as production-live until those screens are separately wired to authenticated analytics/orders endpoints.
