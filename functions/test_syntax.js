/**
 * Szybki test składni dla serwisu skalowania
 */

console.log('🧪 TEST SKŁADNI - Investment Scaling Service');

try {
  // Test importu data-mapping
  console.log('📦 Test importu data-mapping...');
  const dataMapping = require('./utils/data-mapping');
  console.log('✅ data-mapping zaimportowane:', Object.keys(dataMapping));

  // Test importu firebase-config  
  console.log('📦 Test importu firebase-config...');
  const firebaseConfig = require('./utils/firebase-config');
  console.log('✅ firebase-config zaimportowane:', Object.keys(firebaseConfig));

  // Test importu investment-scaling-service
  console.log('📦 Test importu investment-scaling-service...');
  const scalingService = require('./services/investment-scaling-service');
  console.log('✅ investment-scaling-service zaimportowane:', Object.keys(scalingService));

  // Test podstawowych funkcji data-mapping
  console.log('🔧 Test funkcji safeToDouble...');
  const testValues = [null, undefined, '', '123.45', '123,45', 123.45, 'invalid'];
  testValues.forEach(val => {
    const result = dataMapping.safeToDouble(val);
    console.log(`   ${val} -> ${result}`);
  });

  console.log('✅ WSZYSTKIE TESTY SKŁADNI PRZESZŁY POMYŚLNIE');

} catch (error) {
  console.error('❌ BŁĄD SKŁADNI:', error);
  console.error('Stack trace:', error.stack);
  process.exit(1);
}

console.log('🎉 Test składni zakończony - można deployować!');
