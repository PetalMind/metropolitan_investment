/**
 * getAllInvestments Service
 * Funkcja Firebase do pobierania inwestycji z obsługą CORS
 */

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const { db } = require("../utils/firebase-config");
const { getCachedResult, setCachedResult } = require("../utils/cache-utils");
const {
  safeToDouble,
  safeToString,
  parseDate,
  mapProductType,
  mapProductStatus
} = require("../utils/data-mapping");
const {
  calculateCapitalSecuredByRealEstate,
  getUnifiedField
} = require("../utils/unified-statistics");

/**
 * Konwertuje dokument Investment na format zgodny z aplikacją
 */
function convertInvestmentData(doc) {
  const data = doc.data();
  const id = doc.id;

  // NOWY: Oblicz dynamicznie kapitał zabezpieczony nieruchomością
  const capitalSecuredByRealEstate = calculateCapitalSecuredByRealEstate(data);
  const capitalForRestructuring = getUnifiedField(data, 'capitalForRestructuring');

  return {
    id: id,
    clientId: safeToString(data.clientId),
    clientName: safeToString(data.clientName || data.inwestor_imie_nazwisko),
    productName: safeToString(data.productName || data.projectName || `Produkt ${id}`),
    productType: mapProductType(data.productType),
    investmentAmount: safeToDouble(data.investmentAmount || data.kwota_inwestycji),
    remainingCapital: safeToDouble(data.remainingCapital || data.kapital_pozostaly),
    totalValue: safeToDouble(data.totalValue || data.investmentAmount),
    contractDate: parseDate(data.contractDate || data.data_kontraktu),
    createdAt: parseDate(data.createdAt) || new Date().toISOString(),
    status: mapProductStatus(data.status || data.productStatus || 'active'),
    isActive: true,

    // NOWY: Dynamicznie obliczone pola kapitałowe
    capitalSecuredByRealEstate: capitalSecuredByRealEstate, // Obliczone dynamicznie
    capitalForRestructuring: capitalForRestructuring, // Z bazy danych

    // Dodatkowe pola specyficzne dla różnych typów produktów
    interestRate: safeToDouble(data.interestRate || data.stopa_procentowa),
    maturityDate: parseDate(data.maturityDate || data.data_wygasniecia),
    location: safeToString(data.location || data.lokalizacja),

    // Metadata
    sourceFile: safeToString(data.sourceFile || 'investments_collection'),
    uploadedAt: parseDate(data.uploadedAt) || new Date().toISOString(),
  };
}

/**
 * Pobiera wszystkie inwestycje z kolekcji 'investments'
 */
const getAllInvestments = onCall({
  region: 'europe-west1',
  cors: true,
  memory: '512MB',
}, async (request) => {
  const startTime = Date.now();

  try {
    console.log('🚀 [getAllInvestments] Rozpoczynam pobieranie inwestycji');

    const {
      page = 1,
      pageSize = 500,
      clientFilter,
      productTypeFilter,
      sortBy = 'contractDate',
      forceRefresh = false,
    } = request.data || {};

    // Tworzenie cache key
    const cacheKey = `getAllInvestments_${page}_${pageSize}_${clientFilter || 'all'}_${productTypeFilter || 'all'}_${sortBy}`;

    // Sprawdź cache jeśli nie wymuszone odświeżanie
    if (!forceRefresh) {
      const cachedResult = await getCachedResult(cacheKey);
      if (cachedResult) {
        console.log('📋 [getAllInvestments] Zwracam z cache');
        return cachedResult;
      }
    }

    // Buduj zapytanie do kolekcji investments
    let query = db.collection('investments');

    // Filtry
    if (clientFilter && clientFilter.trim()) {
      // Można wyszukiwać po ID klienta lub nazwie
      query = query.where('clientId', '==', clientFilter);
    }

    if (productTypeFilter && productTypeFilter.trim()) {
      query = query.where('productType', '==', productTypeFilter);
    }

    // Sortowanie
    let orderByField = 'createdAt';
    let orderDirection = 'desc';

    switch (sortBy) {
      case 'data_kontraktu':
      case 'contractDate':
        orderByField = 'contractDate';
        break;
      case 'kwota_inwestycji':
      case 'investmentAmount':
        orderByField = 'investmentAmount';
        break;
      case 'clientName':
        orderByField = 'clientName';
        orderDirection = 'asc';
        break;
      case 'productName':
        orderByField = 'productName';
        orderDirection = 'asc';
        break;
    }

    // Dodaj sortowanie do zapytania
    query = query.orderBy(orderByField, orderDirection);

    // Pobierz dane (bez paginacji na razie - można dodać później)
    console.log('💾 [getAllInvestments] Wykonuję zapytanie do Firestore...');
    const querySnapshot = await query.get();

    console.log(`📊 [getAllInvestments] Pobrano ${querySnapshot.size} dokumentów`);

    // Konwertuj dokumenty
    const investments = [];
    querySnapshot.forEach(doc => {
      try {
        const investment = convertInvestmentData(doc);
        investments.push(investment);
      } catch (convertError) {
        console.error(`❌ [getAllInvestments] Błąd konwersji dokumentu ${doc.id}:`, convertError);
        // Pomiń błędny dokument ale kontynuuj
      }
    });

    // Paginacja na poziomie aplikacji (dla prostoty)
    const totalCount = investments.length;
    const startIndex = (page - 1) * pageSize;
    const endIndex = Math.min(startIndex + pageSize, totalCount);
    const paginatedInvestments = investments.slice(startIndex, endIndex);

    const result = {
      investments: paginatedInvestments,
      pagination: {
        currentPage: page,
        pageSize: pageSize,
        totalItems: totalCount,
        totalPages: Math.ceil(totalCount / pageSize),
        hasNext: endIndex < totalCount,
        hasPrevious: page > 1,
      },
      metadata: {
        timestamp: new Date().toISOString(),
        executionTime: Date.now() - startTime,
        region: 'europe-west1',
        filters: {
          clientFilter,
          productTypeFilter,
          sortBy,
        },
      },
    };

    // Cache wyników na 5 minut
    await setCachedResult(cacheKey, result, 300);

    console.log(`✅ [getAllInvestments] Zakończono w ${Date.now() - startTime}ms, zwracam ${paginatedInvestments.length} inwestycji`);
    return result;

  } catch (error) {
    console.error('❌ [getAllInvestments] Błąd pobierania inwestycji:', error);
    throw new HttpsError(
      'internal',
      'Nie udało się pobrać inwestycji',
      {
        message: error.message,
        code: 'GET_INVESTMENTS_ERROR',
        timestamp: new Date().toISOString(),
      }
    );
  }
});

module.exports = {
  getAllInvestments,
};
