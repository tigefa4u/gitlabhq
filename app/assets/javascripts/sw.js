const CURRENT_CACHE = '<%= Gitlab.version %>_<%= Gitlab.revision %>';
const OFFLINE_PAGE = '/-/offline';

// eslint-disable-next-line no-restricted-globals
self.addEventListener('install', event => {
  event.waitUntil(caches.open(CURRENT_CACHE).then(cache => cache.add(OFFLINE_PAGE)));
});

// eslint-disable-next-line no-restricted-globals
self.addEventListener('activate', event => {
  event.waitUntil(
    caches
      .keys()
      .then(cacheNames =>
        Promise.all(
          cacheNames.map(cache =>
            cache !== CURRENT_CACHE ? caches.delete(cache) : Promise.resolve(),
          ),
        ),
      ),
  );
});

// eslint-disable-next-line no-restricted-globals
self.addEventListener('fetch', event => {
  const { request } = event;
  const { method, mode } = request;

  if (method === 'GET' && mode === 'navigate') {
    event.respondWith(fetch(request).catch(() => caches.match(OFFLINE_PAGE)));
  }
});
