// Test minimalny na wzór działającego upload_clients_with_uuid.js
const fs = require('fs');
const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');

// Inicjalizacja Firebase na wzór działającego skryptu
admin.initializeApp({
  credential: admin.credential.cert(require('./service-account.json')),
});

const db = admin.firestore();

// KLUCZOWE: Podłączenie do lokalnego emulatora Firestore
console.log('🔧 Podłączanie do emulatora Firestore (localhost:8080)...');
db.settings({
  host: 'localhost:8080',
  ssl: false
});

async function testMinimal() {
  console.log('🧪 TEST MINIMALNY (wzór upload_clients_with_uuid.js)');
  console.log('='.repeat(50));

  try {
    // Test połączenia - próba prostego query z timeoutem
    console.log('📡 Sprawdzanie połączenia...');

    const timeoutPromise = new Promise((_, reject) =>
      setTimeout(() => reject(new Error('Timeout - emulator może nie odpowiadać')), 10000)
    );

    const queryPromise = db.collection('clients').limit(1).get();

    const snapshot = await Promise.race([queryPromise, timeoutPromise]);
    console.log(`✅ Połączenie OK! Znaleziono ${snapshot.size} dokumentów w kolekcji clients`);

    // Sprawdź czy plik danych istnieje
    const dataFiles = ['clients_data.json', 'clients_data_complete.json'];
    let dataFile = null;

    for (const file of dataFiles) {
      if (fs.existsSync(file)) {
        dataFile = file;
        console.log(`✅ Znaleziono plik z danymi: ${file}`);
        break;
      }
    }

    if (!dataFile) {
      console.log('⚠️  Brak plików z danymi, ale test połączenia przeszedł!');
    } else {
      const data = JSON.parse(fs.readFileSync(dataFile, 'utf8'));
      console.log(`✅ Załadowano ${data.length} klientów z pliku ${dataFile}`);
    }

    console.log('\n🎉 Test minimalny SUKCES - Firebase działa!');
    process.exit(0);

  } catch (error) {
    console.error('❌ Test minimalny BŁĄD:', error.message);
    process.exit(1);
  }
}

testMinimal();
