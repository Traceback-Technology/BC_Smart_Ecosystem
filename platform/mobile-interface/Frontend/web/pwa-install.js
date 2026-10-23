// BC Smart Ecosystem (Flutter web) - "Install" pop-up
// Registers sw.js (a minimal service worker) unless another service worker is already active.
// Set window.PWA_REGISTER_SW = false before this script to turn that off.
// Optional settings (set before this script loads):
//   window.PWA_APP_NAME = 'BC Smart Ecosystem';
//   window.PWA_ICON = 'icons/Icon-192.png';
// Self-contained (injects its own styles), so the same file can also be dropped into
// the Flutter web build (web/index.html) with no other changes.
(function () {
  'use strict';

  var DISMISS_KEY = 'pwa-install-dismissed-at';
  var DISMISS_DAYS = 7;          // how long "Not now" hides the pop-up
  var SHOW_DELAY_MS = 3000;      // wait a moment after page load before showing
  var deferredPrompt = null;
  var APP_NAME = window.PWA_APP_NAME || 'BC Smart Ecosystem';
  var APP_ICON = window.PWA_ICON || 'icons/Icon-192.png';

  // Testing helper: open the site with ?pwa-reset to clear the "Not now" snooze
  if (/[?&]pwa-reset\b/.test(location.search)) {
    try { localStorage.removeItem(DISMISS_KEY); console.info('[pwa] snooze cleared'); } catch (e) {}
  }
  console.info('[pwa] install script loaded');

  // ---- Service worker (needed for installability) ----
  // Skipped if another service worker is already registered (e.g. one from Flutter).
  if ('serviceWorker' in navigator && window.PWA_REGISTER_SW !== false) {
    window.addEventListener('load', function () {
      navigator.serviceWorker.getRegistrations().then(function (regs) {
        if (regs.length) return;
        return navigator.serviceWorker.register('sw.js');
      }).catch(function (err) {
        console.warn('Service worker registration failed:', err);
      });
    });
  }

  // ---- Helpers ----
  function isStandalone() {
    return window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone === true;
  }
  function isIos() {
    return /iphone|ipad|ipod/i.test(navigator.userAgent) ||
      (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  }
  function recentlyDismissed() {
    try {
      var t = Number(localStorage.getItem(DISMISS_KEY));
      return t && (Date.now() - t) < DISMISS_DAYS * 24 * 60 * 60 * 1000;
    } catch (e) { return false; }
  }
  function rememberDismiss() {
    try { localStorage.setItem(DISMISS_KEY, String(Date.now())); } catch (e) {}
  }

  // ---- Styles ----
  function injectStyles() {
    if (document.getElementById('pwa-install-styles')) return;
    var css = '' +
      '.pwa-overlay{position:fixed;inset:0;z-index:2147483647;display:flex;align-items:flex-end;justify-content:center;padding:1rem;background:rgba(14,39,66,.45);opacity:0;transition:opacity .2s}' +
      '.pwa-overlay.pwa-show{opacity:1}' +
      '.pwa-dialog{width:100%;max-width:26rem;background:#fff;color:#17304d;border-radius:1rem;padding:1.5rem;box-shadow:0 12px 40px rgba(14,39,66,.3);font-family:system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif;text-align:center;transform:translateY(1.5rem);transition:transform .25s}' +
      '.pwa-overlay.pwa-show .pwa-dialog{transform:none}' +
      '.pwa-dialog img{width:64px;height:64px;border-radius:14px;margin:0 auto .75rem;display:block}' +
      '.pwa-dialog h2{margin:0 0 .5rem;font-size:1.25rem;color:#0e2742}' +
      '.pwa-dialog p{margin:0 0 1.25rem;font-size:.95rem;line-height:1.5;color:#4a5f78}' +
      '.pwa-actions{display:flex;gap:.75rem}' +
      '.pwa-actions button{flex:1;padding:.75rem 1rem;border-radius:.6rem;font:inherit;font-weight:600;cursor:pointer;border:2px solid #2a6fb5}' +
      '.pwa-install{background:#2a6fb5;color:#fff}' +
      '.pwa-install:hover{background:#1f5a96;border-color:#1f5a96}' +
      '.pwa-later{background:#fff;color:#2a6fb5}' +
      '.pwa-later:hover{background:#eaf3fc}' +
      '.pwa-actions button:focus-visible{outline:3px solid #0a7488;outline-offset:2px}' +
      '.pwa-steps{text-align:left;margin:0 0 1.25rem;padding-left:1.25rem;font-size:.95rem;line-height:1.6;color:#17304d}' +
      '@media(min-width:600px){.pwa-overlay{align-items:center}}' +
      '@media(prefers-reduced-motion:reduce){.pwa-overlay,.pwa-dialog{transition:none}}';
    var style = document.createElement('style');
    style.id = 'pwa-install-styles';
    style.textContent = css;
    document.head.appendChild(style);
  }

  // ---- Pop-up ----
  function showPopup(mode) {
    if (document.getElementById('pwa-overlay') || isStandalone()) return;
    injectStyles();

    var overlay = document.createElement('div');
    overlay.className = 'pwa-overlay';
    overlay.id = 'pwa-overlay';

    var dialog = document.createElement('div');
    dialog.className = 'pwa-dialog';
    dialog.setAttribute('role', 'dialog');
    dialog.setAttribute('aria-modal', 'true');
    dialog.setAttribute('aria-labelledby', 'pwa-title');

    var steps = mode === 'ios'
      ? '<ol class="pwa-steps"><li>Tap the <strong>Share</strong> button in Safari.</li><li>Choose <strong>Add to Home Screen</strong>.</li><li>Tap <strong>Add</strong>.</li></ol>'
      : '';
    var text = mode === 'ios'
      ? 'Add ' + APP_NAME + ' to your home screen for quick access. No app store needed.'
      : 'Install ' + APP_NAME + ' on your device for quick access. No app store needed.';

    dialog.innerHTML =
      '<img src="' + APP_ICON + '" alt="">' +
      '<h2 id="pwa-title">Install ' + APP_NAME + '</h2>' +
      '<p>' + text + '</p>' + steps +
      '<div class="pwa-actions">' +
        '<button type="button" class="pwa-later">Not now</button>' +
        (mode === 'ios' ? '' : '<button type="button" class="pwa-install">Install</button>') +
      '</div>';

    overlay.appendChild(dialog);
    document.body.appendChild(overlay);
    requestAnimationFrame(function () { overlay.classList.add('pwa-show'); });

    var installBtn = dialog.querySelector('.pwa-install');
    var laterBtn = dialog.querySelector('.pwa-later');
    (installBtn || laterBtn).focus();

    function close(remember) {
      if (remember) rememberDismiss();
      overlay.classList.remove('pwa-show');
      setTimeout(function () { overlay.remove(); }, 250);
      document.removeEventListener('keydown', onKey);
    }
    function onKey(e) { if (e.key === 'Escape') close(true); }
    document.addEventListener('keydown', onKey);

    laterBtn.addEventListener('click', function () { close(true); });
    overlay.addEventListener('click', function (e) { if (e.target === overlay) close(true); });

    if (installBtn) {
      installBtn.addEventListener('click', function () {
        if (!deferredPrompt) { close(false); return; }
        var promptEvent = deferredPrompt;
        deferredPrompt = null;
        close(false);
        promptEvent.prompt();
        promptEvent.userChoice.then(function (choice) {
          if (choice.outcome !== 'accepted') rememberDismiss();
        });
      });
    }
  }

  // ---- Android / desktop Chrome, Edge, Samsung Internet ----
  window.addEventListener('beforeinstallprompt', function (e) {
    e.preventDefault();               // stop the browser's own mini-bar
    deferredPrompt = e;
    if (isStandalone()) { console.info('[pwa] install event fired, but the app is already running as an installed app'); return; }
    if (recentlyDismissed()) { console.info('[pwa] install event fired, but the pop-up is snoozed because "Not now" was pressed. Open the site with ?pwa-reset to clear it.'); return; }
    console.info('[pwa] install event fired, showing the pop-up in ' + (SHOW_DELAY_MS / 1000) + 's');
    setTimeout(function () { showPopup('prompt'); }, SHOW_DELAY_MS);
  });

  window.addEventListener('appinstalled', function () {
    deferredPrompt = null;
    var o = document.getElementById('pwa-overlay');
    if (o) o.remove();
  });

  // ---- iPhone / iPad: no install prompt exists, so show the manual steps ----
  window.addEventListener('load', function () {
    if (isIos() && !isStandalone() && !recentlyDismissed()) {
      setTimeout(function () { showPopup('ios'); }, SHOW_DELAY_MS);
    }
  });

  // Optional: lets a page re-open the pop-up, e.g. window.showInstallPopup()
  window.showInstallPopup = function () {
    if (isStandalone()) return;
    showPopup(deferredPrompt ? 'prompt' : (isIos() ? 'ios' : 'prompt'));
  };
})();