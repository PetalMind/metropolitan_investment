/**
 * Unified Statistics Utilities
 * Pojedyncze źródło prawdy dla wszystkich obliczeń statystycznych
 * 
 * KRYTYCZNE: Używaj tych funkcji we WSZYSTKICH Firebase Functions
 */

const { safeToDouble } = require('./data-mapping');

/**
 * Globalna konfiguracja statystyk
 */
const STATISTICS_CONFIG = {
  DEFINITIONS: {
    TOTAL_VALUE: 'remainingCapital + remainingInterest',
    VIABLE_CAPITAL: 'remainingCapital WHERE productStatus = Aktywny',
    MAJORITY_THRESHOLD: 'viableCapital * 0.51',
    ACTIVE_STATUS: 'Aktywny',
    CAPITAL_SECURED_BY_REAL_ESTATE: 'remainingCapital - capitalForRestructuring' // NOWY
  },

  FIELD_MAPPING: {
    // Remaining capital - main field for calculations
    remainingCapital: [
      'remainingCapital',           // Standard Firebase Functions
      'kapital_pozostaly',          // Polish format (legacy)
      'Kapital Pozostaly',          // Excel import format (legacy)
    ],

    // Remaining interest
    remainingInterest: [
      'remainingInterest',          // Standard Firebase Functions
      'odsetki_pozostale',          // Polish format (legacy)
    ],

    // Investment amount - ENHANCED for normalized JSON import
    investmentAmount: [
      'investmentAmount',           // Firestore field (PRIORITY)
      'kwota_inwestycji',           // Polish format (legacy)
      'Kwota_inwestycji',           // Excel format (legacy)
      'paidAmount'                  // Additional field from normalized import
    ],

    // Product status - ENHANCED for normalized JSON import
    productStatus: [
      'productStatus',              // Firestore field (PRIORITY)
      'status_produktu',            // Polish format (legacy)
      'Status_produktu',            // Excel format (legacy)
      'status'                      // Generic status field
    ],

    // Client name
    clientName: [
      'clientName',                 // Firestore field (PRIORITY)
      'klient',                     // Polish format (legacy)
      'Klient'                      // Excel format (legacy)
    ],

    // Client ID
    clientId: [
      'clientId',                   // Firestore field (PRIORITY)
      'ID_Klient',                  // Excel format (legacy)
      'klient_id'                   // Alternative format (legacy)
    ],

    // Capital for restructuring
    capitalForRestructuring: [
      'capitalForRestructuring',    // Firestore field (PRIORITY)
      'kapital_do_restrukturyzacji', // Polish format (legacy)
      'Kapitał do restrukturyzacji' // Excel format (legacy)
    ],

    // Capital secured by real estate
    capitalSecuredByRealEstate: [
      'capitalSecuredByRealEstate', // Firestore field (PRIORITY)
      'kapital_zabezpieczony_nieruchomoscia', // Polish format (legacy)
      'Kapitał zabezpieczony nieruchomością'  // Excel format (legacy)
    ],

    // Product name
    productName: [
      'productName',                // Firestore field (PRIORITY)
      'nazwa_produktu',             // Polish format (legacy)
      'Produkt_nazwa'               // Excel format (legacy)
    ],

    // Product type
    productType: [
      'productType',                // Firestore field (PRIORITY)
      'typ_produktu',               // Polish format (legacy)
      'Typ_produktu'                // Excel format (legacy)
    ],

    // Company ID
    companyId: [
      'companyId',                  // Firestore field (PRIORITY)
      'ID_Spolka',                  // Excel format (legacy)
      'spolka_id'                   // Alternative format (legacy)
    ],

    // Signing date
    signingDate: [
      'signingDate',                // Firestore field (PRIORITY)
      'data_podpisania',            // Polish format (legacy)
      'Data_podpisania'             // Excel format (legacy)
    ],

    // Realized capital
    realizedCapital: [
      'realizedCapital',            // Firestore field (PRIORITY)
      'kapital_zrealizowany',       // Polish format (legacy)
      'Kapital zrealizowany'        // Excel format (legacy)
    ],

    // Realized interest
    realizedInterest: [
      'realizedInterest',           // Firestore field (PRIORITY)
      'odsetki_zrealizowane',       // Polish format (legacy)
      'Odsetki zrealizowane'        // Excel format (legacy)
    ],

    // Transfer to other product
    transferToOtherProduct: [
      'transferToOtherProduct',     // Firestore field (PRIORITY)
      'przekaz_na_inny_produkt',    // Polish format (legacy)
      'Przekaz na inny produkt'     // Excel format (legacy)
    ],

    // Advisor
    advisor: [
      'advisor',                    // Firestore field (PRIORITY)
      'opiekun',                    // Polish format (legacy)
      'Opiekun z MISA'              // Excel format (legacy)
    ],

    // Branch
    branch: [
      'branch',                     // Firestore field (PRIORITY)
      'oddzial',                    // Polish format (legacy)
      'Oddzial'                     // Excel format (legacy)
    ],

    // Sale ID
    saleId: [
      'saleId',                     // Firestore field (PRIORITY)
      'ID_Sprzedaz',                // Excel format (legacy)
      'sprzedaz_id'                 // Alternative format (legacy)
    ]
  }
};

/**
 * ZUNIFIKOWANA funkcja obliczania totalValue
 * @param {Object} investment - dokument inwestycji
 * @returns {number} - totalValue = remainingCapital + remainingInterest
 */
function calculateUnifiedTotalValue(investment) {
  const remainingCapital = getUnifiedField(investment, 'remainingCapital');
  const remainingInterest = getUnifiedField(investment, 'remainingInterest');

  const totalValue = remainingCapital + remainingInterest;

  if (process.env.NODE_ENV === 'development') {
    console.log(`[Unified] totalValue calculation: ${remainingCapital} + ${remainingInterest} = ${totalValue}`);
  }

  return totalValue;
}

/**
 * ZUNIFIKOWANA funkcja obliczania viableCapital
 * @param {Object} investment - dokument inwestycji
 * @returns {number} - viableCapital (tylko dla aktywnych inwestycji)
 */
function calculateUnifiedViableCapital(investment) {
  const productStatus = getUnifiedField(investment, 'productStatus');

  // ZUNIFIKOWANE FILTROWANIE: tylko aktywne inwestycje
  if (productStatus !== STATISTICS_CONFIG.DEFINITIONS.ACTIVE_STATUS) {
    return 0;
  }

  const remainingCapital = getUnifiedField(investment, 'remainingCapital');

  if (process.env.NODE_ENV === 'development') {
    console.log(`[Unified] viableCapital: status=${productStatus}, capital=${remainingCapital}`);
  }

  return remainingCapital;
}

/**
 * NOWA: ZUNIFIKOWANA funkcja obliczania kapitału zabezpieczonego nieruchomością
 * @param {Object} investment - dokument inwestycji  
 * @returns {number} - capitalSecuredByRealEstate = remainingCapital - capitalForRestructuring
 */
// 🔕 DEPRECATED: backend calculation disabled – always return 0 to reduce processing.
function calculateCapitalSecuredByRealEstate(_investment) {
  return 0;
}

/**
 * ZUNIFIKOWANA funkcja obliczania progu większościowego
 * @param {number} totalViableCapital - całkowity kapitał zdatny do głosowania
 * @returns {number} - próg 51%
 */
function calculateMajorityThreshold(totalViableCapital) {
  return totalViableCapital * 0.51;
}

/**
 * Pobiera wartość pola używając zunifikowanego mapowania
 * @param {Object} data - dokument z danymi
 * @param {string} fieldType - typ pola (klucz z FIELD_MAPPING)
 * @returns {number|string} - zunifikowana wartość
 */
function getUnifiedField(data, fieldType) {
  const possibleFields = STATISTICS_CONFIG.FIELD_MAPPING[fieldType];

  if (!possibleFields) {
    console.warn(`[Unified] Unknown field type: ${fieldType}`);
    return fieldType.includes('Capital') || fieldType.includes('Interest') || fieldType.includes('Amount') ? 0 : '';
  }

  for (const field of possibleFields) {
    if (data[field] !== undefined && data[field] !== null) {
      // Konwertuj liczbowe pola na double
      if (fieldType.includes('Capital') || fieldType.includes('Interest') || fieldType.includes('Amount')) {
        return safeToDouble(data[field]);
      }
      // Zwróć string pola
      return data[field];
    }
  }

  // Zwróć wartość domyślną
  return fieldType.includes('Capital') || fieldType.includes('Interest') || fieldType.includes('Amount') ? 0 : '';
}

/**
 * Sprawdza czy inwestycja jest aktywna według zunifikowanych kryteriów
 * @param {Object} investment - dokument inwestycji
 * @returns {boolean}
 */
function isInvestmentActive(investment) {
  const productStatus = getUnifiedField(investment, 'productStatus');
  return productStatus === STATISTICS_CONFIG.DEFINITIONS.ACTIVE_STATUS;
}

/**
 * Oblicza zunifikowane statystyki systemu
 * @param {Array} investments - lista inwestycji
 * @returns {Object} - statystyki systemu
 */
function calculateUnifiedSystemStats(investments) {
  let totalValue = 0;
  let totalViableCapital = 0;
  let totalInvestmentAmount = 0;
  let activeCount = 0;
  let inactiveCount = 0;

  const productTypeStats = {};

  investments.forEach(investment => {
    const investmentTotalValue = calculateUnifiedTotalValue(investment);
    const investmentViableCapital = calculateUnifiedViableCapital(investment);
    const investmentAmount = getUnifiedField(investment, 'investmentAmount');
    const productType = investment.productType || 'Nieznany';
    const isActive = isInvestmentActive(investment);

    totalValue += investmentTotalValue;
    totalViableCapital += investmentViableCapital;
    totalInvestmentAmount += investmentAmount;

    if (isActive) {
      activeCount++;
    } else {
      inactiveCount++;
    }

    // Statystyki według typu produktu
    if (!productTypeStats[productType]) {
      productTypeStats[productType] = {
        count: 0,
        totalValue: 0,
        viableCapital: 0,
        investmentAmount: 0
      };
    }

    productTypeStats[productType].count++;
    productTypeStats[productType].totalValue += investmentTotalValue;
    productTypeStats[productType].viableCapital += investmentViableCapital;
    productTypeStats[productType].investmentAmount += investmentAmount;
  });

  const majorityThreshold = calculateMajorityThreshold(totalViableCapital);

  return {
    totalValue,
    totalViableCapital,
    totalInvestmentAmount,
    majorityThreshold,
    activeCount,
    inactiveCount,
    totalCount: investments.length,
    productTypeStats,

    // Metadata
    calculatedAt: new Date().toISOString(),
    unifiedVersion: '1.0',
    definitions: STATISTICS_CONFIG.DEFINITIONS
  };
}

/**
 * Normalizuje dokument inwestycji do zunifikowanego formatu
 * @param {Object} investment - surowy dokument inwestycji
 * @returns {Object} - znormalizowany dokument
 */
function normalizeInvestmentDocument(investment) {
  return {
    id: investment.id,
    clientName: getUnifiedField(investment, 'clientName'),
    clientId: getUnifiedField(investment, 'clientId'),
    remainingCapital: getUnifiedField(investment, 'remainingCapital'),
    remainingInterest: getUnifiedField(investment, 'remainingInterest'),
    investmentAmount: getUnifiedField(investment, 'investmentAmount'),
    productStatus: getUnifiedField(investment, 'productStatus'),
    productName: getUnifiedField(investment, 'productName'), // DODANE
    productType: getUnifiedField(investment, 'productType') || 'Nieznany',

    // Obliczone pola
    totalValue: calculateUnifiedTotalValue(investment),
    viableCapital: calculateUnifiedViableCapital(investment),
    isActive: isInvestmentActive(investment),
    capitalSecuredByRealEstate: calculateCapitalSecuredByRealEstate(investment), // NOWY
    capitalForRestructuring: getUnifiedField(investment, 'capitalForRestructuring'), // 🔥 NAPRAWKA

    // Oryginalne dane w additionalInfo
    originalData: investment
  };
}

module.exports = {
  STATISTICS_CONFIG,
  calculateUnifiedTotalValue,
  calculateUnifiedViableCapital,
  calculateCapitalSecuredByRealEstate, // NOWY
  calculateMajorityThreshold,
  calculateUnifiedSystemStats,
  getUnifiedField,
  isInvestmentActive,
  normalizeInvestmentDocument
};
