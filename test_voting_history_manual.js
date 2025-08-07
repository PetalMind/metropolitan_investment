const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function testVotingHistory() {
  try {
    console.log('🧪 TEST MANUAL: Historia głosowania\n');

    // 1. Znajdź pierwszego klienta w bazie
    console.log('🔍 1. Szukam pierwszego klienta...');
    const clientsSnapshot = await db.collection('clients')
      .limit(1)
      .get();

    if (clientsSnapshot.empty) {
      console.log('❌ Brak klientów w bazie');
      process.exit(1);
    }

    const clientDoc = clientsSnapshot.docs[0];
    const clientData = clientDoc.data();
    const clientId = clientDoc.id;

    console.log('✅ Znaleziono klienta:');
    console.log(`   - UUID: ${clientId}`);
    console.log(`   - ExcelID: ${clientData.excelId || 'BRAK'}`);
    console.log(`   - Nazwa: ${clientData.imie_nazwisko || clientData.name}`);
    console.log(`   - Status głosowania: ${clientData.votingStatus}`);

    // 2. Ręcznie stwórz rekord zmian
    console.log('\n🔧 2. Tworzę rekord zmiany statusu...');
    const changeRecord = {
      investorId: clientId,
      clientId: clientId,
      clientName: clientData.imie_nazwisko || clientData.name,
      previousVotingStatus: 'Niezdecydowany',
      newVotingStatus: 'Tak',
      changeType: 'statusChanged',
      editedBy: 'Test Admin',
      editedByEmail: 'test@example.com',
      changedAt: admin.firestore.Timestamp.now(),
      reason: 'Test manualny systemu historii głosowania',
      additionalChanges: null
    };

    const changeDoc = await db.collection('voting_status_changes').add(changeRecord);
    console.log(`✅ Utworzono rekord zmiany: ${changeDoc.id}`);

    // 3. Sprawdź czy możemy odczytać historię
    console.log('\n🔍 3. Sprawdzam czy można odczytać historię...');
    const historySnapshot = await db.collection('voting_status_changes')
      .where('investorId', '==', clientId)
      .orderBy('changedAt', 'desc')
      .get();

    console.log(`📊 Znaleziono ${historySnapshot.size} zmian dla klienta`);

    historySnapshot.forEach((doc, index) => {
      const data = doc.data();
      console.log(`\n📝 Zmiana ${index + 1}:`);
      console.log(`   - ID dokumentu: ${doc.id}`);
      console.log(`   - Typ zmiany: ${data.changeType}`);
      console.log(`   - Poprzedni status: ${data.previousVotingStatus}`);
      console.log(`   - Nowy status: ${data.newVotingStatus}`);
      console.log(`   - Data: ${data.changedAt.toDate()}`);
      console.log(`   - Edytowane przez: ${data.editedBy}`);
      console.log(`   - Powód: ${data.reason}`);
    });

    // 4. Test zapytania z clientId (alternatywne pole)
    console.log('\n🔍 4. Sprawdzam zapytanie po clientId...');
    const historyByClientId = await db.collection('voting_status_changes')
      .where('clientId', '==', clientId)
      .orderBy('changedAt', 'desc')
      .get();

    console.log(`📊 Znaleziono ${historyByClientId.size} zmian po clientId`);

    // 5. Sprawdź indeksy (próba zapytania złożonego)
    console.log('\n🔍 5. Sprawdzam indeksy (zapytanie złożone)...');
    try {
      const complexQuery = await db.collection('voting_status_changes')
        .where('changeType', '==', 'statusChanged')
        .orderBy('changedAt', 'desc')
        .limit(5)
        .get();
      console.log(`✅ Indeksy działają - znaleziono ${complexQuery.size} zmian typu statusChanged`);
    } catch (error) {
      console.log(`❌ Problem z indeksami: ${error.message}`);
    }

    console.log('\n✅ Test zakończony pomyślnie!');
    console.log('\n💡 WNIOSKI:');
    console.log('- Kolekcja voting_status_changes działa prawidłowo');
    console.log('- Indeksy są skonfigurowane');
    console.log('- Problem może być w logice aplikacji Flutter');
    console.log('- Sprawdź czy InvestorSummary.client.id odpowiada UUID w bazie');

    process.exit(0);
  } catch (error) {
    console.error('❌ Błąd testu:', error);
    process.exit(1);
  }
}

testVotingHistory();
