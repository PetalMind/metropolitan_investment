const admin = require('firebase-admin');

// Test połączenia z Firebase
async function testFirebaseConnection() {
  try {
    console.log('🔗 Testowanie połączenia z Firebase...');

    // Sprawdź czy Firebase jest zainicjalizowane
    if (admin.apps.length === 0) {
      console.log('⚠️  Firebase nie został zainicjalizowany');
      console.log('Inicjalizuję z domyślnymi ustawieniami...');

      // Próba inicjalizacji z service-account.json
      try {
        const serviceAccount = require('./service-account.json');
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount)
        });
        console.log('✅ Firebase zainicjalizowany z service-account.json');
      } catch (error) {
        console.log('❌ Nie można załadować service-account.json');
        console.log('Spróbuj z zmiennymi środowiskowymi...');

        admin.initializeApp({
          credential: admin.credential.applicationDefault()
        });
        console.log('✅ Firebase zainicjalizowany z domyślnymi credentials');
      }
    }

    const db = admin.firestore();

    // Test połączenia - spróbuj pobrać informacje o bazie
    console.log('📡 Sprawdzanie połączenia z Firestore...');

    const testCollection = db.collection('test');
    const testDoc = testCollection.doc('connection-test');

    await testDoc.set({
      timestamp: admin.firestore.Timestamp.now(),
      message: 'Connection test successful',
      version: 'v1.0'
    });

    console.log('✅ Zapisano dokument testowy');

    const snapshot = await testDoc.get();
    if (snapshot.exists) {
      console.log('✅ Odczytano dokument testowy:', snapshot.data());
    }

    // Usuń dokument testowy
    await testDoc.delete();
    console.log('🧹 Usunięto dokument testowy');

    // Sprawdź istniejące kolekcje
    console.log('📊 Sprawdzanie istniejących kolekcji...');
    const collections = await db.listCollections();
    console.log('Znalezione kolekcje:');
    collections.forEach(collection => {
      console.log(`  - ${collection.id}`);
    });

    // Sprawdź liczbę dokumentów w głównych kolekcjach
    const mainCollections = ['clients', 'investments', 'employees'];
    for (const collectionName of mainCollections) {
      try {
        const snapshot = await db.collection(collectionName).limit(1).get();
        console.log(`  📁 ${collectionName}: ${snapshot.empty ? 'pusta' : 'zawiera dokumenty'}`);
      } catch (error) {
        console.log(`  ❌ ${collectionName}: błąd dostępu`);
      }
    }

    console.log('\n🎉 Połączenie z Firebase działa poprawnie!');

  } catch (error) {
    console.error('❌ Błąd połączenia z Firebase:');
    console.error(error.message);
    console.error('\n🔧 Sprawdź:');
    console.error('1. Czy plik serviceAccountKey.json istnieje i jest poprawny');
    console.error('2. Czy zmienne środowiskowe GOOGLE_APPLICATION_CREDENTIALS są ustawione');
    console.error('3. Czy masz uprawnienia do bazy danych');
    console.error('4. Czy projekt Firebase jest aktywny');

    process.exit(1);
  }
}

if (require.main === module) {
  testFirebaseConnection();
}

module.exports = { testFirebaseConnection };
