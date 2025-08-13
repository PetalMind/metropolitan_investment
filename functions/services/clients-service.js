/**
 * Clients Service
 * Obsługuje operacje związane z klientami z optymalizacją cache
 * Pobiera dane z kolekcji 'clients' i łączy z danymi inwestycji
 */

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const { db } = require("../utils/firebase-config");
const { getCachedResult, setCachedResult } = require("../utils/cache-utils");
const {
  safeToString,
  safeToDouble,
  parseDate,
} = require("../utils/data-mapping");

/**
 * Pobiera wszystkich klientów z paginacją i wyszukiwaniem
 */
exports.getAllClients = onCall({
  memory: "1GiB",
  timeoutSeconds: 300,
  region: "europe-west1",
  cors: true,
}, async (request) => {
  const startTime = Date.now();
  const {
    page = 1,
    pageSize = 10000, // ZWIĘKSZONY LIMIT z 500 do 10000
    searchQuery,
    sortBy = 'imie_nazwisko',
    forceRefresh = false
  } = request.data || {};

  const cacheKey = `getAllClients_${page}_${pageSize}_${searchQuery || 'all'}_${sortBy}`;

  try {
    // Sprawdź cache jeśli nie ma force refresh
    if (!forceRefresh) {
      const cached = getCachedResult(cacheKey);
      if (cached) {
        console.log(`✅ [getAllClients] Zwracam dane z cache (${Date.now() - startTime}ms)`);
        return {
          ...cached,
          source: 'cache',
          processingTime: Date.now() - startTime
        };
      }
    }

    // Pobierz klientów z Firestore
    let query = db.collection('clients');

    // Sprawdź czy kolekcja istnieje
    const testSnapshot = await query.limit(1).get();
    if (testSnapshot.empty) {
      return {
        clients: [],
        totalCount: 0,
        currentPage: page,
        pageSize: pageSize,
        hasNextPage: false,
        hasPreviousPage: false,
        source: 'firestore-empty',
        processingTime: Date.now() - startTime
      };
    }

    // Filtrowanie po wyszukiwanej frazie
    if (searchQuery &&
      searchQuery.trim() !== '' &&
      searchQuery.toLowerCase() !== 'null' &&
      searchQuery !== 'undefined') {
      const searchLower = searchQuery.trim().toLowerCase();

      // Pobierz wszystkich klientów i filtruj lokalnie (Firestore nie obsługuje złożonych zapytań tekstowych)
      const allClientsSnapshot = await query.get();
      let filteredClients = [];

      allClientsSnapshot.docs.forEach(doc => {
        const data = doc.data();
        const client = convertDocumentToClient(doc.id, data);

        // Sprawdź czy klient pasuje do wyszukiwania
        const matchesSearch =
          (client.name && client.name.toLowerCase().includes(searchLower)) ||
          (client.email && client.email.toLowerCase().includes(searchLower)) ||
          (client.phone && client.phone.toLowerCase().includes(searchLower)) ||
          (client.companyName && client.companyName.toLowerCase().includes(searchLower)) ||
          (client.excelId && client.excelId.toString().includes(searchLower));

        if (matchesSearch) {
          filteredClients.push(client);
        }
      });

      // Sortowanie
      filteredClients = sortClients(filteredClients, sortBy);

      // Paginacja
      const totalCount = filteredClients.length;
      const startIndex = (page - 1) * pageSize;
      const endIndex = Math.min(startIndex + pageSize, totalCount);
      const paginatedClients = filteredClients.slice(startIndex, endIndex);

      const result = {
        clients: paginatedClients,
        totalCount: totalCount,
        currentPage: page,
        pageSize: pageSize,
        hasNextPage: endIndex < totalCount,
        hasPreviousPage: page > 1,
        source: 'firestore-filtered',
        processingTime: Date.now() - startTime,
        debug: {
          searchQuery: searchQuery,
          searchLower: searchLower,
          allClientsCount: allClientsSnapshot.size,
          filteredCount: filteredClients.length,
          paginatedCount: paginatedClients.length
        }
      };

      // Cache wynik
      setCachedResult(cacheKey, result);

      console.log(`✅ [getAllClients] Zwracam ${paginatedClients.length}/${totalCount} klientów (${Date.now() - startTime}ms)`);
      return result;

    } else {
      // Bez filtrowania - użyj paginacji Firestore (uproszczona wersja)

      const totalSnapshot = await db.collection('clients').get();
      const totalCount = totalSnapshot.size;

      // Pobierz wszystkich klientów i zastosuj paginację lokalnie (prostsze i bardziej niezawodne)
      const allClientsSnapshot = await db.collection('clients').get();
      const allClients = [];

      allClientsSnapshot.docs.forEach(doc => {
        allClients.push(convertDocumentToClient(doc.id, doc.data()));
      });

      // Sortowanie lokalne
      const sortedClients = sortClients(allClients, sortBy);

      // Paginacja lokalna
      const startIndex = (page - 1) * pageSize;
      const endIndex = Math.min(startIndex + pageSize, sortedClients.length);
      const paginatedClients = sortedClients.slice(startIndex, endIndex);

      const result = {
        clients: paginatedClients,
        totalCount: totalCount,
        currentPage: page,
        pageSize: pageSize,
        hasNextPage: endIndex < totalCount,
        hasPreviousPage: page > 1,
        source: 'firestore-simple',
        processingTime: Date.now() - startTime,
        debug: {
          totalInDatabase: totalCount,
          afterConversion: allClients.length,
          afterPagination: paginatedClients.length,
          sortBy: sortBy
        }
      };

      // Cache wynik
      setCachedResult(cacheKey, result);

      console.log(`✅ [getAllClients] Zwracam ${clients.length}/${totalCount} klientów (${Date.now() - startTime}ms)`);
      return result;
    }

  } catch (error) {
    throw new HttpsError('internal', `Błąd podczas pobierania klientów: ${error.message}`);
  }
});

/**
 * Pobiera aktywnych klientów (mających inwestycje)
 */
exports.getActiveClients = onCall({
  memory: "1GiB",
  timeoutSeconds: 300,
  region: "europe-west1",
  cors: true,
}, async (request) => {
  const startTime = Date.now();
  const { forceRefresh = false } = request.data || {};
  const cacheKey = 'getActiveClients';

  try {
    // Sprawdź cache
    if (!forceRefresh) {
      const cached = getCachedResult(cacheKey);
      if (cached) {
        console.log(`✅ [getActiveClients] Zwracam dane z cache (${Date.now() - startTime}ms)`);
        return {
          ...cached,
          source: 'cache',
          processingTime: Date.now() - startTime
        };
      }
    }

    // Pobierz wszystkich klientów
    const clientsSnapshot = await db.collection('clients').get();

    // Pobierz wszystkie inwestycje aby zidentyfikować aktywnych klientów
    const investmentsSnapshot = await db.collection('investments').get();

    // Sprawdź czy kolekcje nie są puste
    if (clientsSnapshot.empty) {
      return {
        clients: [],
        totalActiveClients: 0,
        totalClients: 0,
        activityRate: 0,
        totalRemainingCapital: 0,
        source: 'firestore-empty',
        processingTime: Date.now() - startTime
      };
    }

    // Stwórz mapę clientId -> ma inwestycje
    const clientsWithInvestments = new Set();
    let totalRemainingCapital = 0;

    investmentsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const clientId = data.clientId;
      const remainingCapital = safeToDouble(data.remainingCapital || data.kapital_pozostaly);

      if (clientId && remainingCapital > 0) {
        clientsWithInvestments.add(clientId);
        totalRemainingCapital += remainingCapital;
      }
    });

    // Filtruj klientów z inwestycjami
    const activeClients = [];
    clientsSnapshot.docs.forEach(doc => {
      const clientId = doc.id;
      if (clientsWithInvestments.has(clientId)) {
        activeClients.push(convertDocumentToClient(clientId, doc.data()));
      }
    });

    // Sortuj alfabetycznie
    activeClients.sort((a, b) => a.name.localeCompare(b.name, 'pl'));

    const activityRate = clientsSnapshot.size > 0
      ? Math.round((activeClients.length / clientsSnapshot.size) * 100)
      : 0;

    const result = {
      clients: activeClients,
      totalActiveClients: activeClients.length,
      totalClients: clientsSnapshot.size,
      activityRate: activityRate,
      totalRemainingCapital: totalRemainingCapital,
      source: 'firestore-active',
      processingTime: Date.now() - startTime,
      debug: {
        clientsInDatabase: clientsSnapshot.size,
        investmentsInDatabase: investmentsSnapshot.size,
        clientsWithInvestmentsCount: clientsWithInvestments.size,
        activeClientsFiltered: activeClients.length
      }
    };

    // Cache wynik
    setCachedResult(cacheKey, result);

    console.log(`✅ [getActiveClients] Zwracam ${activeClients.length} aktywnych klientów z ${clientsSnapshot.size} (wskaźnik: ${activityRate}%, ${Date.now() - startTime}ms)`);
    return result;

  } catch (error) {
    throw new HttpsError('internal', `Błąd podczas pobierania aktywnych klientów: ${error.message}`);
  }
});

/**
 * Pobiera statystyki systemu (klienci i inwestycje)
 */
exports.getSystemStats = onCall({
  memory: "1GiB",
  timeoutSeconds: 300,
  region: "europe-west1",
  cors: true,
}, async (request) => {
  const startTime = Date.now();
  const { forceRefresh = false } = request.data || {};
  const cacheKey = 'getSystemStats';

  try {
    // Sprawdź cache
    if (!forceRefresh) {
      const cached = getCachedResult(cacheKey);
      if (cached) {
        console.log(`✅ [getSystemStats] Zwracam dane z cache (${Date.now() - startTime}ms)`);
        return {
          ...cached,
          source: 'cache',
          processingTime: Date.now() - startTime
        };
      }
    }

    // Pobierz dane równolegle
    const [clientsSnapshot, investmentsSnapshot] = await Promise.all([
      db.collection('clients').get(),
      db.collection('investments').get()
    ]);

    // Analiza klientów
    const totalClients = clientsSnapshot.size;
    const clientsWithInvestments = new Set();

    // Analiza inwestycji
    let totalInvestments = 0;
    let totalRemainingCapital = 0;
    let totalInvestmentAmount = 0;

    investmentsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const clientId = data.clientId;
      const remainingCapital = safeToDouble(data.remainingCapital || data.kapital_pozostaly);
      const investmentAmount = safeToDouble(data.investmentAmount || data.kwota_inwestycji);

      if (clientId && remainingCapital > 0) {
        clientsWithInvestments.add(clientId);
        totalRemainingCapital += remainingCapital;
        totalInvestmentAmount += investmentAmount;
        totalInvestments++;
      }
    });

    const activeClientsCount = clientsWithInvestments.size;
    const averageCapitalPerClient = activeClientsCount > 0
      ? totalRemainingCapital / activeClientsCount
      : 0;

    const averageInvestmentAmount = totalInvestments > 0
      ? totalInvestmentAmount / totalInvestments
      : 0;

    const result = {
      totalClients: totalClients,
      activeClients: activeClientsCount,
      totalInvestments: totalInvestments,
      totalRemainingCapital: Math.round(totalRemainingCapital * 100) / 100,
      totalInvestmentAmount: Math.round(totalInvestmentAmount * 100) / 100,
      averageCapitalPerClient: Math.round(averageCapitalPerClient * 100) / 100,
      averageInvestmentAmount: Math.round(averageInvestmentAmount * 100) / 100,
      activityRate: totalClients > 0 ? Math.round((activeClientsCount / totalClients) * 100) : 0,
      lastUpdated: new Date().toISOString(),
      source: 'firestore-stats',
      processingTime: Date.now() - startTime
    };

    // Cache wynik
    setCachedResult(cacheKey, result);

    console.log(`✅ [getSystemStats] Statystyki wygenerowane: ${totalClients} klientów, ${activeClientsCount} aktywnych, ${totalInvestments} inwestycji (${Date.now() - startTime}ms)`);
    return result;

  } catch (error) {
    throw new HttpsError('internal', `Błąd podczas generowania statystyk: ${error.message}`);
  }
});

/**
 * Konwertuje dokument Firestore do obiektu klienta
 */
function convertDocumentToClient(id, data) {
  return {
    id: id,
    excelId: data.excelId || data.original_id || data.id?.toString() || null,
    fullName: safeToString(data.fullName || data.imie_nazwisko || data.name), // Główne pole z Firebase
    imie_nazwisko: safeToString(data.fullName || data.imie_nazwisko || data.name), // Kompatybilność
    name: safeToString(data.fullName || data.imie_nazwisko || data.name), // Alias dla frontend
    email: safeToString(data.email),
    telefon: safeToString(data.telefon || data.phone),
    phone: safeToString(data.telefon || data.phone), // Alias
    address: safeToString(data.address),
    pesel: safeToString(data.pesel),
    nazwa_firmy: safeToString(data.nazwa_firmy || data.companyName),
    companyName: safeToString(data.nazwa_firmy || data.companyName), // Alias
    type: data.type || 'individual',
    notes: safeToString(data.notes),
    votingStatus: data.votingStatus || 'undecided',
    colorCode: data.colorCode || '#FFFFFF',
    unviableInvestments: Array.isArray(data.unviableInvestments) ? data.unviableInvestments : [],
    isActive: data.isActive !== false, // Domyślnie true
    createdAt: parseDate(data.createdAt) || parseDate(data.created_at) || new Date().toISOString(),
    updatedAt: parseDate(data.updatedAt) || parseDate(data.uploaded_at) || new Date().toISOString(),
    additionalInfo: data.additionalInfo || {}
  };
}

/**
 * Sortuje listę klientów według określonego pola
 */
function sortClients(clients, sortBy) {

  if (!clients || clients.length === 0) {
    return [];
  }

  // Sprawdź czy pierwsze kilka rekordów ma to pole
  const sampleClient = clients[0];
  const hasField = sampleClient[sortBy] !== undefined;

  if (!hasField) {
    console.log(`📋 [sortClients] Dostępne pola w pierwszym kliencie:`, Object.keys(sampleClient));
  }

  return clients.sort((a, b) => {
    let valueA = a[sortBy] || '';
    let valueB = b[sortBy] || '';

    if (typeof valueA === 'string') valueA = valueA.toLowerCase();
    if (typeof valueB === 'string') valueB = valueB.toLowerCase();

    if (valueA < valueB) return -1;
    if (valueA > valueB) return 1;
    return 0;
  });
}

module.exports = {
  getAllClients: exports.getAllClients,
  getActiveClients: exports.getActiveClients,
  getSystemStats: exports.getSystemStats,
};
