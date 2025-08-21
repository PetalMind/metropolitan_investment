const { db, admin } = require('../utils/firebase-config');
const { logError, logInfo } = require('../utils/logger');
const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");

/**
 * 🚀 ENHANCED CLIENTS SERVICE
 * 
 * Obsługuje zaawansowane ładowanie klientów z pełnymi danymi
 * Optymalizuje pobieranie dużej liczby klientów po stronie serwera
 */

/**
 * Pobiera pełne dane klientów na podstawie listy client IDs z OptimizedInvestor
 * @param {Array<string>} clientIds - Lista ID klientów (excelId lub UUID)
 * @param {Object} options - Opcje pobierania
 * @returns {Promise<Object>} - Wynik z pełnymi danymi klientów i statystykami
 */
async function getEnhancedClientsData(clientIds, options = {}) {
  const startTime = Date.now();
  logInfo('Enhanced Clients Service', `Rozpoczynam pobieranie ${clientIds.length} klientów`);

  try {
    const {
      includeStatistics = true,
      maxClients = 1000,
      batchSize = 50
    } = options;

    // Zabezpieczenie przed zbyt dużą liczbą klientów
    const limitedClientIds = clientIds.slice(0, maxClients);
    if (clientIds.length > maxClients) {
      logInfo('Enhanced Clients Service', `Ograniczono do ${maxClients} klientów (było ${clientIds.length})`);
    }

    const clients = [];
    const notFoundIds = [];

    // KROK 1: Pobierz klientów w batch'ach po excelId (najczęstszy przypadek)
    logInfo('Enhanced Clients Service', 'KROK 1: Szukam po excelId...');
    
    for (let i = 0; i < limitedClientIds.length; i += batchSize) {
      const batch = limitedClientIds.slice(i, i + batchSize);
      
      try {
        const snapshot = await db
            .collection('clients')
            .where(admin.firestore.FieldPath.documentId(), 'in', batch)
            .get();

        logInfo('Enhanced Clients Service', `Batch ${Math.floor(i/batchSize) + 1}: znaleziono ${snapshot.docs.length}/${batch.length} po excelId`);

        snapshot.docs.forEach(doc => {
          const clientData = doc.data();
          clients.push({
            id: doc.id,
            ...clientData,
            documentId: doc.id,
          });
        });

        // Znajdź brakujących klientów w tym batch'u
        const foundExcelIds = snapshot.docs.map(doc => doc.data().excelId || doc.data().original_id);
        const missingInBatch = batch.filter(id => !foundExcelIds.includes(id));
        notFoundIds.push(...missingInBatch);

      } catch (batchError) {
        logError('Enhanced Clients Service', `Błąd batch ${Math.floor(i/batchSize) + 1}: ${batchError.message}`);
        notFoundIds.push(...batch);
      }
    }

    // KROK 2: Dla brakujących ID, spróbuj przez document ID (UUID)
    if (notFoundIds.length > 0) {
      logInfo('Enhanced Clients Service', `KROK 2: Szukam ${notFoundIds.length} brakujących po document ID...`);
      
      for (let i = 0; i < notFoundIds.length; i += batchSize) {
        const batch = notFoundIds.slice(i, i + batchSize);
        
        try {
          const excelSnapshot = await db
              .collection('clients')
              .where('excelId', '==', missingId)
              .limit(1)
              .get();          logInfo('Enhanced Clients Service', `UUID Batch ${Math.floor(i/batchSize) + 1}: znaleziono ${snapshot.docs.length}/${batch.length} po document ID`);

          snapshot.docs.forEach(doc => {
            const clientData = doc.data();
            clients.push({
              id: doc.id,
              ...clientData,
              documentId: doc.id,
            });
          });

        } catch (batchError) {
          logError('Enhanced Clients Service', `Błąd UUID batch ${Math.floor(i/batchSize) + 1}: ${batchError.message}`);
        }
      }
    }

    // KROK 3: Oblicz statystyki (opcjonalnie)
    let statistics = null;
    if (includeStatistics && clients.length > 0) {
      logInfo('Enhanced Clients Service', 'KROK 3: Obliczam statystyki...');
      
      statistics = {
        totalClients: clients.length,
        activeClients: clients.filter(c => c.isActive !== false).length,
        clientsWithEmail: clients.filter(c => c.email && c.email.trim() !== '').length,
        clientsWithPhone: clients.filter(c => (c.phone || c.telefon) && (c.phone || c.telefon).trim() !== '').length,
        clientTypes: {
          individual: clients.filter(c => c.type === 'individual').length,
          company: clients.filter(c => c.type === 'company').length,
          marriage: clients.filter(c => c.type === 'marriage').length,
          other: clients.filter(c => c.type === 'other').length,
        },
        votingStatus: {
          undecided: clients.filter(c => !c.votingStatus || c.votingStatus === 'undecided').length,
          yes: clients.filter(c => c.votingStatus === 'yes').length,
          no: clients.filter(c => c.votingStatus === 'no').length,
          abstain: clients.filter(c => c.votingStatus === 'abstain').length,
        }
      };
    }

    const duration = Date.now() - startTime;
    const result = {
      success: true,
      clients,
      statistics,
      meta: {
        requestedCount: clientIds.length,
        foundCount: clients.length,
        notFoundCount: clientIds.length - clients.length,
        duration: `${duration}ms`,
        source: 'enhanced-clients-service',
        timestamp: new Date().toISOString(),
      }
    };

    logInfo('Enhanced Clients Service', `✅ Zakończono w ${duration}ms:`);
    logInfo('Enhanced Clients Service', `   - Żądano: ${clientIds.length} klientów`);
    logInfo('Enhanced Clients Service', `   - Znaleziono: ${clients.length} klientów`);
    logInfo('Enhanced Clients Service', `   - Brakuje: ${clientIds.length - clients.length} klientów`);

    return result;

  } catch (error) {
    const duration = Date.now() - startTime;
    logError('Enhanced Clients Service', `❌ Błąd po ${duration}ms: ${error.message}`);
    
    return {
      success: false,
      error: error.message,
      clients: [],
      statistics: null,
      meta: {
        requestedCount: clientIds.length,
        foundCount: 0,
        notFoundCount: clientIds.length,
        duration: `${duration}ms`,
        source: 'enhanced-clients-service',
        timestamp: new Date().toISOString(),
      }
    };
  }
}

/**
 * Pobiera wszystkich aktywnych klientów z podstawowymi statystykami
 * @param {Object} options - Opcje pobierania
 * @returns {Promise<Object>} - Wynik z klientami i statystykami
 */
async function getAllActiveClients(options = {}) {
  const startTime = Date.now();
  logInfo('Enhanced Clients Service', 'Rozpoczynam pobieranie wszystkich aktywnych klientów');

  try {
    const {
      limit = 10000,
      includeInactive = false
    } = options;

    let query = db.collection('clients');
    
    if (!includeInactive) {
      query = query.where('isActive', '==', true);
    }
    
    query = query.limit(limit);
    
    const snapshot = await query.get();
    
    const clients = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      documentId: doc.id,
    }));

    // Oblicz statystyki
    const statistics = {
      totalClients: clients.length,
      activeClients: clients.filter(c => c.isActive !== false).length,
      clientsWithEmail: clients.filter(c => c.email && c.email.trim() !== '').length,
      clientsWithPhone: clients.filter(c => (c.phone || c.telefon) && (c.phone || c.telefon).trim() !== '').length,
      clientTypes: {
        individual: clients.filter(c => c.type === 'individual').length,
        company: clients.filter(c => c.type === 'company').length,
        marriage: clients.filter(c => c.type === 'marriage').length,
        other: clients.filter(c => c.type === 'other').length,
      },
      votingStatus: {
        undecided: clients.filter(c => !c.votingStatus || c.votingStatus === 'undecided').length,
        yes: clients.filter(c => c.votingStatus === 'yes').length,
        no: clients.filter(c => c.votingStatus === 'no').length,
        abstain: clients.filter(c => c.votingStatus === 'abstain').length,
      }
    };

    const duration = Date.now() - startTime;
    
    logInfo('Enhanced Clients Service', `✅ Pobrano ${clients.length} aktywnych klientów w ${duration}ms`);

    return {
      success: true,
      clients,
      statistics,
      meta: {
        foundCount: clients.length,
        duration: `${duration}ms`,
        source: 'enhanced-clients-service-all',
        timestamp: new Date().toISOString(),
      }
    };

  } catch (error) {
    const duration = Date.now() - startTime;
    logError('Enhanced Clients Service', `❌ Błąd pobierania wszystkich klientów po ${duration}ms: ${error.message}`);
    
    return {
      success: false,
      error: error.message,
      clients: [],
      statistics: null,
      meta: {
        foundCount: 0,
        duration: `${duration}ms`,
        source: 'enhanced-clients-service-all',
        timestamp: new Date().toISOString(),
      }
    };
  }
}

/**
 * Firebase Function: getEnhancedClients
 * Pobiera pełne dane klientów na podstawie listy client IDs z OptimizedInvestor
 */
exports.getEnhancedClients = onCall({
  memory: "2GiB",
  timeoutSeconds: 540,
  region: "europe-west1",
  cors: true,
}, async (request) => {
  try {
    const { clientIds, options = {} } = request.data || {};
    
    if (!clientIds || !Array.isArray(clientIds)) {
      throw new HttpsError('invalid-argument', 'clientIds musi być tablicą ID klientów');
    }

    const result = await getEnhancedClientsData(clientIds, options);
    return result;

  } catch (error) {
    logError('getEnhancedClients', error.message);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError('internal', error.message);
  }
});

/**
 * Firebase Function: getAllActiveClientsFunction
 * Pobiera wszystkich aktywnych klientów z podstawowymi statystykami
 */
exports.getAllActiveClientsFunction = onCall({
  memory: "2GiB",
  timeoutSeconds: 540,
  region: "europe-west1",
  cors: true,
}, async (request) => {
  try {
    const { options = {} } = request.data || {};
    
    const result = await getAllActiveClients(options);
    return result;

  } catch (error) {
    logError('getAllActiveClientsFunction', error.message);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError('internal', error.message);
  }
});

module.exports = {
  getEnhancedClientsData,
  getAllActiveClients,
  
  // Firebase Functions exports
  getEnhancedClients: exports.getEnhancedClients,
  getAllActiveClientsFunction: exports.getAllActiveClientsFunction,
};
