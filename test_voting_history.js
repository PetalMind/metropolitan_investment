#!/usr/bin/env node

/**
 * Skrypt testowy do sprawdzania historii zmian statusów głosowania
 * Ten skrypt pomoże zdiagnozować dlaczego nie pokazuje się historia zmian
 */

const admin = require('firebase-admin');

// Inicjalizacja Firebase Admin SDK
if (!admin.apps.length) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert('./service-account.json'),
    });
    console.log('✅ Firebase Admin SDK zainicjalizowany');
  } catch (error) {
    console.error('❌ Błąd inicjalizacji Firebase:', error.message);
    process.exit(1);
  }
}

const db = admin.firestore();

async function testVotingStatusChanges() {
  console.log('🔍 Testowanie kolekcji voting_status_changes...\n');

  try {
    // Test 1: Sprawdź czy kolekcja istnieje i ma dokumenty
    console.log('📊 Test 1: Sprawdzanie istnienia kolekcji...');
    const allChangesSnapshot = await db
      .collection('voting_status_changes')
      .limit(5)
      .get();

    console.log(`   Znaleziono ${allChangesSnapshot.size} dokumentów w kolekcji`);

    if (allChangesSnapshot.empty) {
      console.log('❌ Kolekcja voting_status_changes jest pusta!');
      return;
    }

    // Test 2: Wyświetl przykładowe dokumenty
    console.log('\n📋 Test 2: Przykładowe dokumenty:');
    allChangesSnapshot.docs.forEach((doc, index) => {
      const data = doc.data();
      console.log(`   ${index + 1}. Dokument ID: ${doc.id}`);
      console.log(`      clientId: ${data.clientId}`);
      console.log(`      investorId: ${data.investorId}`);
      console.log(`      clientName: ${data.clientName}`);
      console.log(`      changeType: ${data.changeType}`);
      console.log(`      changedAt: ${data.changedAt?.toDate()}`);
      console.log(`      editedBy: ${data.editedBy}`);
      console.log('');
    });

    // Test 3: Sprawdź konkretne ID z pytania użytkownika
    const testId = 'e2cc299f-d3f4-4d09-bd81-5a714b6048d2';
    console.log(`🎯 Test 3: Sprawdzanie zmian dla ID: ${testId}`);

    // Zapytanie po investorId (jak w kodzie)
    const investorChanges = await db
      .collection('voting_status_changes')
      .where('investorId', '==', testId)
      .orderBy('changedAt', 'desc')
      .limit(10)
      .get();

    console.log(`   Zapytanie po investorId: znaleziono ${investorChanges.size} wyników`);

    // Zapytanie po clientId (alternatywa)
    const clientChanges = await db
      .collection('voting_status_changes')
      .where('clientId', '==', testId)
      .orderBy('changedAt', 'desc')
      .limit(10)
      .get();

    console.log(`   Zapytanie po clientId: znaleziono ${clientChanges.size} wyników`);

    // Test 4: Wyświetl szczegóły znalezionych zmian
    if (!investorChanges.empty) {
      console.log('\n✅ Test 4: Szczegóły zmian znalezionych po investorId:');
      investorChanges.docs.forEach((doc, index) => {
        const data = doc.data();
        console.log(`   ${index + 1}. ${data.changedAt?.toDate()?.toLocaleString()}: ${data.changeType}`);
        console.log(`      ${data.previousVotingStatus} → ${data.newVotingStatus}`);
        console.log(`      Edytował: ${data.editedBy} (${data.editedByEmail})`);
        if (data.reason) console.log(`      Powód: ${data.reason}`);
        console.log('');
      });
    } else {
      console.log('❌ Brak zmian dla podanego ID mimo że widzę je w bazie!');

      // Sprawdźmy wszystkie dokumenty z tym clientName
      console.log('\n🔍 Sprawdzanie po nazwie klienta...');
      const nameChanges = await db
        .collection('voting_status_changes')
        .where('clientName', '==', 'Piotr Wawro')
        .get();

      console.log(`   Znaleziono ${nameChanges.size} dokumentów dla "Piotr Wawro"`);
      nameChanges.docs.forEach(doc => {
        const data = doc.data();
        console.log(`      ID: ${doc.id}, investorId: ${data.investorId}, clientId: ${data.clientId}`);
      });
    }

    // Test 5: Sprawdź indeksy
    console.log('\n🏗️  Test 5: Status indeksów (informacyjnie)');
    console.log('   Dla zapytań po investorId + changedAt potrzebujesz indeksu kompozytowego');
    console.log('   Sprawdź Firebase Console → Firestore → Indexes');

  } catch (error) {
    console.error('❌ Błąd podczas testowania:', error);

    if (error.code === 9) {
      console.log('\n💡 Błąd FAILED_PRECONDITION - prawdopodobnie brakuje indeksu!');
      console.log('   Wdróż indeksy za pomocą: ./deploy_indexes.sh');
    }
  }
}

// Uruchom test
testVotingStatusChanges()
  .then(() => {
    console.log('🏁 Test zakończony');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Nieoczekiwany błąd:', error);
    process.exit(1);
  });
