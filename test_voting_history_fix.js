const admin = require('firebase-admin');

// Konfiguracja Firebase Admin
const serviceAccount = require('./service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function testVotingHistoryAfterFix() {
  try {
    console.log('=== TEST POPRAWKI ZAPISU HISTORII GŁOSOWANIA ===\n');

    const db = admin.firestore();

    // 1. Sprawdź kilku klientów
    console.log('🔍 1. Sprawdzanie klientów z UUID i excelId...');
    const clientsSnapshot = await db.collection('clients').limit(5).get();

    const testClients = [];
    clientsSnapshot.forEach(doc => {
      const data = doc.data();
      testClients.push({
        uuid: doc.id,
        excelId: data.excelId || data.id || 'BRAK',
        name: data.imie_nazwisko || data.name || 'BRAK NAZWY',
        votingStatus: data.votingStatus || 'undecided'
      });
    });

    console.log('📋 Znaleziono klientów:');
    testClients.forEach((client, index) => {
      console.log(`   ${index + 1}. UUID: ${client.uuid}, ExcelID: ${client.excelId}, Nazwa: "${client.name}", Status: ${client.votingStatus}`);
    });

    // 2. Sprawdź historię głosowania dla każdego klienta
    console.log('\n🔍 2. Sprawdzanie historii głosowania dla każdego klienta...');

    for (const client of testClients) {
      console.log(`\n   📊 Klient: ${client.name} (UUID: ${client.uuid})`);

      // Sprawdź przez UUID (investorId)
      const historyByUUID = await db.collection('voting_status_changes')
        .where('investorId', '==', client.uuid)
        .orderBy('changedAt', 'desc')
        .limit(5)
        .get();

      // Sprawdź przez clientId
      const historyByClientId = await db.collection('voting_status_changes')
        .where('clientId', '==', client.uuid)
        .orderBy('changedAt', 'desc')
        .limit(5)
        .get();

      // Sprawdź przez excelId (jeśli istnieje)
      let historyByExcelId = { size: 0, docs: [] };
      if (client.excelId !== 'BRAK' && client.excelId !== client.uuid) {
        try {
          historyByExcelId = await db.collection('voting_status_changes')
            .where('investorId', '==', client.excelId)
            .orderBy('changedAt', 'desc')
            .limit(5)
            .get();
        } catch (e) {
          // Ignoruj błędy dla excelId
        }
      }

      console.log(`      - Historia przez investorId (UUID): ${historyByUUID.size} rekordów`);
      console.log(`      - Historia przez clientId: ${historyByClientId.size} rekordów`);
      console.log(`      - Historia przez excelId: ${historyByExcelId.size} rekordów`);

      // Pokaż przykłady rekordów
      if (historyByUUID.size > 0) {
        const firstRecord = historyByUUID.docs[0].data();
        console.log(`        Przykład rekordu: ${firstRecord.changeDescription}`);
        console.log(`        Data: ${firstRecord.changedAt?.toDate()}`);
        console.log(`        Edytowane przez: ${firstRecord.editedBy}`);
      }
    }

    // 3. Sprawdź ogólne statystyki
    console.log('\n📊 3. Ogólne statystyki kolekcji voting_status_changes:');
    const allChanges = await db.collection('voting_status_changes').get();
    console.log(`   - Łączna liczba rekordów: ${allChanges.size}`);

    if (allChanges.size > 0) {
      const changeTypes = {};
      const editedBy = {};

      allChanges.forEach(doc => {
        const data = doc.data();
        changeTypes[data.changeType] = (changeTypes[data.changeType] || 0) + 1;
        editedBy[data.editedBy] = (editedBy[data.editedBy] || 0) + 1;
      });

      console.log('   - Typy zmian:', changeTypes);
      console.log('   - Edytowane przez:', editedBy);
    }

    // 4. Test zgodności ID
    console.log('\n🔗 4. Test zgodności ID w historii vs klientach:');
    let matchCount = 0;
    let mismatchCount = 0;

    for (const client of testClients) {
      const historyRecords = await db.collection('voting_status_changes')
        .where('investorId', '==', client.uuid)
        .get();

      if (historyRecords.size > 0) {
        matchCount++;
        console.log(`   ✅ ${client.name}: Historia zgodna z UUID`);
      } else {
        mismatchCount++;
        console.log(`   ❌ ${client.name}: Brak historii dla UUID`);
      }
    }

    console.log(`\n📈 Podsumowanie zgodności:`);
    console.log(`   - Zgodne: ${matchCount}`);
    console.log(`   - Niezgodne: ${mismatchCount}`);
    console.log(`   - Procent zgodności: ${(matchCount / testClients.length * 100).toFixed(1)}%`);

    console.log('\n✅ Test zakończony pomyślnie!');
    process.exit(0);

  } catch (error) {
    console.error('❌ Błąd podczas testowania:', error);
    process.exit(1);
  }
}

// Uruchom test
testVotingHistoryAfterFix();
