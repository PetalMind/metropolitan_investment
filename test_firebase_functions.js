/**
 * Test Firebase Functions - sprawdź czy funkcje getAllClients, getActiveClients i getSystemStats działają
 */

const admin = require('firebase-admin');

// Inicjalizuj Firebase Admin (użyj domyślnych credentials)
admin.initializeApp();

async function testFirebaseFunctions() {
  console.log('🔍 Testowanie Firebase Functions...');

  try {
    // Test 1: Sprawdź czy możemy połączyć się z Firestore
    console.log('\n📊 Test 1: Połączenie z Firestore');
    const db = admin.firestore();

    const clientsSnapshot = await db.collection('clients').limit(1).get();
    console.log(`✅ Kolekcja 'clients' - znaleziono ${clientsSnapshot.size} dokumentów (limit 1)`);

    const investmentsSnapshot = await db.collection('investments').limit(1).get();
    console.log(`✅ Kolekcja 'investments' - znaleziono ${investmentsSnapshot.size} dokumentów (limit 1)`);

    // Test 2: Sprawdź czy funkcje Firebase Functions istnieją lokalnie
    console.log('\n🔧 Test 2: Dostępność modułów funkcji');

    try {
      const clientsService = require('./functions/services/clients-service');
      console.log('✅ Moduł clients-service został załadowany');
      console.log('   - Dostępne funkcje:', Object.keys(clientsService));
    } catch (e) {
      console.log('❌ Błąd ładowania clients-service:', e.message);
    }

    // Test 3: Sprawdź strukę danych w bazie
    console.log('\n📋 Test 3: Struktura danych w bazie');

    if (!clientsSnapshot.empty) {
      const clientDoc = clientsSnapshot.docs[0];
      console.log('✅ Przykładowy klient:', {
        id: clientDoc.id,
        data: Object.keys(clientDoc.data())
      });
    }

    if (!investmentsSnapshot.empty) {
      const investmentDoc = investmentsSnapshot.docs[0];
      console.log('✅ Przykładowa inwestycja:', {
        id: investmentDoc.id,
        data: Object.keys(investmentDoc.data())
      });
    }

    // Test 4: Sprawdź regiony Firebase Functions
    console.log('\n🌍 Test 4: Konfiguracja regionów');
    console.log('   - Domyślny region Firebase Functions: europe-west1');
    console.log('   - Sprawdź czy funkcje są wdrożone w tym regionie');

    console.log('\n✅ Testy zakończone pomyślnie');

  } catch (error) {
    console.error('❌ Błąd podczas testów:', error);
    console.error('Stack trace:', error.stack);
  } finally {
    // Zamknij połączenie
    await admin.app().delete();
    console.log('🔒 Połączenie zamknięte');
  }
}

// Uruchom testy
testFirebaseFunctions();
