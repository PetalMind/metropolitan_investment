const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkInvestmentClientMapping() {
  try {
    console.log('=== Sprawdzanie mapowania klienta w inwestycjach ===');

    // Pobierz jedną inwestycję z clientId 254
    const investmentsSnapshot = await db.collection('investments')
      .where('clientId', '==', '254')
      .limit(1)
      .get();

    if (!investmentsSnapshot.empty) {
      const investment = investmentsSnapshot.docs[0];
      console.log('Inwestycja z clientId 254:', investment.data());
    }

    // Sprawdź czy klient o id 269 istnieje
    const clientsSnapshot = await db.collection('clients')
      .where('id', '==', 269)
      .limit(1)
      .get();

    if (!clientsSnapshot.empty) {
      const client = clientsSnapshot.docs[0];
      console.log('\nKlient o numerycznym ID 269:');
      console.log('Document ID:', client.id);
      console.log('Data:', client.data());
    }

    // Sprawdź czy istnieje mapowanie przez excelId
    const clientsByExcelId = await db.collection('clients')
      .where('excelId', '==', '254')
      .limit(1)
      .get();

    if (!clientsByExcelId.empty) {
      const client = clientsByExcelId.docs[0];
      console.log('\nKlient o excelId 254:');
      console.log('Document ID:', client.id);
      console.log('Data:', client.data());
    }

    process.exit(0);
  } catch (error) {
    console.error('Błąd:', error);
    process.exit(1);
  }
}

checkInvestmentClientMapping();
