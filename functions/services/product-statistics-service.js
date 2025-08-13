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
  console.log(`🔥 [ProductStatisticsService] OBLICZANIE STATYSTYK PRODUKTU: ${productName}`);
  console.log(`📊 Liczba inwestycji do przetworzenia: ${investments.length}`);

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
          console.log(`⚠️ DUPLIKAT POMINIĘTY: ${investment.id}`);
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
        console.log(`    * investmentAmount: ${investmentAmount}`);
        console.log(`    * remainingCapital: ${remainingCapital}`);
        const capitalForRestructuring = getUnifiedField(investment, 'capitalForRestructuring');
        totalCapitalForRestructuring += capitalForRestructuring;
        console.log(`    * capitalForRestructuring: ${capitalForRestructuring}`);
      } catch (investmentError) {
        console.error(`❌ Błąd przetwarzania inwestycji ${investment?.id || 'nieznane'}:`, investmentError);
        // Kontynuuj przetwarzanie innych inwestycji
        continue;
      }
    }

    console.log('🧮 [ProductStatisticsService] OBLICZANIE KOŃCOWE (uproszczone):');
    console.log(`  - totalRemainingCapital: ${totalRemainingCapital}`);
    console.log(`  - totalCapitalForRestructuring: ${totalCapitalForRestructuring}`);
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

    console.log('📊 [ProductStatisticsService] KOŃCOWE ZUNIFIKOWANE STATYSTYKI:');
    console.log(`  - totalInvestmentAmount: ${totalInvestmentAmount}`);
    console.log(`  - totalRemainingCapital: ${totalRemainingCapital}`);
    console.log('  - totalCapitalForRestructuring: ' + totalCapitalForRestructuring);
    console.log('  - totalCapitalSecuredByRealEstate: ' + totalCapitalSecuredByRealEstate);
    console.log(`  - viableCapital: ${viableCapital}`);
    console.log(`  - investorsCount: ${investorsCount}`);

    return statistics;

  } catch (error) {
    console.error(`❌ [ProductStatisticsService] Krityczny błąd obliczania statystyk dla produktu "${productName}":`, error);
    console.error(`❌ [ProductStatisticsService] Stack trace:`, error.stack);
    throw error;
  }
}

module.exports = {
  calculateProductStatistics
};
