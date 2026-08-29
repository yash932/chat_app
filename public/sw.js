const CACHE_NAME = 'pulsechat-v1';
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/css/theme.css',
  '/css/style.css',
  '/js/app.js',
  '/js/socket.js',
  '/js/chat.js',
  '/js/media.js',
  '/js/ui.js',
  '/manifest.json'
];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(STATIC_ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((k) => {
          if (k !== CACHE_NAME) return caches.delete(k);
        })
      );
    })
  );
  self.clients.claim();
});

self.addEventListener('fetch', (e) => {
  // Pass socket.io and API requests directly to network
  if (e.request.url.includes('/socket.io/') || e.request.url.includes('/api/')) {
    return;
  }

  e.respondWith(
    caches.match(e.request).then((res) => res || fetch(e.request))
  );
});
