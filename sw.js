const CACHE = 'keepmoving-v3';
const ASSETS = ['/', '/index.html', '/manifest.json'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', e => {
  // Always fetch fresh from network, fall back to cache
  e.respondWith(
    fetch(e.request).catch(() => caches.match(e.request))
  );
});

self.addEventListener('push', e => {
  let data = { title: '⚠️ Road Alert', body: 'New flag near your route — tap to view.', data: {} };
  try { data = e.data.json(); } catch {}
  e.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: '/icons/icon-192.png',
      badge: '/icons/icon-192.png',
      data: data.data || {},
      vibrate: [200, 100, 200],
      requireInteraction: false
    })
  );
});

self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(cs => {
      const existing = cs.find(c => c.url.includes('lastenbil') || c.url.includes('localhost'));
      if (existing) return existing.focus();
      return clients.openWindow('/');
    })
  );
});
