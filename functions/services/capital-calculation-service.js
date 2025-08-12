/**
 * Capital Calculation Service
 * Serwis do obliczania i zapisywania "Kapitał zabezpieczony nieruchomością" w bazie danych
 */

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const { admin, db } = require("../utils/firebase-config");
const { safeToDouble } = require("../utils/data-mapping");
const {
  calculateCapitalSecuredByRealEstate,
  getUnifiedField,
  normalizeInvestmentDocument
} = require("../utils/unified-statistics");

/**
 * Aktualizuje pole "Kapitał zabezpieczony nieruchomością" dla wszystkich inwestycji
 * Oblicza: Kapitał Pozostały - Kapitał do restrukturyzacji = Kapitał zabezpieczony nieruchomością
 */
const updateCapitalSecuredByRealEstate = onCall({
  memory: "2GiB",
  timeoutSeconds: 540,
  cors: true,
}, async (request) => {
  const data = request.data || {};
  const startTime = Date.now();
  console.log("🚀 [CapitalCalculation] Rozpoczynam aktualizację kapitału zabezpieczonego nieruchomością...");

  try {
    const batchSize = data.batchSize || 500; // Rozmiar batcha dla wydajności
    const dryRun = data.dryRun || false; // Tryb testowy - nie zapisuje do bazy
    const specificInvestmentId = data.investmentId; // Opcjonalnie tylko konkretna inwestycja

    let query = db.collection("investments");

    // Jeśli podano konkretne ID inwestycji
    if (specificInvestmentId) {
      console.log(`📋 [CapitalCalculation] Aktualizacja tylko dla inwestycji: ${specificInvestmentId}`);
      const investmentDoc = await db.collection("investments").doc(specificInvestmentId).get();

      if (!investmentDoc.exists) {
        throw new HttpsError("not-found", `Inwestycja o ID ${specificInvestmentId} nie została znaleziona`);
      }

      const investment = { id: investmentDoc.id, ...investmentDoc.data() };
      const result = await processInvestment(investment, dryRun);

      return {
        processed: 1,
        updated: result.updated ? 1 : 0,
        errors: result.error ? 1 : 0,
        details: [result],
        executionTimeMs: Date.now() - startTime,
        timestamp: new Date().toISOString(),
        dryRun: dryRun
      };
    }

    // Pobierz wszystkie inwestycje
    console.log("📋 [CapitalCalculation] Pobieranie wszystkich inwestycji...");
    const investmentsSnapshot = await query.limit(50000).get();
    const investments = investmentsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    console.log(`📊 [CapitalCalculation] Znaleziono ${investments.length} inwestycji do przetworzenia`);

    let processed = 0;
    let updated = 0;
    let errors = 0;
    let details = [];

    // Przetwarzaj w batchach
    for (let i = 0; i < investments.length; i += batchSize) {
      const batch = investments.slice(i, i + batchSize);
      console.log(`🔄 [CapitalCalculation] Przetwarzanie batcha ${Math.floor(i / batchSize) + 1}/${Math.ceil(investments.length / batchSize)} (${batch.length} inwestycji)`);

      const batchPromises = batch.map(investment => processInvestment(investment, dryRun));
      const batchResults = await Promise.all(batchPromises);

      // Agreguj wyniki
      batchResults.forEach(result => {
        processed++;
        if (result.updated) updated++;
        if (result.error) errors++;
        if (result.error || data.includeDetails) {
          details.push(result);
        }
      });

      // Krótka przerwa między batchami dla uniknięcia przeciążenia
      if (i + batchSize < investments.length) {
        await new Promise(resolve => setTimeout(resolve, 100));
      }
    }

    console.log(`✅ [CapitalCalculation] Zakończono przetwarzanie: ${processed} przetworzonych, ${updated} zaktualizowanych, ${errors} błędów`);

    return {
      processed,
      updated,
      errors,
      details: details.slice(0, 100), // Ogranicz detale do pierwszych 100 dla wydajności
      executionTimeMs: Date.now() - startTime,
      timestamp: new Date().toISOString(),
      dryRun: dryRun,
      summary: {
        successRate: `${((processed - errors) / processed * 100).toFixed(1)}%`,
        updateRate: `${(updated / processed * 100).toFixed(1)}%`
      }
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
async function processInvestment(investment, dryRun = false) {
  try {
    // Pobierz obecne wartości
    const currentRemainingCapital = getUnifiedField(investment, 'remainingCapital');
    const currentCapitalForRestructuring = getUnifiedField(investment, 'capitalForRestructuring');
    const currentCapitalSecuredByRealEstate = getUnifiedField(investment, 'capitalSecuredByRealEstate');

    // Oblicz nową wartość
    const newCapitalSecuredByRealEstate = calculateCapitalSecuredByRealEstate(investment);

    // Sprawdź czy wartość się zmieniła (tolerancja 0.01 PLN dla błędów zaokrąglenia)
    const hasChanged = Math.abs(newCapitalSecuredByRealEstate - currentCapitalSecuredByRealEstate) > 0.01;

    const result = {
      investmentId: investment.id,
      clientName: getUnifiedField(investment, 'clientName'),
      remainingCapital: currentRemainingCapital,
      capitalForRestructuring: currentCapitalForRestructuring,
      oldCapitalSecuredByRealEstate: currentCapitalSecuredByRealEstate,
      newCapitalSecuredByRealEstate: newCapitalSecuredByRealEstate,
      hasChanged: hasChanged,
      updated: false,
      error: null
    };

    // Jeśli wartość się nie zmieniła, pomiń aktualizację
    if (!hasChanged) {
      return result;
    }

    // Jeśli to tylko test, nie zapisuj do bazy
    if (dryRun) {
      result.dryRunNote = "Symulacja - nie zapisano do bazy";
      return result;
    }

    // Aktualizuj dokument w bazie danych
    await db.collection("investments").doc(investment.id).update({
      kapital_zabezpieczony_nieruchomoscia: newCapitalSecuredByRealEstate,
      capitalSecuredByRealEstate: newCapitalSecuredByRealEstate, // Dodaj też angielską wersję
      last_capital_calculation: admin.firestore.Timestamp.now(), // Znacznik czasu aktualizacji
      capital_calculation_version: "1.0" // Wersja algorytmu obliczeniowego
    });

    result.updated = true;
    console.log(`✅ [CapitalCalculation] Zaktualizowano inwestycję ${investment.id}: ${currentCapitalSecuredByRealEstate} → ${newCapitalSecuredByRealEstate}`);

    return result;

  } catch (error) {
    console.error(`❌ [CapitalCalculation] Błąd dla inwestycji ${investment.id}:`, error);
    return {
      investmentId: investment.id,
      error: error.message,
      updated: false
    };
  }
}

/**
 * Sprawdza status obliczania kapitału zabezpieczonego nieruchomością
 * Zwraca statystyki ile inwestycji ma aktualne/nieaktualne wartości
 */
const checkCapitalCalculationStatus = onCall({
  cors: true,
}, async (request) => {
  console.log("📊 [CapitalCalculation] Sprawdzanie statusu obliczeń...");

  try {
    const investmentsSnapshot = await db.collection("investments").limit(10000).get();
    const investments = investmentsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    let totalInvestments = 0;
    let withCalculatedField = 0;
    let withCorrectCalculation = 0;
    let needsUpdate = 0;
    let samples = [];

    investments.forEach(investment => {
      totalInvestments++;

      const currentCapitalSecured = getUnifiedField(investment, 'capitalSecuredByRealEstate');
      const calculatedCapitalSecured = calculateCapitalSecuredByRealEstate(investment);

      const hasField = currentCapitalSecured !== 0 || investment.kapital_zabezpieczony_nieruchomoscia !== undefined;
      const isCorrect = Math.abs(calculatedCapitalSecured - currentCapitalSecured) < 0.01;

      if (hasField) withCalculatedField++;
      if (isCorrect) withCorrectCalculation++;
      if (!isCorrect) needsUpdate++;

      // Zbierz próbki dla analizy
      if (samples.length < 10 && (!isCorrect || !hasField)) {
        samples.push({
          id: investment.id,
          clientName: getUnifiedField(investment, 'clientName'),
          remainingCapital: getUnifiedField(investment, 'remainingCapital'),
          capitalForRestructuring: getUnifiedField(investment, 'capitalForRestructuring'),
          currentValue: currentCapitalSecured,
          shouldBe: calculatedCapitalSecured,
          hasField: hasField,
          isCorrect: isCorrect
        });
      }
    });

    return {
      statistics: {
        totalInvestments,
        withCalculatedField,
        withCorrectCalculation,
        needsUpdate,
        completionRate: `${(withCalculatedField / totalInvestments * 100).toFixed(1)}%`,
        accuracyRate: `${(withCorrectCalculation / totalInvestments * 100).toFixed(1)}%`
      },
      samples,
      recommendations: needsUpdate > 0 ? [
        `Uruchom updateCapitalSecuredByRealEstate aby zaktualizować ${needsUpdate} inwestycji`,
        "Rozważ uruchomienie najpierw z flagą dryRun=true dla testu"
      ] : [
        "Wszystkie inwestycje mają poprawnie obliczony kapitał zabezpieczony nieruchomością"
      ],
      timestamp: new Date().toISOString()
    };

  } catch (error) {
    console.error("❌ [CapitalCalculation] Błąd sprawdzania statusu:", error);
    throw new HttpsError(
      "internal",
      "Nie udało się sprawdzić statusu obliczeń",
      error.message
    );
  }
});

/**
 * Funkcja schedulowana do automatycznego przeliczania co tydzień
 * (Opcjonalnie można dodać do cron jobs)
 */
const scheduleCapitalRecalculation = onCall({
  cors: true,
}, async (request) => {
  console.log("⏰ [CapitalCalculation] Uruchamianie schedulowanego przeliczania...");

  try {
    // Najpierw sprawdź status
    const statusResult = await checkCapitalCalculationStatus({ data: {} });

    if (statusResult.statistics.needsUpdate === 0) {
      return {
        skipped: true,
        message: "Wszystkie wartości są aktualne - pominięto przeliczanie",
        statistics: statusResult.statistics,
        timestamp: new Date().toISOString()
      };
    }

    // Uruchom aktualizację
    const updateResult = await updateCapitalSecuredByRealEstate({
      data: {
        batchSize: 250,
        dryRun: false
      }
    });

    return {
      scheduled: true,
      statusBefore: statusResult.statistics,
      updateResult: {
        processed: updateResult.processed,
        updated: updateResult.updated,
        errors: updateResult.errors,
        executionTimeMs: updateResult.executionTimeMs
      },
      timestamp: new Date().toISOString()
    };

  } catch (error) {
    console.error("❌ [CapitalCalculation] Błąd schedulowanego przeliczania:", error);
    throw new HttpsError(
      "internal",
      "Nie udało się uruchomić schedulowanego przeliczania",
      error.message
    );
  }
});

module.exports = {
  updateCapitalSecuredByRealEstate,
  checkCapitalCalculationStatus,
  scheduleCapitalRecalculation
};
