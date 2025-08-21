// Debug script dla enhanced_clients_screen.dart
// Test czy getClientsByIds poprawnie pobiera pełne dane klientów

const admin = require('firebase-admin');

// Inicjalizacja Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function testClientDataStructure() {
  console.log('🔍 Test struktury danych klientów w Firestore');
  console.log('=============================================');

  try {
    // Pobierz pierwszych 5 klientów do analizy
    const snapshot = await db.collection('clients').limit(5).get();

    console.log(`📋 Znaleziono ${snapshot.docs.length} klientów`);

    snapshot.docs.forEach((doc, index) => {
      const data = doc.data();
      console.log(`\n👤 Klient ${index + 1}: ${doc.id}`);
      console.log(`   - Nazwa: ${data.fullName || data.imie_nazwisko || data.name || '(brak)'}`);
      console.log(`   - Email: "${data.email || '(pusty)'}"`);
      console.log(`   - Telefon: "${data.phone || data.telefon || '(brak)'}"`);
      console.log(`   - Adres: "${data.address || '(pusty)'}"`);
      console.log(`   - ExcelId: ${data.excelId || data.original_id || '(brak)'}`);
      console.log(`   - IsActive: ${data.isActive}`);
      console.log(`   - Type: ${data.type || '(brak)'}`);
      console.log(`   - VotingStatus: ${data.votingStatus || '(brak)'}`);

      // Sprawdź additionalInfo
      if (data.additionalInfo) {
        console.log(`   - AdditionalInfo keys: ${Object.keys(data.additionalInfo).join(', ')}`);
      }

      // Sprawdź wszystkie dostępne pola
      const allFields = Object.keys(data);
      console.log(`   - Wszystkie pola (${allFields.length}): ${allFields.join(', ')}`);
    });

    console.log('\n✅ Test zakończony');

  } catch (error) {
    console.error('❌ Błąd podczas testowania:', error);
  }
}

async function testSpecificClientIds() {
  console.log('\n🎯 Test pobierania klientów przez IDs');
  console.log('===================================');

  try {
    // Pobierz kilka konkretnych IDs (jak w OptimizedInvestor)
    const testIds = ['1008', '1001', '1002']; // Przykładowe IDs

    console.log(`📋 Szukam klientów o IDs: ${testIds.join(', ')}`);

    // Test 1: Szukaj po document ID
    for (const id of testIds) {
      try {
        const doc = await db.collection('clients').doc(id).get();
        if (doc.exists) {
          const data = doc.data();
          console.log(`✅ Znaleziono po doc.id="${id}": ${data.fullName || data.name}`);
        } else {
          console.log(`❌ Nie znaleziono po doc.id="${id}"`);
        }
      } catch (error) {
        console.log(`❌ Błąd przy doc.id="${id}": ${error.message}`);
      }
    }

    // Test 2: Szukaj po excelId
    for (const id of testIds) {
      try {
        const snapshot = await db.collection('clients')
          .where('excelId', '==', id)
          .limit(1)
          .get();

        if (!snapshot.empty) {
          const data = snapshot.docs[0].data();
          console.log(`✅ Znaleziono po excelId="${id}": ${data.fullName || data.name} (doc.id: ${snapshot.docs[0].id})`);
        } else {
          console.log(`❌ Nie znaleziono po excelId="${id}"`);
        }
      } catch (error) {
        console.log(`❌ Błąd przy excelId="${id}": ${error.message}`);
      }
    }

  } catch (error) {
    console.error('❌ Błąd podczas testowania IDs:', error);
  }
}

// Uruchom testy
async function runAllTests() {
  await testClientDataStructure();
  await testSpecificClientIds();
  process.exit(0);
}

runAllTests();
