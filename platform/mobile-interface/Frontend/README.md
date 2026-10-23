# Install pop-up for the Flutter web app (BC Smart Ecosystem)

Gives the deployed Flutter web app an **Install** pop-up (no Play Store / App Store).

## Steps

1. Copy everything in `web/` into your Flutter project's `web/` folder:
   - `pwa-install.js`
   - `manifest.json` (replaces the existing one, or merge the fields)
   - `icons/` (these use the team logo as a placeholder; swap in the app's own logo, keeping the same file names)
2. Open `web/index.html` and add the lines from `index-snippet.html` (the `<head>` lines and the script tag before `</body>`).
3. Build and deploy:
   ```bash
   flutter build web --release
   npx wrangler deploy
   ```
4. Open the deployed HTTPS URL in Chrome or Edge, wait about 3 seconds, and the pop-up appears.

## Notes

- Needs HTTPS (Cloudflare provides it). It will not work from a plain file or a non-HTTPS address.
- Flutter registers its own service worker, so offline support is already handled. This script does not register one.
- Android/desktop Chrome and Edge: the pop-up's Install button opens the native install dialog.
- iPhone/iPad Safari: no install prompt exists, so the pop-up shows Share > Add to Home Screen.
- "Not now" hides it for 7 days. `window.showInstallPopup()` reopens it from the console.
- Change the name or icon shown in the pop-up by setting `window.PWA_APP_NAME` / `window.PWA_ICON` in a `<script>` before `pwa-install.js`.
- Check installability in DevTools under Application > Manifest.
