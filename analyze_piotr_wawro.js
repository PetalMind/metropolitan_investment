#!/usr/bin/env node

/**
 * Skrypt do analizy klientów o nazwie "Piotr Wawro"
 * Sprawdza czy są duplikaty i jakie mają ID
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

async function analyzePiotrWawro() {
  console.log('🔍 Analiza klientów "Piotr Wawro"...\n');

  try {
    // 1. Znajdź wszystkich klientów o nazwie "Piotr Wawro"
    console.log('📊 Szukanie klientów po name...');
    const nameQuery = await db
      .collection('clients')
      .where('name', '==', 'Piotr Wawro')
      .get();

    console.log(`   Znaleziono ${nameQuery.size} klientów po 'name'`);

    // 2. Szukanie po imie_nazwisko (Excel format)
    console.log('📊 Szukanie klientów po imie_nazwisko...');
    const imieNazwiskoQuery = await db
      .collection('clients')
      .where('imie_nazwisko', '==', 'Piotr Wawro')
      .get();

    console.log(`   Znaleziono ${imieNazwiskoQuery.size} klientów po 'imie_nazwisko'`);

    // 3. Połącz wyniki i usuń duplikaty
    const allDocs = new Map();

    nameQuery.docs.forEach(doc => allDocs.set(doc.id, doc));
    imieNazwiskoQuery.docs.forEach(doc => allDocs.set(doc.id, doc));

    console.log(`\n📋 WSZYSTKICH UNIKALNYCH KLIENTÓW: ${allDocs.size}`);
    console.log('════════════════════════════════════════════════════');

    let index = 1;
    for (const [docId, doc] of allDocs) {
      const data = doc.data();
      console.log(`\n${index}. KLIENT:`);
      console.log(`   🆔 Firestore ID: ${docId}`);
      console.log(`   📝 name: "${data.name}"`);
      console.log(`   📝 imie_nazwisko: "${data.imie_nazwisko}"`);
      console.log(`   📧 email: "${data.email}"`);
      console.log(`   📞 telefon: "${data.telefon}"`);
      console.log(`   🗳️  votingStatus: ${data.votingStatus}`);
      console.log(`   💼 type: ${data.type}`);
      console.log(`   ✅ isActive: ${data.isActive}`);
      console.log(`   📅 updatedAt: ${data.updatedAt?.toDate()}`);

      if (data.excelId) {
        console.log(`   📊 excelId: ${data.excelId}`);
      }
      if (data.original_id) {
        console.log(`   📊 original_id: ${data.original_id}`);
      }

      index++;
    }

    // 4. Sprawdź historię zmian dla każdego znalezionego ID
    console.log('\n🔍 SPRAWDZANIE HISTORII ZMIAN:');
    console.log('════════════════════════════════════════════════════');

    for (const [docId, doc] of allDocs) {
      console.log(`\n🎯 Historia dla ID: ${docId}`);

      // Zapytanie po investorId
      const investorChanges = await db
        .collection('voting_status_changes')
        .where('investorId', '==', docId)
        .orderBy('changedAt', 'desc')
        .get();

      console.log(`   📊 Zapytanie po investorId: ${investorChanges.size} wyników`);

      // Zapytanie po clientId  
      const clientChanges = await db
        .collection('voting_status_changes')
        .where('clientId', '==', docId)
        .orderBy('changedAt', 'desc')
        .get();

      console.log(`   📊 Zapytanie po clientId: ${clientChanges.size} wyników`);

      // Pokaż szczegóły zmian
      if (investorChanges.size > 0) {
        investorChanges.docs.forEach((changeDoc, i) => {
          const changeData = changeDoc.data();
          console.log(`      ${i + 1}. ${changeData.changedAt?.toDate()?.toLocaleString()}`);
          console.log(`         ${changeData.previousVotingStatus} → ${changeData.newVotingStatus}`);
          console.log(`         By: ${changeData.editedBy}`);
        });
      }
    }

    // 5. Sprawdź czy są zmiany dla ID z logów aplikacji
    const appId = 'eb3ab782-f801-46c3-b8f5-7532b328ae0e';
    const dbId = 'e2cc299f-d3f4-4d09-bd81-5a714b6048d2';

    console.log('\n🎯 TESTOWANIE KONKRETNYCH ID:');
    console.log('════════════════════════════════════════════════════');

    console.log(`\n📱 ID z aplikacji: ${appId}`);
    const appIdChanges = await db
      .collection('voting_status_changes')
      .where('investorId', '==', appId)
      .get();
    console.log(`   Historia zmian: ${appIdChanges.size} dokumentów`);

    console.log(`\n💾 ID z bazy zmian: ${dbId}`);
    const dbIdChanges = await db
      .collection('voting_status_changes')
      .where('investorId', '==', dbId)
      .get();
    console.log(`   Historia zmian: ${dbIdChanges.size} dokumentów`);

    // Sprawdź czy te ID istnieją w kolekcji clients
    try {
      const appClient = await db.collection('clients').doc(appId).get();
      console.log(`   📱 Klient z ID aplikacji istnieje: ${appClient.exists}`);
      if (appClient.exists) {
        const appData = appClient.data();
        console.log(`      Nazwa: ${appData?.name || appData?.imie_nazwisko}`);
      }
    } catch (e) {
      console.log(`   📱 Błąd sprawdzania klienta z aplikacji: ${e.message}`);
    }

    try {
      const dbClient = await db.collection('clients').doc(dbId).get();
      console.log(`   💾 Klient z ID bazy zmian istnieje: ${dbClient.exists}`);
      if (dbClient.exists) {
        const dbData = dbClient.data();
        console.log(`      Nazwa: ${dbData?.name || dbData?.imie_nazwisko}`);
      }
    } catch (e) {
      console.log(`   💾 Błąd sprawdzania klienta z bazy: ${e.message}`);
    }

  } catch (error) {
    console.error('❌ Błąd analizy:', error);
  }
}

// Uruchom analizę
analyzePiotrWawro()
  .then(() => {
    console.log('\n🏁 Analiza zakończona');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Nieoczekiwany błąd:', error);
    process.exit(1);
  });
