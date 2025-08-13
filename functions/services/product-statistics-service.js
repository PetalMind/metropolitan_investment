/**
 * Product Statistics Service - Firebase Functions
 * Oblicza zunifikowane statystyki produktu po stronie serwera
 */

const { getUnifiedField, isInvestmentActive } = require('../utils/unified-statistics');

/**
 * Oblicza statystyki produktu po stronie serwera
 * @param {Array} investments - lista inwestycji dla konkretnego produktu
 * @param {string} productName - nazwa produktu
 * @returns {Object} - statystyki produktu
 */
async function calculateProductStatistics(investments, productName) {

  // ⚠️ WALIDACJA PARAMETRÓW
  if (!productName || typeof productName !== 'string' || productName.trim() === '') {
    throw new Error('Parametr productName jest wymagany i nie może być pusty');
  }

  if (!investments || !Array.isArray(investments)) {
    throw new Error('Parametr investments musi być tablicą');
  }

  try {
    // Inicjalizacja sum
    let totalInvestmentAmount = 0;
    let totalRemainingCapital = 0;
    let totalCapitalForRestructuring = 0; // NOWE
    // totalCapitalSecuredByRealEstate obliczamy na końcu ze wzoru
    let activeInvestorsCount = 0;
    let investorsCount = 0;
    let hasInactiveInvestors = false;

    // Deduplikacja na podstawie ID inwestycji
    const processedInvestmentIds = new Set();
    const uniqueClientIds = new Set();

    for (const investment of investments) {
      try {
        // Filtruj tylko inwestycje danego produktu
        const investmentProductName = getUnifiedField(investment, 'productName');
        if (investmentProductName !== productName) {
          continue;
        }

        // Deduplikacja
        if (processedInvestmentIds.has(investment.id)) {
          continue;
        }
        processedInvestmentIds.add(investment.id);

        // Sprawdź status inwestora (założenie że mamy pole clientStatus lub podobne)
        const isActive = isInvestmentActive(investment);

        if (!isActive) {
          hasInactiveInvestors = true;
        } else {
          // Zlicz unikalnych aktywnych klientów
          const clientId = getUnifiedField(investment, 'clientId');
          uniqueClientIds.add(clientId);
        }

        // Sumuj podstawowe wartości
        const investmentAmount = getUnifiedField(investment, 'investmentAmount');
        const remainingCapital = getUnifiedField(investment, 'remainingCapital');
        totalInvestmentAmount += investmentAmount;
        totalRemainingCapital += remainingCapital;

        console.log(`  ✅ ${getUnifiedField(investment, 'clientName')}: ${investmentProductName}`);
        const capitalForRestructuring = getUnifiedField(investment, 'capitalForRestructuring');
        totalCapitalForRestructuring += capitalForRestructuring;
      } catch (investmentError) {
        // Kontynuuj przetwarzanie innych inwestycji
        continue;
      }
    }

    console.log('🧮 [ProductStatisticsService] OBLICZANIE KOŃCOWE (uproszczone):');
    const totalCapitalSecuredByRealEstate = Math.max(
      totalRemainingCapital - totalCapitalForRestructuring,
      0
    );

    // Oblicz pozostałe metryki
    activeInvestorsCount = uniqueClientIds.size;
    investorsCount = uniqueClientIds.size; // Dla uproszczenia
    const viableCapital = totalRemainingCapital;
    const majorityThreshold = viableCapital * 0.5;
    const majorityVotingCapacity = viableCapital > 0 ? (majorityThreshold / viableCapital) * 100 : 0.0;

    const statistics = {
      totalInvestmentAmount,
      totalRemainingCapital,
      viableCapital,
      majorityThreshold,
      totalCapitalForRestructuring,
      totalCapitalSecuredByRealEstate,
      investorsCount,
      activeInvestorsCount,
      majorityVotingCapacity,
      hasInactiveInvestors,

      // Metadata
      calculatedAt: new Date().toISOString(),
      productName,
      processedInvestmentsCount: processedInvestmentIds.size,
      originalInvestmentsCount: investments.length
    };

    return statistics;

  } catch (error) {
    throw error;
  }
}

module.exports = {
  calculateProductStatistics
};
