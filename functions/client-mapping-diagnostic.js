/**
 * 🔍 DIAGNOSTYKA MAPOWANIA ID KLIENTÓW - Firebase Functions
 * Funkcja pomocnicza do diagnozowania problemów z mapowaniem
 */

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

/**
 * Diagnostyka mapowania ID klientów - sprawdza jakość mapowania w bazie
 */
exports.diagnosticClientMapping = onCall({
  memory: "1GiB",
  timeoutSeconds: 180,
  region: "europe-west1",
}, async (request) => {
  const startTime = Date.now();
  const db = admin.firestore();

  console.log("🔍 [Diagnostic] Rozpoczynam diagnostykę mapowania klientów...");

  try {
    // KROK 1: Pobierz wszystkich klientów
    const clientsSnapshot = await db.collection('clients').get();
    const clients = [];
    const excelIdMap = new Map();
    const nameMap = new Map();
    const duplicateExcelIds = new Map();
    const duplicateNames = new Map();

    clientsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const client = {
        firestoreId: doc.id,
        excelId: data.excelId || data.original_id || data.id?.toString(),
        name: data.fullName || data.imie_nazwisko || data.name,
        email: data.email,
        phone: data.phone || data.telefon,
        votingStatus: data.votingStatus,
      };

      clients.push(client);

      // Sprawdź duplikaty excelId
      if (client.excelId) {
        if (excelIdMap.has(client.excelId)) {
          if (!duplicateExcelIds.has(client.excelId)) {
            duplicateExcelIds.set(client.excelId, []);
          }
          duplicateExcelIds.get(client.excelId).push(client);
        } else {
          excelIdMap.set(client.excelId, client);
        }
      }

      // Sprawdź duplikaty nazw
      if (client.name) {
        if (nameMap.has(client.name)) {
          if (!duplicateNames.has(client.name)) {
            duplicateNames.set(client.name, []);
          }
          duplicateNames.get(client.name).push(client);
        } else {
          nameMap.set(client.name, client);
        }
      }
    });

    // KROK 2: Sprawdź produkty inwestycyjne
    const collections = ['investments', 'bonds', 'shares', 'loans', 'apartments'];
    const productsAnalysis = {};
    let totalProducts = 0;
    let productsWithClientId = 0;
    let productsWithClientName = 0;
    let productsMapped = 0;

    for (const collection of collections) {
      const snapshot = await db.collection(collection).limit(100).get();
      const analysis = {
        total: snapshot.docs.length,
        withClientId: 0,
        withClientName: 0,
        mapped: 0,
        unmapped: [],
      };

      snapshot.docs.forEach(doc => {
        const data = doc.data();
        const excelClientId = data.ID_Klient || data.id_klient?.toString();
        const clientName = data.Klient || data.klient;

        if (excelClientId) analysis.withClientId++;
        if (clientName) analysis.withClientName++;

        // Sprawdź czy można zmapować
        const canMapByExcelId = excelClientId && excelIdMap.has(excelClientId);
        const canMapByName = clientName && nameMap.has(clientName);

        if (canMapByExcelId || canMapByName) {
          analysis.mapped++;
        } else if (excelClientId || clientName) {
          analysis.unmapped.push({
            id: doc.id,
            excelClientId,
            clientName,
          });
        }
      });

      productsAnalysis[collection] = analysis;
      totalProducts += analysis.total;
      productsWithClientId += analysis.withClientId;
      productsWithClientName += analysis.withClientName;
      productsMapped += analysis.mapped;
    }

    // KROK 3: Przygotuj raport
    const report = {
      timestamp: new Date().toISOString(),
      executionTime: Date.now() - startTime,
      clients: {
        total: clients.length,
        withExcelId: clients.filter(c => c.excelId).length,
        withName: clients.filter(c => c.name).length,
        duplicateExcelIds: Array.from(duplicateExcelIds.entries()).map(([id, clients]) => ({
          excelId: id,
          count: clients.length + 1,
          clients: clients.map(c => ({ firestoreId: c.firestoreId, name: c.name }))
        })),
        duplicateNames: Array.from(duplicateNames.entries()).map(([name, clients]) => ({
          name: name,
          count: clients.length + 1,
          clients: clients.map(c => ({ firestoreId: c.firestoreId, excelId: c.excelId }))
        })),
      },
      products: {
        total: totalProducts,
        withClientId: productsWithClientId,
        withClientName: productsWithClientName,
        mapped: productsMapped,
        unmapped: totalProducts - productsMapped,
        mappingRate: ((productsMapped / totalProducts) * 100).toFixed(2) + '%',
        byCollection: productsAnalysis,
      },
      recommendations: [],
    };

    // KROK 4: Generuj rekomendacje
    if (report.clients.duplicateExcelIds.length > 0) {
      report.recommendations.push({
        type: 'warning',
        message: `Znaleziono ${report.clients.duplicateExcelIds.length} duplikatów Excel ID`,
        action: 'Usuń lub popraw duplikaty Excel ID w klientach'
      });
    }

    if (report.clients.duplicateNames.length > 0) {
      report.recommendations.push({
        type: 'warning',
        message: `Znaleziono ${report.clients.duplicateNames.length} duplikatów nazw`,
        action: 'Sprawdź czy duplikaty nazw to rzeczywiście różni klienci'
      });
    }

    const mappingRate = (productsMapped / totalProducts) * 100;
    if (mappingRate < 80) {
      report.recommendations.push({
        type: 'error',
        message: `Niski procent mapowania: ${mappingRate.toFixed(1)}%`,
        action: 'Uruchom migrację mapowania ID klientów'
      });
    } else if (mappingRate < 95) {
      report.recommendations.push({
        type: 'warning',
        message: `Średni procent mapowania: ${mappingRate.toFixed(1)}%`,
        action: 'Sprawdź niezmapowane produkty i dodaj brakujące ID'
      });
    }

    console.log(`✅ [Diagnostic] Diagnostyka zakończona w ${Date.now() - startTime}ms`);
    console.log(`📊 [Diagnostic] Klienci: ${clients.length}, Produkty: ${totalProducts}, Zmapowane: ${productsMapped}`);

    return {
      success: true,
      data: report
    };

  } catch (error) {
    console.error("❌ [Diagnostic] Błąd diagnostyki:", error);
    throw new HttpsError(
      'internal',
      `Błąd podczas diagnostyki: ${error.message}`
    );
  }
});

/**
 * Test mapowania konkretnego klienta
 */
exports.testClientMapping = onCall({
  memory: "512MiB",
  timeoutSeconds: 60,
  region: "europe-west1",
}, async (request) => {
  const { excelId, clientName } = request.data || {};

  if (!excelId && !clientName) {
    throw new HttpsError('invalid-argument', 'Wymagane excelId lub clientName');
  }

  const db = admin.firestore();
  console.log(`🧪 [Test Mapping] Testowanie: Excel ID: ${excelId}, Nazwa: ${clientName}`);

  try {
    // Znajdź klienta
    let clientQuery;

    if (excelId) {
      clientQuery = await db.collection('clients')
        .where('excelId', '==', excelId)
        .limit(1)
        .get();
    }

    if (!clientQuery || clientQuery.empty) {
      clientQuery = await db.collection('clients')
        .where('imie_nazwisko', '==', clientName)
        .limit(1)
        .get();
    }

    if (clientQuery.empty) {
      return {
        success: false,
        message: 'Nie znaleziono klienta',
        searchCriteria: { excelId, clientName }
      };
    }

    const clientDoc = clientQuery.docs[0];
    const clientData = clientDoc.data();

    // Znajdź produkty tego klienta
    const productQueries = await Promise.all([
      db.collection('investments').where('id_klient', '==', excelId).get(),
      db.collection('bonds').where('ID_Klient', '==', excelId).get(),
      db.collection('shares').where('ID_Klient', '==', excelId).get(),
      db.collection('loans').where('ID_Klient', '==', excelId).get(),
      db.collection('apartments').where('ID_Klient', '==', excelId).get(),
    ]);

    const products = [];
    productQueries.forEach((query, index) => {
      const collections = ['investments', 'bonds', 'shares', 'loans', 'apartments'];
      query.docs.forEach(doc => {
        products.push({
          id: doc.id,
          collection: collections[index],
          data: doc.data()
        });
      });
    });

    return {
      success: true,
      client: {
        firestoreId: clientDoc.id,
        ...clientData
      },
      products: products,
      stats: {
        totalProducts: products.length,
        productsByCollection: {
          investments: productQueries[0].docs.length,
          bonds: productQueries[1].docs.length,
          shares: productQueries[2].docs.length,
          loans: productQueries[3].docs.length,
          apartments: productQueries[4].docs.length,
        }
      }
    };

  } catch (error) {
    console.error("❌ [Test Mapping] Błąd:", error);
    throw new HttpsError('internal', `Błąd testowania: ${error.message}`);
  }
});
