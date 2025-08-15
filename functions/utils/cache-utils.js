/**
 * Cache Management Utilities
 */

// In-memory cache dla szybkiego dostępu
const cache = new Map();
const cacheTimestamps = new Map();

/**
 * Pobiera wynik z cache
 * @param {string} key - Klucz cache
 * @return {Object|null} Wynik z cache lub null
 */
async function getCachedResult(key) {
  const timestamp = cacheTimestamps.get(key);
  if (!timestamp || Date.now() - timestamp > 300000) { // 5 minut
    console.log(`🗂️ [Cache] MISS - key: ${key.substring(0, 50)}... (expired or not found)`);
    cache.delete(key);
    cacheTimestamps.delete(key);
    return null;
  }

  const ageSeconds = Math.floor((Date.now() - timestamp) / 1000);
  console.log(`💾 [Cache] HIT - key: ${key.substring(0, 50)}... (age: ${ageSeconds}s)`);
  return cache.get(key);
}

/**
 * Zapisuje wynik do cache
 * @param {string} key - Klucz cache
 * @param {Object} data - Dane do zapisania
 * @param {number} ttlSeconds - Czas życia w sekundach (domyślnie 300s = 5min)
 */
async function setCachedResult(key, data, ttlSeconds = 300) {
  console.log(`💿 [Cache] SET - key: ${key.substring(0, 50)}... (TTL: ${ttlSeconds}s)`);
  cache.set(key, data);
  cacheTimestamps.set(key, Date.now());

  // Automatyczne czyszczenie cache
  setTimeout(() => {
    console.log(`🗑️ [Cache] EXPIRED - key: ${key.substring(0, 50)}...`);
    cache.delete(key);
    cacheTimestamps.delete(key);
  }, ttlSeconds * 1000);
}

/**
 * Czyści cały cache
 */
function clearCache() {
  cache.clear();
  cacheTimestamps.clear();
}

module.exports = {
  getCachedResult,
  setCachedResult,
  clearCache,
};
