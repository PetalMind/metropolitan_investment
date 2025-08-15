/**
 * Investment Scaling Service
 * 
 * Serwis obsługujący proporcjonalne skalowanie inwestycji w ramach produktu.
 * Pozwala na zmianę całkowitej kwoty produktu z automatycznym przeskalowaniem
 * udziałów wszystkich inwestorów proporcjonalnie.
 * 
 * 🎯 KLUCZOWE FUNKCJONALNOŚCI:
 * • Proporcjonalne skalowanie kwot inwestycji
 * • Zachowanie proporcji między inwestorami
 * • Transakcyjne aktualizacje (atomicity)
 * • Walidacja danych wejściowych
 * • Historia zmian i audyting
 */

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const { db } = require("../utils/firebase-config");
const { safeToDouble } = require("../utils/data-mapping");

/**
 * Skaluje proporcjonalnie wszystkie inwestycje w ramach produktu
 * 
 * @param {Object} data - Dane wejściowe
 * @param {string} data.productId - ID produktu (może być logiczne lub UUID)
 * @param {string} data.productName - Nazwa produktu (fallback dla identyfikacji)
 * @param {number} data.newTotalAmount - Nowa całkowita kwota produktu
 * @param {string} data.reason - Powód zmiany (opcjonalnie)
 * @param {string} data.userId - ID użytkownika wykonującego zmianę
 * @param {string} data.userEmail - Email użytkownika
 * 
 * @returns {Object} Wynik operacji z szczegółami zmian
 */
const scaleProductInvestments = onCall(async (request) => {
  const startTime = Date.now();
  console.log(`🎯 [InvestmentScaling] Rozpoczynam skalowanie inwestycji produktu`);
  console.log(`📊 [InvestmentScaling] Dane wejściowe:`, JSON.stringify(request.data, null, 2));

  try {
    const {
      productId,
      productName,
      newTotalAmount,
      reason = 'Proporcjonalne skalowanie kwoty produktu',
      userId,
      userEmail,
      companyId,
      creditorCompany
    } = request.data;

    // 🔍 WALIDACJA DANYCH WEJŚCIOWYCH
    if (!productId && !productName) {
      throw new HttpsError(
        'invalid-argument',
        'Wymagany jest productId lub productName'
      );
    }

    if (!newTotalAmount || newTotalAmount <= 0) {
      throw new HttpsError(
        'invalid-argument',
        'newTotalAmount musi być liczbą większą od 0'
      );
    }

    if (!userId || !userEmail) {
      throw new HttpsError(
        'unauthenticated',
        'Wymagane są dane użytkownika (userId i userEmail)'
      );
    }

    // 🔍 ZNAJDOWANIE INWESTYCJI PRODUKTU
    console.log(`🔍 [InvestmentScaling] Wyszukuję inwestycje dla produktu...`);

    let query = db.collection('investments');

    // Strategia wyszukiwania - podobnie jak w investor_edit_dialog.dart
    if (productId) {
      // Pierwsza próba: po productId
      query = query.where('productId', '==', productId);
    } else {
      // Fallback: po nazwie produktu
      query = query.where('productName', '==', productName);
    }

    const investmentsSnapshot = await query.get();

    // Jeśli nie ma wyników, spróbuj alternatywnych strategii
    let investments = [];
    if (!investmentsSnapshot.empty) {
      investments = investmentsSnapshot.docs;
    } else {
      console.log(`⚠️ [InvestmentScaling] Nie znaleziono po productId, próbuję alternatywnych strategii...`);

      // Fallback 1: po nazwie produktu (case-insensitive)
      if (productName) {
        const allInvestments = await db.collection('investments').get();
        investments = allInvestments.docs.filter(doc => {
          const data = doc.data();
          return data.productName &&
            data.productName.trim().toLowerCase() === productName.trim().toLowerCase();
        });
      }

      // Fallback 2: po companyId i creditorCompany (jeśli podane)
      if (investments.length === 0 && (companyId || creditorCompany)) {
        const allInvestments = await db.collection('investments').get();
        investments = allInvestments.docs.filter(doc => {
          const data = doc.data();
          return (productName && data.productName &&
            data.productName.trim().toLowerCase() === productName.trim().toLowerCase()) &&
            ((companyId && data.companyId === companyId) ||
              (creditorCompany && data.creditorCompany === creditorCompany));
        });
      }
    }

    if (investments.length === 0) {
      throw new HttpsError(
        'not-found',
        `Nie znaleziono inwestycji dla produktu ${productId || productName}`
      );
    }

    console.log(`✅ [InvestmentScaling] Znaleziono ${investments.length} inwestycji do skalowania`);

    // 🧮 OBLICZANIE AKTUALNEJ CAŁKOWITEJ KWOTY I WSPÓŁCZYNNIKA SKALOWANIA
    let currentTotalAmount = 0;
    const investmentData = [];

    for (const doc of investments) {
      const data = doc.data();
      const investmentAmount = safeToDouble(data.investmentAmount || data.kwota_inwestycji || 0);
      currentTotalAmount += investmentAmount;

      investmentData.push({
        id: doc.id,
        data: data,
        currentAmount: investmentAmount,
        remainingCapital: safeToDouble(data.remainingCapital || data.kapital_pozostaly || 0),
        capitalSecured: safeToDouble(data.capitalSecuredByRealEstate || data.kapital_zabezpieczony_nieruchomoscami || 0),
        capitalForRestructuring: safeToDouble(data.capitalForRestructuring || data.kapital_do_restrukturyzacji || 0),
      });
    }

    if (currentTotalAmount <= 0) {
      throw new HttpsError(
        'invalid-argument',
        'Aktualna całkowita kwota produktu wynosi 0 - nie można skalować'
      );
    }

    const scalingFactor = newTotalAmount / currentTotalAmount;

    console.log(`📊 [InvestmentScaling] Szczegóły skalowania:`);
    console.log(`   - Aktualna kwota: ${currentTotalAmount.toFixed(2)} PLN`);
    console.log(`   - Nowa kwota: ${newTotalAmount.toFixed(2)} PLN`);
    console.log(`   - Współczynnik skalowania: ${scalingFactor.toFixed(6)}`);
    console.log(`   - Liczba inwestycji: ${investmentData.length}`);

    // 🔄 TRANSAKCYJNE AKTUALIZACJE
    console.log(`🔄 [InvestmentScaling] Rozpoczynam transakcyjne aktualizacje...`);

    const batch = db.batch();
    const updateDetails = [];
    const timestamp = new Date();

    for (const investment of investmentData) {
      const newInvestmentAmount = investment.currentAmount * scalingFactor;
      const newRemainingCapital = investment.remainingCapital * scalingFactor;
      const newCapitalSecured = investment.capitalSecured * scalingFactor;
      const newCapitalForRestructuring = investment.capitalForRestructuring * scalingFactor;

      // Przygotuj dane do aktualizacji
      const updateData = {
        // Zaktualizowane kwoty finansowe
        investmentAmount: newInvestmentAmount,
        remainingCapital: newRemainingCapital,
        capitalSecuredByRealEstate: newCapitalSecured,
        capitalForRestructuring: newCapitalForRestructuring,

        // Metadane aktualizacji
        updatedAt: timestamp,
        lastScaledAt: timestamp,
        lastScalingFactor: scalingFactor,
        scalingReason: reason,
        scaledBy: userEmail,
        scaledByUserId: userId,
      };

      // Dodaj do batcha
      const docRef = db.collection('investments').doc(investment.id);
      batch.update(docRef, updateData);

      // Zapisz szczegóły do raportu
      updateDetails.push({
        investmentId: investment.id,
        clientId: investment.data.clientId || investment.data.ID_Klient,
        clientName: investment.data.clientName || investment.data.imie_nazwisko,
        oldAmount: investment.currentAmount,
        newAmount: newInvestmentAmount,
        difference: newInvestmentAmount - investment.currentAmount,
        scalingFactor: scalingFactor,
      });

      console.log(`   📝 ${investment.id}: ${investment.currentAmount.toFixed(2)} → ${newInvestmentAmount.toFixed(2)} PLN`);
    }

    // Wykonaj batch
    await batch.commit();
    console.log(`✅ [InvestmentScaling] Pomyślnie zaktualizowano ${investmentData.length} inwestycji`);

    // 📝 ZAPISZ HISTORIĘ OPERACJI (opcjonalnie - do osobnej kolekcji)
    try {
      const historyDoc = {
        productId: productId,
        productName: productName,
        operationType: 'PRODUCT_SCALING',
        timestamp: timestamp,
        executedBy: userEmail,
        executedByUserId: userId,
        reason: reason,

        // Szczegóły skalowania
        previousTotalAmount: currentTotalAmount,
        newTotalAmount: newTotalAmount,
        scalingFactor: scalingFactor,
        affectedInvestmentsCount: investmentData.length,

        // Szczegóły zmian
        updateDetails: updateDetails,

        // Metadane
        executionTimeMs: Date.now() - startTime,
        serverTimestamp: timestamp,
      };

      await db.collection('scaling_history').add(historyDoc);
      console.log(`📝 [InvestmentScaling] Zapisano historię operacji`);
    } catch (historyError) {
      console.warn(`⚠️ [InvestmentScaling] Nie udało się zapisać historii:`, historyError);
      // Nie przerywamy operacji - historia jest opcjonalna
    }

    // 🎯 ZWRÓĆ WYNIK OPERACJI
    const result = {
      success: true,
      summary: {
        productId: productId,
        productName: productName,
        previousTotalAmount: currentTotalAmount,
        newTotalAmount: newTotalAmount,
        scalingFactor: scalingFactor,
        affectedInvestments: investmentData.length,
        executionTimeMs: Date.now() - startTime,
      },
      details: updateDetails,
      timestamp: timestamp.toISOString(),
    };

    console.log(`🎉 [InvestmentScaling] Operacja zakończona pomyślnie w ${Date.now() - startTime}ms`);
    return result;

  } catch (error) {
    console.error(`❌ [InvestmentScaling] Błąd podczas skalowania:`, error);

    if (error instanceof HttpsError) {
      throw error;
    } else {
      throw new HttpsError(
        'internal',
        'Błąd podczas skalowania inwestycji produktu',
        error.message
      );
    }
  }
});

module.exports = {
  scaleProductInvestments,
};
