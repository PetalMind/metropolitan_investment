'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {
  "version.json": "1234567890abcdef",
  "index.html": "1234567890abcdef",
  "main.dart.js": "1234567890abcdef",
  "flutter_bootstrap.js": "1234567890abcdef",
  "assets/AssetManifest.json": "1234567890abcdef",
  "assets/FontManifest.json": "1234567890abcdef",
  "assets/fonts/MaterialIcons-Regular.otf": "1234567890abcdef",
  "assets/logos/logo.png": "1234567890abcdef",
  "favicon.png": "1234567890abcdef",
  "icons/Icon-192.png": "1234567890abcdef",
  "icons/Icon-512.png": "1234567890abcdef",
  "manifest.json": "1234567890abcdef",
  "assets/AssetManifest.bin": "1234567890abcdef",
  "assets/AssetManifest.bin.json": "1234567890abcdef",
  "assets/FontManifest.bin": "1234567890abcdef",
  "assets/FontManifest.bin.json": "1234567890abcdef",
  "assets/fonts/Montserrat/Montserrat-Regular.ttf": "1234567890abcdef",
  "assets/fonts/Montserrat/Montserrat-Medium.ttf": "1234567890abcdef",
  "assets/fonts/Montserrat/Montserrat-SemiBold.ttf": "1234567890abcdef",
  "assets/fonts/Montserrat/Montserrat-Bold.ttf": "1234567890abcdef",
  "assets/fonts/Montserrat/Montserrat-ExtraBold.ttf": "1234567890abcdef",
  "assets/fonts/Montserrat/Montserrat-Black.ttf": "1234567890abcdef",
  "assets/fonts/Roboto/Roboto-Regular.ttf": "1234567890abcdef",
  "assets/fonts/Roboto/Roboto-Medium.ttf": "1234567890abcdef",
  "assets/audio/notification.mp3": "1234567890abcdef",
  "canvaskit/skwasm.js": "1234567890abcdef",
  "canvaskit/skwasm.js.symbols": "1234567890abcdef",
  "canvaskit/canvaskit.js": "1234567890abcdef",
  "canvaskit/canvaskit.js.symbols": "1234567890abcdef",
  "canvaskit/canvaskit.wasm": "1234567890abcdef",
  "canvaskit/skwasm.wasm": "1234567890abcdef",
  "canvaskit/chromium/canvaskit.js": "1234567890abcdef",
  "canvaskit/chromium/canvaskit.js.symbols": "1234567890abcdef",
  "canvaskit/chromium/canvaskit.wasm": "1234567890abcdef",
  "canvaskit/skwasm_st.js": "1234567890abcdef",
  "canvaskit/skwasm_st.js.symbols": "1234567890abcdef",
  "canvaskit/skwasm_st.wasm": "1234567890abcdef",
};

// The application shell files that are downloaded before a service worker can
// start.
const CORE = [
  "main.dart.js",
  "index.html",
  "flutter_bootstrap.js",
  "assets/AssetManifest.bin.json",
  "assets/FontManifest.json"
];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});

// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      const contentCache = await caches.open(CACHE_NAME);
      const tempCache = await caches.open(TEMP);
      const manifestCache = await caches.open(MANIFEST);
      const manifest = await manifestCache.match('manifest');

      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        await contentCache.addAll(Object.keys(RESOURCES).map(key => {
          return new Request(key, {'cache': 'reload'});
        }));
        return;
      }

      const oldAssets = await manifest.json();
      const updatedAssets = Object.keys(RESOURCES);
      const removedAssets = oldAssets.filter(asset => !updatedAssets.includes(asset));

      // Remove outdated assets
      await Promise.all(removedAssets.map(async asset => {
        await contentCache.delete(asset);
      }));

      // Add new assets
      await Promise.all(updatedAssets.map(async asset => {
        const oldAsset = oldAssets.find(a => a === asset);
        if (!oldAsset) {
          await contentCache.add(new Request(asset, {'cache': 'reload'}));
        }
      }));

      await manifestCache.put('manifest', new Response(JSON.stringify(updatedAssets)));
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Metropolitan Investment: Service worker activation failed:', err);
      return;
    }
  }());
});

// === ENHANCED FETCH HANDLER WITH CACHE ERROR FIX ===
self.addEventListener('fetch', (event) => {
  // Skip cross-origin requests, like those for Google Analytics.
  if (event.request.url.startsWith(self.location.origin)) {
    event.respondWith(
      caches.match(event.request).then((cachedResponse) => {
        if (cachedResponse) {
          return cachedResponse;
        }

        return fetch(event.request).then((response) => {
          // === FIX FOR PARTIAL RESPONSE CACHE ERROR ===
          // Check if response is partial (status 206) and skip caching
          if (response.status === 206) {
            console.warn('Metropolitan Investment: Skipping cache of partial response for:', event.request.url);
            return response; // Return response without caching
          }

          // Only cache successful responses
          if (!response || response.status !== 200 || response.type !== 'basic') {
            return response;
          }

          // Clone the response before caching
          const responseToCache = response.clone();

          caches.open(CACHE_NAME).then((cache) => {
            try {
              cache.put(event.request, responseToCache);
            } catch (error) {
              console.error('Metropolitan Investment: Cache put failed:', error);
              // Send error message to main thread
              self.clients.matchAll().then(clients => {
                clients.forEach(client => {
                  client.postMessage({
                    type: 'cache-error',
                    error: error.message,
                    url: event.request.url
                  });
                });
              });
            }
          });

          return response;
        }).catch((error) => {
          console.error('Metropolitan Investment: Fetch failed:', error);
          // Return cached offline page if available
          return caches.match('/index.html');
        });
      })
    );
  }
});

// === MESSAGE HANDLER ===
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});