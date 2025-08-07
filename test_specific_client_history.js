const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function testSpecificClient() {
  try {
    console.log('🧪 TEST: Sprawdzenie konkretnego klienta z testowej historii\n');

    const testClientId = '000d3538-9fe9-46e1-a178-7d577cc600b8'; // UUID z poprzedniego testu

    // 1. Sprawdź klienta
    console.log('🔍 1. Sprawdzam klienta...');
    const clientDoc = await db.collection('clients').doc(testClientId).get();

    if (!clientDoc.exists) {
      console.log('❌ Klient nie istnieje!');
      process.exit(1);
    }

    const clientData = clientDoc.data();
    console.log('✅ Klient istnieje:');
    console.log(`   - UUID: ${testClientId}`);
    console.log(`   - ExcelID: ${clientData.excelId}`);
    console.log(`   - Nazwa: ${clientData.imie_nazwisko || clientData.name}`);

    // 2. Sprawdź historię głosowania dla tego klienta
    console.log('\n🔍 2. Sprawdzam historię głosowania...');
    const historySnapshot = await db.collection('voting_status_changes')
      .where('investorId', '==', testClientId)
      .orderBy('changedAt', 'desc')
      .get();

    console.log(`📊 Historia głosowania: ${historySnapshot.size} zmian`);

    historySnapshot.forEach((doc, index) => {
      const data = doc.data();
      console.log(`\n📝 Zmiana ${index + 1}:`);
      console.log(`   - investorId: ${data.investorId}`);
      console.log(`   - clientId: ${data.clientId}`);
      console.log(`   - clientName: ${data.clientName}`);
      console.log(`   - changeType: ${data.changeType}`);
      console.log(`   - poprzedni: ${data.previousVotingStatus}`);
      console.log(`   - nowy: ${data.newVotingStatus}`);
      console.log(`   - data: ${data.changedAt.toDate()}`);
    });

    // 3. Sprawdź alternatywne zapytanie po clientId
    console.log('\n🔍 3. Sprawdzam zapytanie po clientId...');
    const altHistorySnapshot = await db.collection('voting_status_changes')
      .where('clientId', '==', testClientId)
      .orderBy('changedAt', 'desc')
      .get();

    console.log(`📊 Historia po clientId: ${altHistorySnapshot.size} zmian`);

    // 4. Stwórz dodatkowy rekord dla tego klienta
    console.log('\n🔧 4. Dodaję drugi rekord historii...');
    const secondChange = {
      investorId: testClientId,
      clientId: testClientId,
      clientName: clientData.imie_nazwisko || clientData.name,
      previousVotingStatus: 'Tak',
      newVotingStatus: 'Nie',
      changeType: 'statusChanged',
      editedBy: 'Test Admin 2',
      editedByEmail: 'test2@example.com',
      changedAt: admin.firestore.Timestamp.now(),
      reason: 'Drugi test - zmiana z Tak na Nie',
      additionalChanges: {
        'source': 'manual_test',
        'version': '2.0'
      }
    };

    await db.collection('voting_status_changes').add(secondChange);
    console.log('✅ Dodano drugi rekord');

    // 5. Sprawdź końcową historię
    console.log('\n🔍 5. Sprawdzam końcową historię...');
    const finalHistorySnapshot = await db.collection('voting_status_changes')
      .where('investorId', '==', testClientId)
      .orderBy('changedAt', 'desc')
      .get();

    console.log(`📊 Końcowa historia: ${finalHistorySnapshot.size} zmian`);

    finalHistorySnapshot.forEach((doc, index) => {
      const data = doc.data();
      console.log(`   ${index + 1}. ${data.previousVotingStatus} → ${data.newVotingStatus} (${data.editedBy})`);
    });

    console.log('\n✅ Test zakończony!');
    console.log('\n📋 INFORMACJE DLA TESTÓW FLUTTER:');
    console.log(`Client UUID: ${testClientId}`);
    console.log(`Client Name: ${clientData.imie_nazwisko || clientData.name}`);
    console.log(`Client ExcelId: ${clientData.excelId}`);
    console.log(`Historia changes: ${finalHistorySnapshot.size} rekordów`);

    process.exit(0);
  } catch (error) {
    console.error('❌ Błąd testu:', error);
    process.exit(1);
  }
}

testSpecificClient();
