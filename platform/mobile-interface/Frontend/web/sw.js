// Minimal service worker for the BC Smart Ecosystem web app.
// It makes the app installable. It deliberately does NOT cache anything, so users
// always get the latest Flutter build (no stale main.dart.js after a deploy).
// Offline support can be added later once the install flow is confirmed working.

self.addEventListener('install', function () {
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', function (event) {
  // Pass every request straight to the network.
  event.respondWith(fetch(event.request));
});
