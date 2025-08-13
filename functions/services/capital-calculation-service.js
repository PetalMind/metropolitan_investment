/**
 * Capital Calculation Service
 * Serwis do obliczania i zapisywania "Kapitał zabezpieczony nieruchomością" w bazie danych
 */

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const { admin, db } = require("../utils/firebase-config");
const { safeToDouble } = require("../utils/data-mapping");
const { getUnifiedField } = require("../utils/unified-statistics");

/**
 * Aktualizuje pole "Kapitał zabezpieczony nieruchomością" dla wszystkich inwestycji
 * Oblicza: Kapitał Pozostały - Kapitał do restrukturyzacji = Kapitał zabezpieczony nieruchomością
 */
// DEPRECATED: pozostawione jako stub – nie wykonuje już przeliczeń
const updateCapitalSecuredByRealEstate = onCall({
  memory: "2GiB",
  timeoutSeconds: 540,
  cors: true,
}, async (request) => {
  const data = request.data || {};
  const startTime = Date.now();
  console.log("🚫 [CapitalCalculation] Funkcja zdezaktywowana – brak aktualizacji kapitału zabezpieczonego.");

  try {
    return {
      processed: 0,
      updated: 0,
      errors: 0,
      deprecated: true,
      message: 'Obliczenia kapitału zabezpieczonego zostały wyłączone na backendzie',
      executionTimeMs: Date.now() - startTime,
      timestamp: new Date().toISOString()
    };

  } catch (error) {
    console.error("❌ [CapitalCalculation] Błąd:", error);
    throw new HttpsError(
      "internal",
      "Nie udało się zaktualizować kapitału zabezpieczonego nieruchomością",
      error.message
    );
  }
});

/**
 * Przetwarza pojedynczą inwestycję - oblicza i zapisuje kapitał zabezpieczony nieruchomością
 * @param {Object} investment - dokument inwestycji
 * @param {boolean} dryRun - czy tylko symulować bez zapisu do bazy
 * @returns {Object} - wynik przetwarzania
 */
// processInvestment usunięte – logika nieaktywna

/**
 * Sprawdza status obliczania kapitału zabezpieczonego nieruchomością
 * Zwraca statystyki ile inwestycji ma aktualne/nieaktualne wartości
 */
const checkCapitalCalculationStatus = onCall({ cors: true }, async () => {
  return {
    deprecated: true,
    message: 'Monitoring obliczeń wyłączony – backend nie oblicza już capitalSecuredByRealEstate',
    timestamp: new Date().toISOString()
  };
});

/**
 * Funkcja schedulowana do automatycznego przeliczania co tydzień
 * (Opcjonalnie można dodać do cron jobs)
 */
const scheduleCapitalRecalculation = onCall({ cors: true }, async () => {
  return {
    deprecated: true,
    message: 'Schedulowane przeliczenie wyłączone – brak potrzeby aktualizacji',
    timestamp: new Date().toISOString()
  };
});

module.exports = {
  updateCapitalSecuredByRealEstate,
  checkCapitalCalculationStatus,
  scheduleCapitalRecalculation
};
