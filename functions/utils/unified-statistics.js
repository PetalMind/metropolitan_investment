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
    // Kapitał pozostały - główne pole do obliczeń
    remainingCapital: [
      'remainingCapital',           // Standard Firebase Functions
      'kapital_pozostaly',          // Polski format
      'Kapital Pozostaly',          // Excel import format
      'Kapital zrealizowany'        // Alternatywna nazwa
    ],

    // Odsetki pozostałe
    remainingInterest: [
      'remainingInterest',          // Standard Firebase Functions
      'odsetki_pozostale',          // Polski format
      'remainingInterest'           // Firestore field
    ],

    // Kwota inwestycji
    investmentAmount: [
      'investmentAmount',           // Firestore field (CONFIRMED)
      'kwota_inwestycji',           // Polski format
      'Kwota_inwestycji',           // Excel format
      'paymentAmount'               // Alternative field (CONFIRMED)
    ],

    // Status produktu
    productStatus: [
      'productStatus',              // Firestore field (CONFIRMED)
      'status_produktu',            // Polski format
      'Status_produktu'             // Excel format
    ],

    // Nazwa klienta
    clientName: [
      'clientName',                 // Firestore field (CONFIRMED)
      'klient',                     // Polski format
      'Klient'                      // Excel format
    ],

    // ID klienta
    clientId: [
      'clientId',                   // Firestore field (CONFIRMED)
      'ID_Klient',                  // Excel format
      'klient_id'                   // Alternative format
    ],

    // Kapitał do restrukturyzacji (CONFIRMED in Firestore)
    capitalForRestructuring: [
      'capitalForRestructuring',    // Firestore field (CONFIRMED)
      'kapital_do_restrukturyzacji', // Polski format
      'Kapitał do restrukturyzacji' // Excel format
    ],

    // Kapitał zabezpieczony nieruchomością (CONFIRMED in Firestore)
    capitalSecuredByRealEstate: [
      'capitalSecuredByRealEstate', // Firestore field (CONFIRMED)
      'kapital_zabezpieczony_nieruchomoscia', // Polski format
      'Kapitał zabezpieczony nieruchomością'  // Excel format
    ],

    // Dodatkowe pola z rzeczywistych danych Firestore
    productName: [
      'productName',                // Firestore field (CONFIRMED)
      'nazwa_produktu',             // Polski format
      'Produkt_nazwa'               // Excel format
    ],

    productType: [
      'productType',                // Firestore field (CONFIRMED)
      'typ_produktu',               // Polski format
      'Typ_produktu'                // Excel format
    ],

    companyId: [
      'companyId',                  // Firestore field (CONFIRMED)
      'ID_Spolka',                  // Excel format
      'spolka_id'                   // Alternative format
    ],

    signedDate: [
      'signedDate',                 // Firestore field (CONFIRMED)
      'data_podpisania',            // Polski format
      'Data_podpisania'             // Excel format
    ],

    realizedCapital: [
      'realizedCapital',            // Firestore field (CONFIRMED)
      'kapital_zrealizowany',       // Polski format
      'Kapital zrealizowany'        // Excel format
    ],

    realizedInterest: [
      'realizedInterest',           // Firestore field (CONFIRMED)
      'odsetki_zrealizowane',       // Polski format
      'Odsetki zrealizowane'        // Excel format
    ],

    transferToOtherProduct: [
      'transferToOtherProduct',     // Firestore field (CONFIRMED)
      'przekaz_na_inny_produkt',    // Polski format
      'Przekaz na inny produkt'     // Excel format
    ],

    advisor: [
      'advisor',                    // Firestore field (CONFIRMED)
      'opiekun',                    // Polski format
      'Opiekun z MISA'              // Excel format
    ],

    branch: [
      'branch',                     // Firestore field (CONFIRMED)
      'oddzial',                    // Polski format
      'Oddzial'                     // Excel format
    ],

    salesId: [
      'salesId',                    // Firestore field (CONFIRMED)
      'ID_Sprzedaz',                // Excel format
      'sprzedaz_id'                 // Alternative format
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
function calculateCapitalSecuredByRealEstate(investment) {
  const remainingCapital = getUnifiedField(investment, 'remainingCapital');
  const capitalForRestructuring = getUnifiedField(investment, 'capitalForRestructuring');

  const capitalSecuredByRealEstate = remainingCapital - capitalForRestructuring;

  if (process.env.NODE_ENV === 'development') {
    console.log(`[Unified] capitalSecuredByRealEstate: ${remainingCapital} - ${capitalForRestructuring} = ${capitalSecuredByRealEstate}`);
  }

  // Zwróć nie mniej niż 0
  return Math.max(0, capitalSecuredByRealEstate);
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
    productType: investment.productType || 'Nieznany',

    // Obliczone pola
    totalValue: calculateUnifiedTotalValue(investment),
    viableCapital: calculateUnifiedViableCapital(investment),
    isActive: isInvestmentActive(investment),
    capitalSecuredByRealEstate: calculateCapitalSecuredByRealEstate(investment), // NOWY

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
