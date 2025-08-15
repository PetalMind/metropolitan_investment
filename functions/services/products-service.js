/**
 * Products Service
 * Obsługuje pobieranie i przetwarzanie produktów TYLKO z kolekcji 'investments'
 * 
 * UWAGA: Stare kolekcje (bonds, shares, loans, apartments, products) są deprecated
 * Wszystkie dane produktów znajdują się teraz w kolekcji 'investments'
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

/**
 * Konwertuje dokument z kolekcji 'investments' na UnifiedProduct
 * UPDATED: Enhanced field mapping for normalized JSON import data
 */
function convertInvestmentToUnifiedProduct(doc) {
  const data = doc.data();
  const id = doc.id;

  // Enhanced product type mapping
  const productType = mapProductType(data.productType || data.Typ_produktu || data.typ_produktu);
  const status = mapProductStatus(data.status || data.productStatus || data.Status_produktu);

  return {
    // 🚀 ENHANCED: Support logical IDs from normalized import
    id: data.id || id, // Prefer logical ID (bond_0001, apartment_0045) over UUID

    // Product identification - enhanced field mapping
    name: safeToString(
      data.productName ||
      data.projectName ||
      data.Produkt_nazwa ||
      data.nazwa_produktu ||
      `${getProductTypeName(productType)} ${data.id || id}`
    ),
    productType: productType,
    productTypeName: getProductTypeName(productType),

    // Financial information - support Polish field names and comma formatting
    investmentAmount: safeToDouble(
      data.investmentAmount ||
      data.paidAmount ||
      data.paymentAmount ||
      data.kwota_inwestycji ||
      data.Kwota_inwestycji
    ),
    totalValue: calculateTotalValue(data),

    // Date fields - enhanced date parsing
    createdAt: parseDate(
      data.createdAt ||
      data.signingDate ||
      data.signedDate ||
      data.Data_podpisania ||
      data.data_podpisania
    ) || new Date().toISOString(),
    uploadedAt: parseDate(data.uploadedAt) || new Date().toISOString(),

    // Source and status
    sourceFile: safeToString(data.sourceFile || 'investments_collection'),
    status: status,
    isActive: status === 'active' || status === 'Aktywny',

    // Company/Client information - enhanced field mapping
    companyName: safeToString(
      data.companyId ||
      data.creditorCompany ||
      data.ID_Spolka ||
      data.spolka_id
    ),
    companyId: safeToString(data.companyId || data.ID_Spolka),
    clientId: safeToString(data.clientId || data.ID_Klient || data.id_klient),
    clientName: safeToString(
      data.clientName ||
      data.Klient ||
      data.klient
    ),

    // Financial details - enhanced field mapping
    realizedCapital: safeToDouble(
      data.realizedCapital ||
      data.kapital_zrealizowany ||
      data['Kapital zrealizowany']
    ),
    remainingCapital: safeToDouble(
      data.remainingCapital ||
      data.kapital_pozostaly ||
      data['Kapital Pozostaly'] ||
      data.realEstateSecuredCapital
    ),
    currency: 'PLN',

    // Enhanced date fields
    deliveryDate: parseDate(data.deliveryDate || data.data_dostawy),
    redemptionDate: parseDate(
      data.redemptionDate ||
      data.data_wykupu ||
      data.redemptionDate
    ),
    signedDate: parseDate(
      data.signingDate ||
      data.signedDate ||
      data.Data_podpisania ||
      data.data_podpisania
    ),

    // Type-specific fields based on normalized data structure
    ...getTypeSpecificFields(productType, data),

    // Enhanced metadata with debug information
    additionalInfo: {
      ...data,
      originalCollection: 'investments',
      migrationSource: data.migrationSource || 'normalized_json_import',
      dataVersion: data.dataVersion || '2025.01',
      logicalId: data.id, // Store logical ID for reference
      hasLogicalId: !!data.id,
    }
  };
}

/**
 * Oblicza całkowitą wartość produktu
 * UPDATED: Enhanced calculation for normalized JSON data
 */
function calculateTotalValue(data) {
  // Try different investment amount fields from normalized data
  const investmentAmount = safeToDouble(
    data.investmentAmount ||
    data.paidAmount ||
    data.paymentAmount ||
    data.kwota_inwestycji ||
    data.Kwota_inwestycji
  );

  // Try different remaining capital fields
  const remainingCapital = safeToDouble(
    data.remainingCapital ||
    data.kapital_pozostaly ||
    data['Kapital Pozostaly'] ||
    data.realEstateSecuredCapital
  );

  // Try realized capital fields
  const realizedCapital = safeToDouble(
    data.realizedCapital ||
    data.kapital_zrealizowany ||
    data['Kapital zrealizowany']
  );

  // Calculation priority:
  // 1. If we have remaining + realized capital, use that
  if (remainingCapital > 0 || realizedCapital > 0) {
    return remainingCapital + realizedCapital;
  }

  // 2. Otherwise use investment amount
  return investmentAmount;
}

/**
 * Zwraca nazwę wyświetlaną dla typu produktu
 * UPDATED: Enhanced product type names for normalized data
 */
function getProductTypeName(productType) {
  const typeNames = {
    apartments: 'Apartamenty',
    bonds: 'Obligacje',
    shares: 'Udziały',
    loans: 'Pożyczki',
    other: 'Inne',
    // Additional mappings for legacy data
    'apartamenty': 'Apartamenty',
    'obligacje': 'Obligacje',
    'udziały': 'Udziały',
    'pożyczki': 'Pożyczki',
  };

  return typeNames[productType?.toLowerCase()] || 'Nieznany';
}

/**
 * Zwraca pola specyficzne dla danego typu produktu
 */
function getTypeSpecificFields(productType, data) {
  switch (productType) {
    case 'apartments':
      return {
        address: safeToString(data.address),
        apartmentNumber: safeToString(data.apartmentNumber),
        building: safeToString(data.building),
        floor: safeToDouble(data.floor),
        area: safeToDouble(data.area),
        roomCount: safeToDouble(data.roomCount),
        pricePerM2: safeToDouble(data.pricePerM2),
        parkingSpace: safeToDouble(data.parkingSpace),
        storageRoom: safeToDouble(data.storageRoom),
        balcony: safeToDouble(data.balcony),
        developer: safeToString(data.developer),
        projectName: safeToString(data.projectName),
      };
    case 'bonds':
      return {
        interestRate: extractInterestRate(data),
        maturityDate: parseDate(data.deliveryDate || data.redemptionDate),
        issuer: safeToString(data.creditorCompany || data.companyId),
      };
    case 'shares':
      return {
        shareCount: safeToString(data.shareCount),
        companyName: safeToString(data.creditorCompany || data.companyId),
      };
    case 'loans':
      return {
        borrower: safeToString(data.creditorCompany),
        interestRate: extractInterestRate(data),
        maturityDate: parseDate(data.deliveryDate),
      };
    default:
      return {};
  }
}

/**
 * Próbuje wyciągnąć oprocentowanie z różnych pól
 */
function extractInterestRate(data) {
  // Szukaj w różnych możliwych polach
  const possibleFields = [
    'interestRate',
    'oprocentowanie',
    'rate',
    'stopa',
  ];

  for (const field of possibleFields) {
    if (data[field]) {
      const rate = safeToDouble(data[field]);
      if (rate > 0) return rate;
    }
  }

  return null;
}

/**
 * Główna funkcja: Pobiera zunifikowane produkty z kolekcji 'investments'
 */
const getUnifiedProducts = onCall({
  memory: "2GiB",
  timeoutSeconds: 540,
  cors: true,
}, async (request) => {
  const data = request.data || {};
  const startTime = Date.now();
  console.log("🚀 [Unified Products] Rozpoczynam pobieranie z kolekcji 'investments'...", data);

  try {
    const {
      page = 1,
      pageSize = 250,
      sortBy = "createdAt",
      sortAscending = false,
      searchQuery = null,
      productTypes = null, // ['apartments', 'bonds', 'shares', 'loans']
      statuses = null,     // ['active', 'inactive', 'pending', 'suspended']
      minInvestmentAmount = null,
      maxInvestmentAmount = null,
      createdAfter = null,
      createdBefore = null,
      companyName = null,
      minInterestRate = null,
      maxInterestRate = null,
      forceRefresh = false,
    } = data;

    // 💾 Sprawdź cache
    const cacheKey = `unified_products_${JSON.stringify(data)}`;
    if (!forceRefresh) {
      const cached = await getCachedResult(cacheKey);
      if (cached) {
        console.log("⚡ [Unified Products] Zwracam z cache");
        return cached;
      }
    }

    console.log("📊 [Unified Products] Pobieranie z kolekcji 'investments'...");

    // Pobierz wszystkie dokumenty z kolekcji 'investments'
    const investmentsSnapshot = await db.collection("investments").get();

    console.log(`📊 [Unified Products] Pobrano ${investmentsSnapshot.size} dokumentów z kolekcji 'investments'`);

    // Sprawdź czy mamy w ogóle jakieś dane
    if (investmentsSnapshot.size === 0) {
      console.error("🚫 [Unified Products] BRAK DANYCH w kolekcji 'investments'!");

      return {
        products: [],
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
          cacheUsed: false,
          filters: data,
          warning: "Brak danych w kolekcji 'investments'"
        },
      };
    }

    // Konwertuj dokumenty na zunifikowane produkty
    const allProducts = [];

    investmentsSnapshot.docs.forEach(doc => {
      try {
        const product = convertInvestmentToUnifiedProduct(doc);
        allProducts.push(product);
      } catch (error) {
        console.warn(`⚠️ [Unified Products] Błąd konwersji dokumentu ${doc.id}:`, error);
      }
    });

    console.log(`📊 [Unified Products] Skonwertowano ${allProducts.length} produktów`);

    // Zastosuj filtry
    let filteredProducts = [...allProducts];

    // Filtr typu produktu
    if (productTypes && productTypes.length > 0) {
      filteredProducts = filteredProducts.filter(p => productTypes.includes(p.productType));
    }

    // Filtr statusu
    if (statuses && statuses.length > 0) {
      filteredProducts = filteredProducts.filter(p => statuses.includes(p.status));
    }

    // Filtr wyszukiwania
    if (searchQuery && searchQuery.trim()) {
      const searchLower = searchQuery.toLowerCase();
      filteredProducts = filteredProducts.filter(p =>
        p.name.toLowerCase().includes(searchLower) ||
        (p.companyName && p.companyName.toLowerCase().includes(searchLower)) ||
        (p.clientName && p.clientName.toLowerCase().includes(searchLower)) ||
        p.id.toLowerCase().includes(searchLower)
      );
    }

    // Filtr kwoty inwestycji
    if (minInvestmentAmount !== null) {
      filteredProducts = filteredProducts.filter(p => p.investmentAmount >= minInvestmentAmount);
    }
    if (maxInvestmentAmount !== null) {
      filteredProducts = filteredProducts.filter(p => p.investmentAmount <= maxInvestmentAmount);
    }

    // Filtr nazwy spółki
    if (companyName && companyName.trim()) {
      filteredProducts = filteredProducts.filter(p =>
        p.companyName && p.companyName.toLowerCase().includes(companyName.toLowerCase())
      );
    }

    // Filtr dat
    if (createdAfter) {
      const afterDate = new Date(createdAfter);
      filteredProducts = filteredProducts.filter(p => new Date(p.createdAt) >= afterDate);
    }
    if (createdBefore) {
      const beforeDate = new Date(createdBefore);
      filteredProducts = filteredProducts.filter(p => new Date(p.createdAt) <= beforeDate);
    }

    console.log(`📊 [Unified Products] Po filtrach: ${filteredProducts.length} produktów`);

    // Sortowanie
    filteredProducts.sort((a, b) => {
      let comparison = 0;

      switch (sortBy) {
        case 'name':
          comparison = a.name.localeCompare(b.name);
          break;
        case 'productType':
          comparison = a.productTypeName.localeCompare(b.productTypeName);
          break;
        case 'investmentAmount':
          comparison = a.investmentAmount - b.investmentAmount;
          break;
        case 'totalValue':
          comparison = a.totalValue - b.totalValue;
          break;
        case 'createdAt':
          comparison = new Date(a.createdAt) - new Date(b.createdAt);
          break;
        case 'companyName':
          comparison = (a.companyName || '').localeCompare(b.companyName || '');
          break;
        default:
          comparison = new Date(a.createdAt) - new Date(b.createdAt);
      }

      return sortAscending ? comparison : -comparison;
    });

    // Paginacja
    const totalCount = filteredProducts.length;
    const startIndex = (page - 1) * pageSize;
    const endIndex = startIndex + pageSize;
    const paginatedProducts = filteredProducts.slice(startIndex, endIndex);

    console.log(`📊 [Unified Products] Zwracam stronę ${page} (${paginatedProducts.length} z ${totalCount})`);

    const result = {
      products: paginatedProducts,
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
        cacheUsed: false,
        filters: data,
      },
    };

    // 💾 Cache wyników na 5 minut
    await setCachedResult(cacheKey, result, 300);

    console.log(`✅ [Unified Products] Zakończono w ${Date.now() - startTime}ms`);
    return result;

  } catch (error) {
    console.error("❌ [Unified Products] Błąd:", error);
    throw new HttpsError(
      "internal",
      "Nie udało się pobrać zunifikowanych produktów",
      error.message,
    );
  }
});

module.exports = {
  getUnifiedProducts,
};
