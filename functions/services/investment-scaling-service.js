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

/**
 * 🚀 NOWA FUNKCJA: Skaluje TYLKO kapitał pozostały (pozostawia investmentAmount bez zmian)
 * 
 * @param {string} data.productId - ID produktu do skalowania
 * @param {string} data.productName - Nazwa produktu (fallback)
 * @param {number} data.newTotalRemainingCapital - Nowa całkowita kwota kapitału pozostałego
 * @param {string} data.reason - Powód skalowania
 * @param {string} data.userId - ID użytkownika
 * @param {string} data.userEmail - Email użytkownika
 * 
 * @returns {Object} Wynik operacji z szczegółami zmian
 */
const scaleRemainingCapitalOnly = onCall(async (request) => {
  const startTime = Date.now();
  console.log(`🎯 [RemainingCapitalScaling] Rozpoczynam skalowanie TYLKO kapitału pozostałego`);
  console.log(`📊 [RemainingCapitalScaling] Dane wejściowe:`, JSON.stringify(request.data, null, 2));

  try {
    const {
      productId,
      productName,
      newTotalRemainingCapital,
      reason = 'Skalowanie kapitału pozostałego (bez zmiany sumy inwestycji)',
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

    if (!newTotalRemainingCapital || newTotalRemainingCapital <= 0) {
      throw new HttpsError(
        'invalid-argument',
        'newTotalRemainingCapital musi być liczbą większą od 0'
      );
    }

    if (!userId || !userEmail) {
      throw new HttpsError(
        'unauthenticated',
        'Wymagane są dane użytkownika (userId i userEmail)'
      );
    }

    // 🔍 ZNAJDOWANIE INWESTYCJI PRODUKTU (identyczna logika jak w scaleProductInvestments)
    console.log(`🔍 [RemainingCapitalScaling] Wyszukuję inwestycje dla produktu...`);

    let query = db.collection('investments');

    if (productId) {
      query = query.where('productId', '==', productId);
    } else {
      query = query.where('productName', '==', productName);
    }

    const investmentsSnapshot = await query.get();

    let investments = [];
    if (!investmentsSnapshot.empty) {
      investments = investmentsSnapshot.docs;
    } else {
      console.log(`⚠️ [RemainingCapitalScaling] Nie znaleziono po productId, próbuję alternatywnych strategii...`);

      if (productName) {
        const allInvestments = await db.collection('investments').get();
        investments = allInvestments.docs.filter(doc => {
          const data = doc.data();
          return data.productName &&
            data.productName.trim().toLowerCase() === productName.trim().toLowerCase();
        });
      }

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

    console.log(`✅ [RemainingCapitalScaling] Znaleziono ${investments.length} inwestycji do skalowania`);

    // 🧮 OBLICZANIE AKTUALNEGO KAPITAŁU POZOSTAŁEGO I SPRAWDZENIE SUMY INWESTYCJI
    let currentTotalRemainingCapital = 0;
    let totalInvestmentAmount = 0;
    const investmentData = [];

    for (const doc of investments) {
      const data = doc.data();
      const investmentAmount = safeToDouble(data.investmentAmount || data.kwota_inwestycji || 0);
      const remainingCapital = safeToDouble(data.remainingCapital || data.kapital_pozostaly || 0);

      currentTotalRemainingCapital += remainingCapital;
      totalInvestmentAmount += investmentAmount;

      investmentData.push({
        id: doc.id,
        data: data,
        investmentAmount: investmentAmount, // 🚫 NIE ZMIENIA SIĘ
        remainingCapital: remainingCapital,
        capitalSecured: safeToDouble(data.capitalSecuredByRealEstate || data.kapital_zabezpieczony_nieruchomoscami || 0),
        capitalForRestructuring: safeToDouble(data.capitalForRestructuring || data.kapital_do_restrukturyzacji || 0),
      });
    }

    // 🚫 WALIDACJA: Sprawdź czy nowy kapitał nie przekracza sumy inwestycji
    if (newTotalRemainingCapital > totalInvestmentAmount) {
      throw new HttpsError(
        'invalid-argument',
        `Nowy kapitał pozostały (${newTotalRemainingCapital.toFixed(2)}) nie może być większy niż suma inwestycji (${totalInvestmentAmount.toFixed(2)})`
      );
    }

    if (currentTotalRemainingCapital <= 0) {
      throw new HttpsError(
        'invalid-argument',
        'Aktualny kapitał pozostały wynosi 0 - nie można skalować'
      );
    }

    const scalingFactor = newTotalRemainingCapital / currentTotalRemainingCapital;

    console.log(`📊 [RemainingCapitalScaling] Szczegóły skalowania:`);
    console.log(`   - Aktualny kapitał pozostały: ${currentTotalRemainingCapital.toFixed(2)} PLN`);
    console.log(`   - Nowy kapitał pozostały: ${newTotalRemainingCapital.toFixed(2)} PLN`);
    console.log(`   - Suma inwestycji (NIEZMIENIONA): ${totalInvestmentAmount.toFixed(2)} PLN`);
    console.log(`   - Współczynnik skalowania: ${scalingFactor.toFixed(6)}`);
    console.log(`   - Liczba inwestycji: ${investmentData.length}`);

    // 🔄 TRANSAKCYJNE AKTUALIZACJE (TYLKO remainingCapital i powiązane pola)
    console.log(`🔄 [RemainingCapitalScaling] Rozpoczynam transakcyjne aktualizacje...`);

    const batch = db.batch();
    const updateDetails = [];
    const timestamp = new Date();

    for (const investment of investmentData) {
      const newRemainingCapital = investment.remainingCapital * scalingFactor;
      const newCapitalSecured = investment.capitalSecured * scalingFactor;
      const newCapitalForRestructuring = investment.capitalForRestructuring * scalingFactor;

      // 🚫 WAŻNE: investmentAmount pozostaje NIEZMIENIONE
      const updateData = {
        // ✅ Zaktualizowane kwoty kapitału
        remainingCapital: newRemainingCapital,
        capitalSecuredByRealEstate: newCapitalSecured,
        capitalForRestructuring: newCapitalForRestructuring,

        // 🚫 investmentAmount NIE JEST AKTUALIZOWANE!

        // Metadane aktualizacji
        updatedAt: timestamp,
        lastScaledAt: timestamp,
        lastScalingFactor: scalingFactor,
        scalingReason: reason,
        scaledBy: userEmail,
        scaledByUserId: userId,
        scalingType: 'remaining_capital_only', // 🏷️ Oznacz typ skalowania
      };

      const docRef = db.collection('investments').doc(investment.id);
      batch.update(docRef, updateData);

      updateDetails.push({
        investmentId: investment.id,
        clientId: investment.data.clientId || investment.data.ID_Klient,
        clientName: investment.data.clientName || investment.data.imie_nazwisko,
        oldRemainingCapital: investment.remainingCapital,
        newRemainingCapital: newRemainingCapital,
        investmentAmount: investment.investmentAmount, // 🚫 NIEZMIENIONE
        scalingFactor: scalingFactor,
      });
    }

    // Wykonaj batch update
    await batch.commit();
    console.log(`✅ [RemainingCapitalScaling] Zaktualizowano ${investmentData.length} inwestycji`);

    const result = {
      success: true,
      message: `Pomyślnie zaktualizowano kapitał pozostały dla ${investmentData.length} inwestycji`,
      summary: {
        scalingType: 'remaining_capital_only',
        productId: productId,
        productName: productName,
        previousTotalRemainingCapital: currentTotalRemainingCapital,
        newTotalRemainingCapital: newTotalRemainingCapital,
        totalInvestmentAmount: totalInvestmentAmount, // 🚫 NIEZMIENIONE
        scalingFactor: scalingFactor,
        affectedInvestments: investmentData.length,
        executionTimeMs: Date.now() - startTime,
      },
      details: updateDetails,
      timestamp: timestamp.toISOString(),
    };

    console.log(`🎉 [RemainingCapitalScaling] Operacja zakończona pomyślnie w ${Date.now() - startTime}ms`);
    return result;

  } catch (error) {
    console.error(`❌ [RemainingCapitalScaling] Błąd podczas skalowania:`, error);

    if (error instanceof HttpsError) {
      throw error;
    } else {
      throw new HttpsError(
        'internal',
        'Błąd podczas skalowania kapitału pozostałego',
        error.message
      );
    }
  }
});

module.exports = {
  scaleProductInvestments,
  scaleRemainingCapitalOnly, // 🚀 NOWA FUNKCJA
};
