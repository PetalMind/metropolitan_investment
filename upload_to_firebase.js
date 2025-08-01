const admin = require('firebase-admin');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');

// Inicjalizacja Firebase Admin SDK
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function uploadInvestmentsWithClients() {
  try {
    console.log('Rozpoczynam wgrywanie danych z investments_with_clients.json...');

    // Wczytanie danych z pliku JSON
    const rawData = fs.readFileSync('./investments_with_clients.json', 'utf8');
    const investments = JSON.parse(rawData);

    console.log(`Znaleziono ${investments.length} rekordów do wgrania`);

    const batch = db.batch();
    let batchCount = 0;
    let totalUploaded = 0;

    for (let i = 0; i < investments.length; i++) {
      const investment = investments[i];

      // Generuj unikalny UUID dla dokumentu
      const docId = uuidv4();

      // Referencja do dokumentu w kolekcji 'investments'
      const docRef = db.collection('investments').doc(docId);

      // Dodaj do batcha
      batch.set(docRef, investment);
      batchCount++;

      // Firebase pozwala na maksymalnie 500 operacji w jednym batch
      if (batchCount === 500 || i === investments.length - 1) {
        await batch.commit();
        totalUploaded += batchCount;
        console.log(`Wgrano ${totalUploaded} z ${investments.length} rekordów...`);

        // Resetuj batch
        const newBatch = db.batch();
        Object.setPrototypeOf(batch, Object.getPrototypeOf(newBatch));
        Object.assign(batch, newBatch);
        batchCount = 0;
      }
    }

    console.log(`✅ Pomyślnie wgrano wszystkie ${totalUploaded} rekordów do kolekcji 'investments'`);

  } catch (error) {
    console.error('❌ Błąd podczas wgrywania danych:', error);
  } finally {
    // Zamknij połączenie
    process.exit(0);
  }
}

// Uruchom funkcję upload
uploadInvestmentsWithClients();
