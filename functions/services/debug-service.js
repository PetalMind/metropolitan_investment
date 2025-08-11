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

    // Test 1: Sprawdź kolekcję clients
    const clientsSnapshot = await db.collection('clients').limit(3).get();
    const clientsCount = clientsSnapshot.size;

    const sampleClients = [];
    clientsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      sampleClients.push({
        id: doc.id,
        name: data.imie_nazwisko || data.fullName || data.name,
        email: data.email,
        hasData: !!data
      });
    });

    // Test 2: Sprawdź kolekcję investments  
    const investmentsSnapshot = await db.collection('investments').limit(3).get();
    const investmentsCount = investmentsSnapshot.size;

    const sampleInvestments = [];
    investmentsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      sampleInvestments.push({
        id: doc.id,
        clientId: data.clientId,
        remainingCapital: data.remainingCapital || data.kapital_pozostaly,
        hasData: !!data
      });
    });

    // Test 3: Podstawowa logika
    const testResult = {
      timestamp: new Date().toISOString(),
      processingTime: Date.now() - startTime,
      database: {
        clientsCount: clientsCount,
        investmentsCount: investmentsCount,
        clientsEmpty: clientsSnapshot.empty,
        investmentsEmpty: investmentsSnapshot.empty
      },
      samples: {
        clients: sampleClients,
        investments: sampleInvestments
      },
      functionStatus: 'working',
      version: '1.0.0'
    };

    console.log(`✅ [debugClientsTest] Test zakończony pomyślnie (${Date.now() - startTime}ms)`);
    return testResult;

  } catch (error) {
    console.error('❌ [debugClientsTest] Błąd:', error);
    return {
      timestamp: new Date().toISOString(),
      processingTime: Date.now() - startTime,
      error: error.message,
      functionStatus: 'error',
      version: '1.0.0'
    };
  }
});

module.exports = {
  debugClientsTest: exports.debugClientsTest,
};
