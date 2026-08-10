// Tombstone service worker — its only job is to uninstall its predecessor.
//
// The app is built with `--pwa-strategy=none` and ships no worker of its own,
// but devices that loaded an earlier build still have Flutter's generated
// worker installed. That worker serves `index.html` and `main.dart.js` from its
// own cache, ahead of the network, so such a device stays pinned to an old
// build no matter what the server sends — and it cannot be rescued from inside
// the page, because the page it runs is the cached one.
//
// The escape hatch is the browser's own update check: it re-fetches THIS url on
// navigation and installs it whenever the bytes differ. Deleting the file
// instead would rely on 404-triggered unregistration, which browsers treat
// inconsistently; shipping a worker that deliberately removes itself does not.
//
// Keep this file until every active install is known to have picked it up —
// removing it early just leaves the old worker in place.
//
// It lives outside `web/` on purpose: `flutter build web --pwa-strategy=none`
// writes its own EMPTY flutter_service_worker.js and would clobber a copy kept
// there. Deploying is therefore:
//
//     flutter build web --release --base-href=/app/ --pwa-strategy=none
//     cp tool/sw_tombstone.js build/web/flutter_service_worker.js
//
// (Flutter's empty file would also stop the caching, but it leaves the stale
// Cache Storage in place and never reloads the open page.)

self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) => Promise.all(keys.map((key) => caches.delete(key))))
      .then(() => self.registration.unregister())
      .then(() => self.clients.matchAll({ type: 'window' }))
      .then((clients) => {
        // The open pages are still running the old cached bundle; nothing is
        // left to serve it from cache now, so reloading fetches the real one.
        for (const client of clients) {
          client.navigate(client.url);
        }
      }),
  );
});

// Never answer from cache — while this worker is alive, everything is a
// straight pass-through to the network.
self.addEventListener('fetch', () => {});
