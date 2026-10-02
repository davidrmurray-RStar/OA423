// OA423 dashboard service worker — keeps a cached copy of the app shell so the page
// still opens when the tablet's browser starts before the Termux server (nightly reboot).
// Network-first: the server's copy always wins when it is reachable.
const CACHE = 'oa423-shell-v1';
const SHELL = ['/', '/assets/chart.umd.js', '/assets/echarts.min.js',
               '/assets/custom-gauge-panel.png', '/SS_app.jpg', '/manifest.json'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE)
    .then(c => Promise.all(SHELL.map(u => c.add(u).catch(() => {}))))
    .then(() => self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys()
    .then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});

function netFirst(req, key, ms) {
  const c = new AbortController();
  const t = setTimeout(() => c.abort(), ms);
  return fetch(req, { signal: c.signal, cache: 'no-store' }).then(res => {
    clearTimeout(t);
    if (res && res.ok) { const copy = res.clone(); caches.open(CACHE).then(ch => ch.put(key, copy)); }
    return res;
  }).catch(() => {
    clearTimeout(t);
    return caches.match(key, { ignoreSearch: true }).then(hit => hit || Response.error());
  });
}

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;
  const p = url.pathname;
  if (p.startsWith('/api/') || p.startsWith('/docs/') || p === '/heartbeat' || p === '/sw.js' || p === '/config.js') return;
  if (req.mode === 'navigate') {
    e.respondWith(netFirst(req, (p === '/' || p === '/index.html') ? '/' : p, 6000));
  } else {
    e.respondWith(netFirst(req, p, 10000));
  }
});
