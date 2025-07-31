// Skrypt do wgrywania danych z clients_data.json do Firebase z UUID jako klucz dokumentu
// Upewnij się, że masz zainstalowane firebase-admin: npm install firebase-admin uuid

const fs = require('fs');
const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');

// Ścieżka do pliku z danymi
const DATA_PATH = './clients_data.json';

// Ścieżka do pliku z kluczem serwisowym Firebase
const SERVICE_ACCOUNT_PATH = './service-account.json';

// Nazwa kolekcji w Firestore
const COLLECTION_NAME = 'clients';

// Inicjalizacja Firebase
admin.initializeApp({
  credential: admin.credential.cert(require(SERVICE_ACCOUNT_PATH)),
});

const db = admin.firestore();

async function uploadClients() {
  const data = JSON.parse(fs.readFileSync(DATA_PATH, 'utf8'));
  if (!Array.isArray(data)) {
    console.error('Plik JSON powinien zawierać tablicę obiektów.');
    process.exit(1);
  }

  for (const client of data) {
    const docId = uuidv4(); // Generuj UUID jako klucz dokumentu
    await db.collection(COLLECTION_NAME).doc(docId).set(client);
    console.log(`Dodano klienta z oryginalnym id: ${client.id} do dokumentu o UUID: ${docId}`);
  }
  console.log('Wszystkie dane zostały przesłane.');
}

uploadClients().catch(console.error);
