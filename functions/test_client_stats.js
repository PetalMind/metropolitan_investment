// Test statystyk klientów
const admin = require('firebase-admin');
const { getSystemStats } = require('./services/clients-service');

// Inicjalizacja Firebase (użyj rzeczywistego projektu)
if (!admin.apps.length) {
  // Dodaj właściwą konfigurację projektu
  admin.initializeApp();
}

async function testClientStats() {
  console.log('🧪 Testowanie statystyk klientów...');

  try {
    // Test pobrania statystyk systemu
    console.log('\n1️⃣ Test getSystemStats...');
    
    const mockRequest = {
      data: {
        forceRefresh: true
      }
    };

    const result = await getSystemStats(mockRequest);
    
    console.log('✅ System Stats Result:');
    console.log('  - Total Clients:', result.totalClients);
    console.log('  - Active Clients:', result.activeClients);
    console.log('  - Total Investments:', result.totalInvestments);
    console.log('  - Total Remaining Capital:', result.totalRemainingCapital);
    console.log('  - Average Capital Per Client:', result.averageCapitalPerClient);
    console.log('  - Source:', result.source);
    console.log('  - Processing Time:', result.processingTime + 'ms');
    
    // Sprawdź czy dane są prawidłowe
    if (result.totalClients === 0) {
      console.log('⚠️ WARNING: Total clients is 0 - check clients collection');
    }
    
    if (result.totalRemainingCapital === 0) {
      console.log('⚠️ WARNING: Total remaining capital is 0 - check investments collection');
    }
    
    // Test bezpośredniego dostępu do bazy danych
    console.log('\n2️⃣ Test Direct Database Access...');
    const db = admin.firestore();
    
    const clientsSnapshot = await db.collection('clients').get();
    console.log('  - Clients in database:', clientsSnapshot.size);
    
    const investmentsSnapshot = await db.collection('investments').get();
    console.log('  - Investments in database:', investmentsSnapshot.size);
    
    // Próbka danych z pierwszych dokumentów
    if (clientsSnapshot.size > 0) {
      const firstClient = clientsSnapshot.docs[0].data();
      console.log('  - First client sample:', {
        id: clientsSnapshot.docs[0].id,
        fullName: firstClient.fullName || firstClient.imie_nazwisko,
        email: firstClient.email,
        isActive: firstClient.isActive
      });
    }
    
    if (investmentsSnapshot.size > 0) {
      const firstInvestment = investmentsSnapshot.docs[0].data();
      console.log('  - First investment sample:', {
        id: investmentsSnapshot.docs[0].id,
        clientId: firstInvestment.clientId,
        remainingCapital: firstInvestment.remainingCapital || firstInvestment.kapital_pozostaly,
        investmentAmount: firstInvestment.investmentAmount || firstInvestment.kwota_inwestycji,
        productType: firstInvestment.productType
      });
    }

    console.log('\n🎉 Test completed successfully!');

  } catch (error) {
    console.error('\n❌ Error during testing:', error.message);
    console.error('Stack trace:', error.stack);
  }
}

// Uruchom test
if (require.main === module) {
  testClientStats();
}

module.exports = { testClientStats };
