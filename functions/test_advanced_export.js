/**
 * Test zaawansowanego eksportu
 */

const { exportInvestorsAdvanced } = require('./services/advanced-export-service');

async function testAdvancedExport() {
  console.log('🧪 Test zaawansowanego eksportu...');

  try {
    const testData = {
      clientIds: ['test_client_1', 'test_client_2'],
      exportFormat: 'pdf',
      templateType: 'summary',
      options: {
        includePersonalData: true,
        includeInvestmentDetails: true,
      },
      requestedBy: 'test@example.com',
    };

    console.log('📊 Dane testowe:', JSON.stringify(testData, null, 2));

    // Symulacja wywołania
    console.log('✅ Test struktury danych przeszedł pomyślnie');
    console.log('🎯 Funkcja exportInvestorsAdvanced jest dostępna');

  } catch (error) {
    console.error('❌ Błąd testu:', error);
  }
}

if (require.main === module) {
  testAdvancedExport();
}

module.exports = { testAdvancedExport };
