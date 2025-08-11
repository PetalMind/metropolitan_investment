// Test funkcji analitycznych
const admin = require('firebase-admin');

// Inicjalizacja bez kluczy dla testów lokalnych
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'demo-project'
  });
}

// Import funkcji
const { getEmployeesAnalytics } = require('./analytics/employees_analytics');
const { getGeographicAnalytics } = require('./analytics/geographic_analytics');
const { getTrendsAnalytics } = require('./analytics/trends_analytics');

async function testAnalytics() {
  console.log('🧪 Testowanie funkcji analitycznych...');

  const testData = {
    timeRangeMonths: 12
  };

  const testContext = {
    auth: {
      uid: 'test-user'
    }
  };

  try {
    // Test 1: Employee Analytics
    console.log('\n1️⃣ Test Employee Analytics...');
    const employeesResult = await getEmployeesAnalytics(testData, testContext);
    console.log('✅ Employee Analytics: OK');
    console.log('Data keys:', Object.keys(employeesResult || {}));

    // Test 2: Geographic Analytics
    console.log('\n2️⃣ Test Geographic Analytics...');
    const geographicResult = await getGeographicAnalytics(testData, testContext);
    console.log('✅ Geographic Analytics: OK');
    console.log('Data keys:', Object.keys(geographicResult || {}));

    // Test 3: Trends Analytics
    console.log('\n3️⃣ Test Trends Analytics...');
    const trendsResult = await getTrendsAnalytics(testData, testContext);
    console.log('✅ Trends Analytics: OK');
    console.log('Data keys:', Object.keys(trendsResult || {}));

    console.log('\n🎉 Wszystkie testy przeszły pomyślnie!');

  } catch (error) {
    console.error('\n❌ Błąd podczas testowania:', error.message);
    console.error('Stack trace:', error.stack);
  }
}

// Uruchom testy
if (require.main === module) {
  testAnalytics();
}

module.exports = { testAnalytics };
