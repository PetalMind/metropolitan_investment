/**
 * Capital Calculation Service
 * Service for calculating and saving "Capital secured by real estate" in database
 */

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const { admin, db } = require("../utils/firebase-config");
const { safeToDouble } = require("../utils/data-mapping");
const { getUnifiedField } = require("../utils/unified-statistics");

/**
 * Updates "Capital secured by real estate" field for all investments
 * Calculates: Remaining Capital - Capital for restructuring = Capital secured by real estate
 */
// DEPRECATED: left as stub – no longer performs calculations
const updateCapitalSecuredByRealEstate = onCall({
  memory: "2GiB",
  timeoutSeconds: 540,
  cors: true,
}, async (request) => {
  const data = request.data || {};
  const startTime = Date.now();
  console.log("🚫 [CapitalCalculation] Function deactivated – no capital secured updates.");

  try {
    return {
      processed: 0,
      updated: 0,
      errors: 0,
      deprecated: true,
      message: 'Secured capital calculations have been disabled on backend',
      executionTimeMs: Date.now() - startTime,
      timestamp: new Date().toISOString()
    };

  } catch (error) {
    console.error("❌ [CapitalCalculation] Error:", error);
    throw new HttpsError(
      "internal",
      "Failed to update capital secured by real estate",
      error.message
    );
  }
});

/**
 * Processes single investment - calculates and saves capital secured by real estate
 * @param {Object} investment - investment document
 * @param {boolean} dryRun - whether to only simulate without saving to database
 * @returns {Object} - processing result
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
