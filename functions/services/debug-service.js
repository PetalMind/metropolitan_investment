/**
 * Debug Test Function - pomocnicza funkcja do diagnozowania problemów
 */

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const { db } = require("../utils/firebase-config");

/**
 * Funkcja testowa do diagnozowania problemów z klientami
 */
exports.debugClientsTest = onCall({
  memory: "512MiB",
  timeoutSeconds: 60,
  region: "europe-west1",
  cors: true,
}, async (request) => {
  const startTime = Date.now();

  try {
    console.log('🔍 [debugClientsTest] Rozpoczynam diagnozę...');

    // Test 1: Sprawdź kolekcję clients - całkowita liczba
    const clientsCountSnapshot = await db.collection('clients').count().get();
    const totalClientsCount = clientsCountSnapshot.data().count;

    // Test 2: Sprawdź pierwsze 10 klientów
    const clientsSnapshot = await db.collection('clients').limit(10).get();
    const clientsCount = clientsSnapshot.size;

    const sampleClients = [];
    clientsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      sampleClients.push({
        id: doc.id,
        name: data.imie_nazwisko || data.fullName || data.name || 'Brak nazwy',
        email: data.email || 'Brak email',
        excelId: data.excelId || data.original_id || 'Brak excelId',
        isActive: data.isActive,
        hasData: !!data
      });
    });

    // Test 3: Sprawdź kolekcję investments - całkowita liczba  
    const investmentsCountSnapshot = await db.collection('investments').count().get();
    const totalInvestmentsCount = investmentsCountSnapshot.data().count;

    const investmentsSnapshot = await db.collection('investments').limit(10).get();
    const investmentsCount = investmentsSnapshot.size;

    const sampleInvestments = [];
    investmentsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      sampleInvestments.push({
        id: doc.id,
        clientId: data.clientId || data.klient || 'Brak clientId',
        remainingCapital: data.remainingCapital || data.kapital_pozostaly || 0,
        productType: data.productType || data.typ_produktu || 'Brak typu',
        hasData: !!data
      });
    });

    // Test 4: Sprawdź mapowanie clientId z investments do clients
    const uniqueClientIds = [...new Set(sampleInvestments.map(inv => inv.clientId))];
    const mappingTest = [];

    for (const clientId of uniqueClientIds.slice(0, 5)) {
      if (clientId && clientId !== 'Brak clientId') {
        // Sprawdź po document ID
        const byDocId = await db.collection('clients').doc(clientId).get();

        // Sprawdź po excelId
        const byExcelId = await db.collection('clients').where('excelId', '==', clientId).limit(1).get();

        // Sprawdź po original_id
        const byOriginalId = await db.collection('clients').where('original_id', '==', clientId).limit(1).get();

        mappingTest.push({
          clientId: clientId,
          foundByDocId: byDocId.exists,
          foundByExcelId: !byExcelId.empty,
          foundByOriginalId: !byOriginalId.empty,
          clientData: byDocId.exists ? {
            name: byDocId.data().imie_nazwisko || byDocId.data().fullName || 'Brak nazwy',
            excelId: byDocId.data().excelId,
            originalId: byDocId.data().original_id
          } : null
        });
      }
    }

    // Test 5: Podstawowa logika
    const testResult = {
      timestamp: new Date().toISOString(),
      processingTime: Date.now() - startTime,
      database: {
        totalClientsCount: totalClientsCount,
        totalInvestmentsCount: totalInvestmentsCount,
        sampleClientsCount: clientsCount,
        sampleInvestmentsCount: investmentsCount,
        clientsEmpty: clientsSnapshot.empty,
        investmentsEmpty: investmentsSnapshot.empty
      },
      samples: {
        clients: sampleClients,
        investments: sampleInvestments
      },
      mapping: {
        uniqueClientIdsFromInvestments: uniqueClientIds,
        mappingTest: mappingTest
      },
      functionStatus: 'working',
      version: '2.0.0'
    };

    console.log(`✅ [debugClientsTest] Test zakończony pomyślnie (${Date.now() - startTime}ms)`);
    console.log(`📊 Znaleziono ${totalClientsCount} klientów i ${totalInvestmentsCount} inwestycji w bazie`);

    return testResult;

  } catch (error) {
    console.error('❌ [debugClientsTest] Błąd:', error);
    return {
      timestamp: new Date().toISOString(),
      processingTime: Date.now() - startTime,
      error: error.message,
      functionStatus: 'error',
      version: '2.0.0'
    };
  }
});

module.exports = {
  debugClientsTest: exports.debugClientsTest,
};
