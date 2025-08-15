/**
 * Test skalowania inwestycji produktu
 * 
 * Skrypt testuje funkcję Firebase Functions scaleProductInvestments
 * w środowisku lokalnym.
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const functions = require('firebase-functions-test')();

// Inicjalizuj Firebase Admin
try {
  // Próbuj użyć ServiceAccount.json jeśli istnieje, inaczej użyj domyślnych credentials
  let app;
  try {
    const serviceAccount = require('./ServiceAccount.json');
    app = initializeApp({
      credential: cert(serviceAccount),
      projectId: 'metropolitaninvestment-6aa9b'
    });
    console.log('🔥 Firebase Admin zainicjalizowane z ServiceAccount');
  } catch (serviceAccountError) {
    // Fallback do Application Default Credentials
    app = initializeApp({
      projectId: 'metropolitaninvestment-6aa9b'
    });
    console.log('🔥 Firebase Admin zainicjalizowane z domyślnymi credentials');
  }
} catch (error) {
  console.error('❌ Błąd inicjalizacji Firebase Admin:', error);
  process.exit(1);
}

const db = getFirestore();

// Import funkcji skalowania
const { scaleProductInvestments } = require('./services/investment-scaling-service');

/**
 * Test funkcji skalowania
 */
async function testInvestmentScaling() {
  console.log('\n🧪 TEST SKALOWANIA INWESTYCJI PRODUKTU\n');

  try {
    // 🔍 Znajdź przykładowy produkt z inwestycjami
    console.log('🔍 Szukam produktów z inwestycjami...');

    const investmentsSnapshot = await db.collection('investments').limit(5).get();
    if (investmentsSnapshot.empty) {
      console.log('❌ Brak inwestycji w bazie danych');
      return;
    }

    const sampleInvestment = investmentsSnapshot.docs[0].data();
    const productName = sampleInvestment.productName || sampleInvestment.nazwa_produktu;

    if (!productName) {
      console.log('❌ Brak nazwy produktu w przykładowej inwestycji');
      return;
    }

    console.log(`📋 Wybrany produkt do testu: "${productName}"`);

    // 📊 Sprawdź obecną sytuację produktu
    console.log('\n📊 Analiza obecnego stanu produktu...');

    const productInvestmentsQuery = await db.collection('investments')
      .where('productName', '==', productName)
      .get();

    let currentTotal = 0;
    productInvestmentsQuery.docs.forEach(doc => {
      const data = doc.data();
      const amount = parseFloat(data.investmentAmount || data.kwota_inwestycji || 0);
      currentTotal += amount;
    });

    console.log(`   - Liczba inwestycji: ${productInvestmentsQuery.docs.length}`);
    console.log(`   - Obecna suma: ${currentTotal.toFixed(2)} PLN`);

    if (currentTotal <= 0) {
      console.log('❌ Obecna suma wynosi 0 - nie można testować skalowania');
      return;
    }

    // 🎯 TEST 1: Skalowanie w górę (+20%)
    console.log('\n🎯 TEST 1: Skalowanie w górę (+20%)');
    const newTotalAmount = currentTotal * 1.2;

    const testData = {
      productName: productName,
      newTotalAmount: newTotalAmount,
      reason: 'Test skalowania w górę +20%',
      userId: 'test_user_123',
      userEmail: 'test@example.com'
    };

    console.log('📤 Wywołuję funkcję skalowania...');
    console.log(`   - Produkt: ${productName}`);
    console.log(`   - Nowa kwota: ${newTotalAmount.toFixed(2)} PLN`);
    console.log(`   - Współczynnik: 1.2 (120%)`);

    // Mock request object
    const mockRequest = {
      data: testData
    };

    const result = await scaleProductInvestments(mockRequest);

    console.log('\n✅ Wynik skalowania:');
    console.log(`   - Status: ${result.success ? 'Sukces' : 'Błąd'}`);
    if (result.summary) {
      console.log(`   - Poprzednia kwota: ${result.summary.previousTotalAmount.toFixed(2)} PLN`);
      console.log(`   - Nowa kwota: ${result.summary.newTotalAmount.toFixed(2)} PLN`);
      console.log(`   - Współczynnik: ${result.summary.scalingFactor.toFixed(4)}`);
      console.log(`   - Zaktualizowano inwestycji: ${result.summary.affectedInvestments}`);
      console.log(`   - Czas wykonania: ${result.summary.executionTimeMs}ms`);
    }

    if (result.details && result.details.length > 0) {
      console.log('\n📋 Szczegóły zmian (pierwsze 3):');
      result.details.slice(0, 3).forEach((detail, index) => {
        console.log(`   ${index + 1}. ${detail.clientName || detail.investmentId}:`);
        console.log(`      ${detail.oldAmount.toFixed(2)} → ${detail.newAmount.toFixed(2)} PLN`);
        console.log(`      Różnica: ${detail.difference.toFixed(2)} PLN`);
      });
    }

    // 🔄 TEST 2: Przywróć pierwotny stan (skalowanie w dół)
    console.log('\n🔄 TEST 2: Przywracanie pierwotnego stanu');

    const restoreData = {
      productName: productName,
      newTotalAmount: currentTotal,
      reason: 'Przywrócenie pierwotnego stanu po teście',
      userId: 'test_user_123',
      userEmail: 'test@example.com'
    };

    const mockRestoreRequest = {
      data: restoreData
    };

    const restoreResult = await scaleProductInvestments(mockRestoreRequest);

    console.log('✅ Przywrócenie stanu:');
    console.log(`   - Status: ${restoreResult.success ? 'Sukces' : 'Błąd'}`);
    if (restoreResult.summary) {
      console.log(`   - Przywrócono do: ${restoreResult.summary.newTotalAmount.toFixed(2)} PLN`);
      console.log(`   - Współczynnik: ${restoreResult.summary.scalingFactor.toFixed(4)}`);
    }

    // 📈 Weryfikacja końcowa
    console.log('\n📈 Weryfikacja końcowa...');
    const finalCheck = await db.collection('investments')
      .where('productName', '==', productName)
      .get();

    let finalTotal = 0;
    finalCheck.docs.forEach(doc => {
      const data = doc.data();
      const amount = parseFloat(data.investmentAmount || data.kwota_inwestycji || 0);
      finalTotal += amount;
    });

    const difference = Math.abs(finalTotal - currentTotal);
    console.log(`   - Końcowa suma: ${finalTotal.toFixed(2)} PLN`);
    console.log(`   - Oryginalna suma: ${currentTotal.toFixed(2)} PLN`);
    console.log(`   - Różnica: ${difference.toFixed(2)} PLN`);

    if (difference < 0.01) {
      console.log('✅ TEST ZAKOŃCZONY POMYŚLNIE - Stan przywrócony');
    } else {
      console.log('⚠️ UWAGA: Stan nie został w pełni przywrócony');
    }

    // 📝 Sprawdź historię
    console.log('\n📝 Sprawdzanie historii operacji...');
    const historySnapshot = await db.collection('scaling_history')
      .where('productName', '==', productName)
      .orderBy('timestamp', 'desc')
      .limit(2)
      .get();

    console.log(`   - Znaleziono ${historySnapshot.docs.length} wpisów historii`);
    historySnapshot.docs.forEach((doc, index) => {
      const histData = doc.data();
      console.log(`   ${index + 1}. ${histData.operationType} - ${histData.reason}`);
      console.log(`      Wykonane: ${histData.timestamp?.toDate?.()?.toLocaleString('pl-PL') || histData.timestamp}`);
      console.log(`      Przez: ${histData.executedBy}`);
    });

    console.log('\n🎉 TEST KOMPLETNY');

  } catch (error) {
    console.error('❌ Błąd podczas testu:', error);
    console.error('Stack trace:', error.stack);
  }
}

/**
 * Test walidacji danych wejściowych
 */
async function testValidation() {
  console.log('\n🧪 TEST WALIDACJI DANYCH WEJŚCIOWYCH\n');

  const testCases = [
    {
      name: 'Brak productId i productName',
      data: {
        newTotalAmount: 1000,
        userId: 'test',
        userEmail: 'test@example.com'
      },
      expectedError: 'invalid-argument'
    },
    {
      name: 'Ujemna kwota',
      data: {
        productName: 'Test Product',
        newTotalAmount: -100,
        userId: 'test',
        userEmail: 'test@example.com'
      },
      expectedError: 'invalid-argument'
    },
    {
      name: 'Brak danych użytkownika',
      data: {
        productName: 'Test Product',
        newTotalAmount: 1000
      },
      expectedError: 'unauthenticated'
    }
  ];

  for (const testCase of testCases) {
    console.log(`📋 Test: ${testCase.name}`);

    try {
      const mockRequest = { data: testCase.data };
      await scaleProductInvestments(mockRequest);
      console.log('❌ BŁĄD: Test powinien zakończyć się błędem');
    } catch (error) {
      if (error.code === testCase.expectedError) {
        console.log(`✅ OK: Poprawny błąd - ${error.code}`);
      } else {
        console.log(`⚠️ Nieoczekiwany błąd: ${error.code} (oczekiwano: ${testCase.expectedError})`);
      }
    }
  }
}

/**
 * Główna funkcja testowa
 */
async function main() {
  console.log('🚀 ROZPOCZYNAM TESTY SKALOWANIA INWESTYCJI\n');

  try {
    await testValidation();
    await testInvestmentScaling();
  } catch (error) {
    console.error('💥 Krytyczny błąd testu:', error);
  } finally {
    console.log('\n🏁 KONIEC TESTÓW');
    process.exit(0);
  }
}

// Uruchom testy
if (require.main === module) {
  main();
}

module.exports = {
  testInvestmentScaling,
  testValidation,
};
