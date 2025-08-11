/**
 * Test składni Firebase Functions - sprawdza błędy składniowe
 */

console.log('🧪 Sprawdzanie składni Firebase Functions...');

try {
  console.log('1️⃣ Sprawdzam główny plik index.js...');
  const indexModule = require('./functions/index.js');
  console.log('✅ index.js - składnia poprawna');
  console.log('📋 Dostępne funkcje:', Object.keys(indexModule));

  console.log('\n2️⃣ Sprawdzam clients-service.js...');
  const clientsService = require('./functions/services/clients-service.js');
  console.log('✅ clients-service.js - składnia poprawna');
  console.log('📋 Eksportowane funkcje:', Object.keys(clientsService));

  console.log('\n3️⃣ Sprawdzam utils...');
  const cacheUtils = require('./functions/utils/cache-utils.js');
  console.log('✅ cache-utils.js - składnia poprawna');

  const dataMapping = require('./functions/utils/data-mapping.js');
  console.log('✅ data-mapping.js - składnia poprawna');

  const firebaseConfig = require('./functions/utils/firebase-config.js');
  console.log('✅ firebase-config.js - składnia poprawna');

  console.log('\n🎉 Wszystkie pliki mają poprawną składnię JavaScript!');
  console.log('✅ Możesz bezpiecznie wdrożyć funkcje Firebase');

} catch (error) {
  console.error('\n❌ Błąd składni:', error.message);
  console.error('🔍 Szczegóły:', error.stack);
  console.log('\n🛠️ Napraw błędy składni przed wdrożeniem!');
}

console.log('\n👋 Sprawdzenie składni zakończone.');
