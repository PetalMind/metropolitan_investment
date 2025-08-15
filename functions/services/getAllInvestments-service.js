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
 * UPDATED: Enhanced support for normalized JSON data import
 */
function convertInvestmentData(doc) {
  const data = doc.data();
  const id = doc.id;

  console.log(`🔍 [convertInvestmentData] Processing investment ${id}:`, {
    productType: data.productType,
    clientName: data.clientName,
    investmentAmount: data.investmentAmount,
    hasId: !!data.id,
    logicalId: data.id
  });

  // NOWY: Oblicz dynamicznie kapitał zabezpieczony nieruchomością
  const capitalSecuredByRealEstate = calculateCapitalSecuredByRealEstate(data);
  const capitalForRestructuring = getUnifiedField(data, 'capitalForRestructuring');

  return {
    // 🚀 ENHANCED: Support for logical IDs from normalized import
    id: data.id || id, // Preferuj logiczne ID (bond_0001, apartment_0045) nad UUID

    // Client information - enhanced field mapping
    clientId: safeToString(data.clientId || data.ID_Klient || data.id_klient),
    clientName: safeToString(
      data.clientName ||
      data.inwestor_imie_nazwisko ||
      data.Klient ||
      data.klient ||
      `Klient ${data.clientId || id}`
    ),

    // Product information - enhanced field mapping
    productName: safeToString(
      data.productName ||
      data.projectName ||
      data.Produkt_nazwa ||
      data.nazwa_produktu ||
      `${mapProductType(data.productType)} ${id}`
    ),
    productType: mapProductType(data.productType || data.Typ_produktu || data.typ_produktu),

    // Financial information - support for Polish field names and comma formatting
    investmentAmount: safeToDouble(
      data.investmentAmount ||
      data.kwota_inwestycji ||
      data.Kwota_inwestycji ||
      data.paymentAmount
    ),
    remainingCapital: safeToDouble(
      data.remainingCapital ||
      data.kapital_pozostaly ||
      data['Kapital Pozostaly'] ||
      data.realizedCapital // fallback for some data formats
    ),
    totalValue: safeToDouble(
      data.totalValue ||
      data.investmentAmount ||
      data.kwota_inwestycji ||
      data.paymentAmount
    ),

    // Date fields - support for multiple formats
    contractDate: parseDate(
      data.contractDate ||
      data.signedDate ||
      data.data_kontraktu ||
      data.Data_podpisania ||
      data.signingDate
    ),
    createdAt: parseDate(data.createdAt) || new Date().toISOString(),

    // Status mapping - enhanced for normalized data
    status: mapProductStatus(
      data.status ||
      data.productStatus ||
      data.Status_produktu ||
      data.status_produktu ||
      'Aktywny'
    ),
    isActive: true,

    // 🚀 ENHANCED: Dynamic capital calculations from normalized data
    capitalSecuredByRealEstate: capitalSecuredByRealEstate,
    capitalForRestructuring: capitalForRestructuring,

    // Additional product-specific fields
    interestRate: safeToDouble(data.interestRate || data.stopa_procentowa || data.oprocentowanie),
    maturityDate: parseDate(data.maturityDate || data.data_wygasniecia || data.redemptionDate),
    location: safeToString(data.location || data.lokalizacja || data.address),

    // Company/Advisor information
    advisor: safeToString(data.advisor || data.opiekun || data['Opiekun z MISA']),
    branch: safeToString(data.branch || data.oddzial || data.Oddzial),
    companyId: safeToString(data.companyId || data.ID_Spolka || data.spolka_id),
    creditorCompany: safeToString(data.creditorCompany || data.wierzyciel_spolka),

    // 🚀 ENHANCED: Additional fields from normalized JSON import
    saleId: safeToString(data.saleId || data.ID_Sprzedaz), // 🚀 ENHANCED: Sale ID
    projectName: safeToString(data.projectName || ''), // 🚀 ENHANCED: Project name for apartments
    marketEntry: safeToString(data.marketEntry || ''), // 🚀 ENHANCED: Market entry type
    investmentEntryDate: parseDate(data.investmentEntryDate), // 🚀 ENHANCED: Investment entry date
    shareCount: safeToString(data.shareCount || ''), // 🚀 ENHANCED: Share count for shares

    // Enhanced metadata
    sourceFile: safeToString(data.sourceFile || 'investments_collection'),
    uploadedAt: parseDate(data.uploadedAt) || new Date().toISOString(),

    // Raw data for debugging
    __debugInfo: {
      originalId: id,
      logicalId: data.id,
      hasLogicalId: !!data.id,
      originalFields: Object.keys(data).slice(0, 10) // First 10 fields for debugging
    }
  };
}

/**
 * Pobiera wszystkie inwestycje z kolekcji 'investments'
 * ENHANCED: Better support for normalized JSON import and debugging
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
      pageSize = 5000,
      clientFilter,
      productTypeFilter,
      sortBy = 'contractDate',
      forceRefresh = false,
      includeDebugInfo = false, // 🚀 NEW: Debug information flag
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

    // 🚀 DIAGNOSTIC: Check collection existence and sample data
    console.log('🔍 [getAllInvestments] Sprawdzam kolekcję investments...');
    const collectionRef = db.collection('investments');

    // Get collection info
    const sampleQuery = await collectionRef.limit(5).get();
    console.log(`📊 [getAllInvestments] Sample query returned ${sampleQuery.size} documents`);

    if (sampleQuery.size > 0) {
      const sampleDoc = sampleQuery.docs[0];
      const sampleData = sampleDoc.data();
      console.log('🔍 [getAllInvestments] Sample document structure:', {
        id: sampleDoc.id,
        logicalId: sampleData.id,
        productType: sampleData.productType,
        clientName: sampleData.clientName,
        investmentAmount: sampleData.investmentAmount,
        fieldCount: Object.keys(sampleData).length,
        topFields: Object.keys(sampleData).slice(0, 10)
      });
    }

    // Buduj zapytanie do kolekcji investments
    let query = db.collection('investments');

    // Filtry
    if (clientFilter && clientFilter.trim()) {
      // 🚀 ENHANCED: Search by both logical clientId and document clientId field
      console.log(`🔍 [getAllInvestments] Filtruje po kliencie: ${clientFilter}`);
      query = query.where('clientId', '==', clientFilter);
    }

    if (productTypeFilter && productTypeFilter.trim()) {
      console.log(`🔍 [getAllInvestments] Filtruje po typie produktu: ${productTypeFilter}`);
      query = query.where('productType', '==', productTypeFilter);
    }

    // Sortowanie - enhanced to handle missing fields gracefully
    let orderByField = 'createdAt';
    let orderDirection = 'desc';

    switch (sortBy) {
      case 'data_kontraktu':
      case 'contractDate':
      case 'signedDate':
        orderByField = 'createdAt'; // Fallback to createdAt if signedDate doesn't exist
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

    console.log(`🔍 [getAllInvestments] Sortowanie: ${orderByField} ${orderDirection}`);

    // Pobierz dane (bez paginacji na razie - można dodać później)
    console.log('💾 [getAllInvestments] Wykonuję zapytanie do Firestore...');
    const querySnapshot = await query.get();

    console.log(`📊 [getAllInvestments] Pobrano ${querySnapshot.size} dokumentów`);

    // 🚀 ENHANCED: Collection diagnostic information
    if (querySnapshot.size === 0) {
      console.error('🚫 [getAllInvestments] BRAK DOKUMENTÓW w kolekcji investments!');

      // Check if collection exists at all
      const allCollections = await db.listCollections();
      const collectionNames = allCollections.map(c => c.id);
      console.log('📋 [getAllInvestments] Dostępne kolekcje:', collectionNames);

      return {
        investments: [],
        pagination: {
          currentPage: page,
          pageSize: pageSize,
          totalItems: 0,
          totalPages: 0,
          hasNext: false,
          hasPrevious: false,
        },
        metadata: {
          timestamp: new Date().toISOString(),
          executionTime: Date.now() - startTime,
          region: 'europe-west1',
          filters: { clientFilter, productTypeFilter, sortBy },
          diagnostic: {
            error: 'NO_DOCUMENTS_FOUND',
            availableCollections: collectionNames,
            suggestion: 'Check if investment data was properly imported'
          }
        },
      };
    }

    // Konwertuj dokumenty
    const investments = [];
    let conversionErrors = 0;

    querySnapshot.forEach(doc => {
      try {
        const investment = convertInvestmentData(doc);
        investments.push(investment);
      } catch (convertError) {
        conversionErrors++;
        console.error(`❌ [getAllInvestments] Błąd konwersji dokumentu ${doc.id}:`, convertError);

        if (includeDebugInfo) {
          // Include failed conversion info in debug mode
          investments.push({
            id: doc.id,
            __error: convertError.message,
            __rawData: doc.data()
          });
        }
      }
    });

    console.log(`📊 [getAllInvestments] Skonwertowano ${investments.length} inwestycji, błędów konwersji: ${conversionErrors}`);

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
        diagnostic: {
          totalDocuments: querySnapshot.size,
          conversionErrors: conversionErrors,
          successfulConversions: investments.length - conversionErrors,
          cacheUsed: false
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
        stack: error.stack?.split('\n').slice(0, 5) // First 5 lines of stack trace
      }
    );
  }
});

/**
 * Funkcja diagnostyczna - sprawdza stan kolekcji investments
 * NEW: Diagnostic function for troubleshooting investment data
 */
const diagnosticInvestments = onCall({
  region: 'europe-west1',
  cors: true,
  memory: '256MB',
}, async (request) => {
  try {
    console.log('🔍 [diagnosticInvestments] Rozpoczynam diagnozę kolekcji investments');

    const { sampleSize = 5, checkIndexes = false } = request.data || {};

    const diagnostic = {
      timestamp: new Date().toISOString(),
      region: 'europe-west1',
      collection: 'investments'
    };

    // 1. Check collection existence and basic stats
    const collectionRef = db.collection('investments');
    const countQuery = await collectionRef.count().get();
    diagnostic.totalDocuments = countQuery.data().count;

    console.log(`📊 [diagnosticInvestments] Total documents: ${diagnostic.totalDocuments}`);

    if (diagnostic.totalDocuments === 0) {
      diagnostic.status = 'EMPTY_COLLECTION';
      diagnostic.message = 'Kolekcja investments jest pusta lub nie istnieje';
      diagnostic.suggestions = [
        'Sprawdź czy dane zostały zaimportowane',
        'Uruchom skrypt importu: npm run import-investments:full',
        'Sprawdź logi importu pod kątem błędów'
      ];
      return diagnostic;
    }

    // 2. Sample document analysis
    const sampleQuery = await collectionRef.limit(sampleSize).get();
    diagnostic.sampleDocuments = [];

    sampleQuery.docs.forEach(doc => {
      const data = doc.data();
      diagnostic.sampleDocuments.push({
        id: doc.id,
        logicalId: data.id,
        productType: data.productType,
        clientId: data.clientId,
        clientName: data.clientName,
        investmentAmount: data.investmentAmount,
        fieldCount: Object.keys(data).length,
        hasLogicalId: !!data.id,
        sourceFile: data.sourceFile
      });
    });

    // 3. Product type distribution
    const productTypeQuery = await collectionRef.get();
    const productTypeCounts = {};
    const sourceFileCounts = {};
    const statusCounts = {};

    productTypeQuery.docs.forEach(doc => {
      const data = doc.data();

      // Product type distribution
      const productType = data.productType || 'Unknown';
      productTypeCounts[productType] = (productTypeCounts[productType] || 0) + 1;

      // Source file distribution
      const sourceFile = data.sourceFile || 'Unknown';
      sourceFileCounts[sourceFile] = (sourceFileCounts[sourceFile] || 0) + 1;

      // Status distribution
      const status = data.productStatus || data.status || 'Unknown';
      statusCounts[status] = (statusCounts[status] || 0) + 1;
    });

    diagnostic.distribution = {
      productTypes: productTypeCounts,
      sourceFiles: sourceFileCounts,
      statuses: statusCounts
    };

    // 4. Data quality checks
    const qualityIssues = [];
    let documentsWithLogicalIds = 0;
    let documentsWithClientIds = 0;
    let documentsWithAmounts = 0;

    diagnostic.sampleDocuments.forEach(doc => {
      if (doc.hasLogicalId) documentsWithLogicalIds++;
      if (doc.clientId) documentsWithClientIds++;
      if (doc.investmentAmount > 0) documentsWithAmounts++;

      if (!doc.productType || doc.productType === 'Unknown') {
        qualityIssues.push(`Document ${doc.id}: Missing productType`);
      }
      if (!doc.clientId) {
        qualityIssues.push(`Document ${doc.id}: Missing clientId`);
      }
      if (!doc.investmentAmount || doc.investmentAmount <= 0) {
        qualityIssues.push(`Document ${doc.id}: Invalid investmentAmount`);
      }
    });

    diagnostic.dataQuality = {
      documentsWithLogicalIds: `${documentsWithLogicalIds}/${sampleSize}`,
      documentsWithClientIds: `${documentsWithClientIds}/${sampleSize}`,
      documentsWithAmounts: `${documentsWithAmounts}/${sampleSize}`,
      issues: qualityIssues.slice(0, 10) // Limit to 10 issues
    };

    // 5. Overall status
    if (qualityIssues.length === 0) {
      diagnostic.status = 'HEALTHY';
      diagnostic.message = 'Kolekcja investments wygląda na prawidłową';
    } else if (qualityIssues.length < sampleSize) {
      diagnostic.status = 'MINOR_ISSUES';
      diagnostic.message = 'Kolekcja ma drobne problemy z jakością danych';
    } else {
      diagnostic.status = 'MAJOR_ISSUES';
      diagnostic.message = 'Kolekcja ma poważne problemy z jakością danych';
    }

    console.log(`✅ [diagnosticInvestments] Diagnoza zakończona, status: ${diagnostic.status}`);
    return diagnostic;

  } catch (error) {
    console.error('❌ [diagnosticInvestments] Błąd diagnozy:', error);
    throw new HttpsError(
      'internal',
      'Nie udało się przeprowadzić diagnozy',
      {
        message: error.message,
        code: 'DIAGNOSTIC_ERROR',
        timestamp: new Date().toISOString(),
      }
    );
  }
});

module.exports = {
  getAllInvestments,
  diagnosticInvestments, // 🚀 NEW: Diagnostic function
};
