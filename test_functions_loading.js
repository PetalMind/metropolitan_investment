#!/usr/bin/env node

/**
 * 🔧 TEST ŁADOWANIA FUNKCJI FIREBASE
 * Sprawdza czy wszystkie funkcje można załadować bez błędów
 */

console.log("🧪 [Test] Rozpoczynam test ładowania funkcji Firebase...");

// Test 1: Import głównego modułu optimized-product-investors
try {
  console.log("📦 [Test] Ładowanie optimized-product-investors...");
  const optimizedService = require('./functions/optimized-product-investors');
  console.log("✅ [Test] optimized-product-investors załadowany!", Object.keys(optimizedService));
} catch (error) {
  console.error("❌ [Test] Błąd ładowania optimized-product-investors:", error.message);
  console.error(error.stack);
}

// Test 2: Import premium-analytics-service
try {
  console.log("📦 [Test] Ładowanie premium-analytics-service...");
  const premiumService = require('./functions/services/premium-analytics-service');
  console.log("✅ [Test] premium-analytics-service załadowany!", Object.keys(premiumService));
} catch (error) {
  console.error("❌ [Test] Błąd ładowania premium-analytics-service:", error.message);
  console.error(error.stack);
}

// Test 3: Import głównego index.js
try {
  console.log("📦 [Test] Ładowanie głównego index.js...");
  const mainIndex = require('./functions/index');
  console.log("✅ [Test] index.js załadowany!", Object.keys(mainIndex));
} catch (error) {
  console.error("❌ [Test] Błąd ładowania index.js:", error.message);
  console.error(error.stack);
}

// Test 4: Import wszystkich utils
try {
  console.log("📦 [Test] Ładowanie firebase-config...");
  const firebaseConfig = require('./functions/utils/firebase-config');
  console.log("✅ [Test] firebase-config załadowany!");

  console.log("📦 [Test] Ładowanie cache-utils...");
  const cacheUtils = require('./functions/utils/cache-utils');
  console.log("✅ [Test] cache-utils załadowany!");

  console.log("📦 [Test] Ładowanie unified-statistics...");
  const unifiedStats = require('./functions/utils/unified-statistics');
  console.log("✅ [Test] unified-statistics załadowany!");

} catch (error) {
  console.error("❌ [Test] Błąd ładowania utils:", error.message);
  console.error(error.stack);
}

console.log("🧪 [Test] Test ładowania zakończony.");
