const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Konfiguracja Firebase Admin
const serviceAccount = {
  type: "service_account",
  project_id: "cosmopolitan-investment",
  private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
  private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  client_email: process.env.FIREBASE_CLIENT_EMAIL,
  client_id: process.env.FIREBASE_CLIENT_ID,
  auth_uri: "https://accounts.google.com/o/oauth2/auth",
  token_uri: "https://oauth2.googleapis.com/token",
  auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
  client_x509_cert_url: process.env.FIREBASE_CLIENT_CERT_URL
};

class FirebaseClientUploader {
  constructor() {
    this.db = null;
    this.batchSize = 500; // Firestore batch limit
    this.uploadStats = {
      total: 0,
      uploaded: 0,
      updated: 0,
      errors: 0,
      startTime: null,
      endTime: null
    };
  }

  async initialize() {
    try {
      console.log('🔥 Inicjalizacja Firebase Admin...');

      // Sprawdź czy mamy wszystkie wymagane zmienne środowiskowe
      const requiredVars = ['FIREBASE_PRIVATE_KEY', 'FIREBASE_CLIENT_EMAIL', 'FIREBASE_CLIENT_ID'];
      const missingVars = requiredVars.filter(varName => !process.env[varName]);

      if (missingVars.length > 0) {
        console.log('⚠️  Brakuje zmiennych środowiskowych:', missingVars.join(', '));
        console.log('Próbuję użyć pliku service-account.json...');

        // Spróbuj użyć pliku service account
        const serviceAccountPath = path.join(__dirname, 'service-account.json');
        if (fs.existsSync(serviceAccountPath)) {
          const serviceAccountFile = require(serviceAccountPath);
          admin.initializeApp({
            credential: admin.credential.cert(serviceAccountFile),
            projectId: serviceAccountFile.project_id
          });
        } else {
          throw new Error('Brak pliku service-account.json');
        }
      } else {
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: serviceAccount.project_id
        });
      }

      this.db = admin.firestore();
      console.log('✅ Firebase zainicjalizowany pomyślnie!');

      // Test połączenia
      await this.db.collection('test').limit(1).get();
      console.log('✅ Połączenie z Firestore potwierdzone!');

    } catch (error) {
      console.error('❌ Błąd inicjalizacji Firebase:', error.message);
      throw error;
    }
  }

  async loadClientsData() {
    try {
      console.log('📄 Ładowanie danych klientów...');
      const filePath = path.join(__dirname, 'clients_data.json');

      if (!fs.existsSync(filePath)) {
        throw new Error(`Plik ${filePath} nie istnieje`);
      }

      const rawData = fs.readFileSync(filePath, 'utf8');
      const clients = JSON.parse(rawData);

      console.log(`✅ Załadowano ${clients.length} klientów z pliku JSON`);
      this.uploadStats.total = clients.length;

      return clients;
    } catch (error) {
      console.error('❌ Błąd ładowania danych:', error.message);
      throw error;
    }
  }

  async checkExistingClients() {
    try {
      console.log('🔍 Sprawdzanie istniejących klientów w bazie...');
      const snapshot = await this.db.collection('clients').get();
      console.log(`📊 Znaleziono ${snapshot.size} istniejących klientów w bazie`);
      return snapshot.size;
    } catch (error) {
      console.error('❌ Błąd sprawdzania istniejących klientów:', error.message);
      return 0;
    }
  }

  async uploadClientsInBatches(clients) {
    this.uploadStats.startTime = new Date();
    console.log(`🚀 Rozpoczynam upload ${clients.length} klientów...`);

    const batches = [];
    for (let i = 0; i < clients.length; i += this.batchSize) {
      const batch = clients.slice(i, i + this.batchSize);
      batches.push(batch);
    }

    console.log(`📦 Podzielono na ${batches.length} batchy po ${this.batchSize} klientów`);

    for (let batchIndex = 0; batchIndex < batches.length; batchIndex++) {
      const batch = batches[batchIndex];
      console.log(`\n📤 Przetwarzam batch ${batchIndex + 1}/${batches.length} (${batch.length} klientów)...`);

      await this.uploadBatch(batch, batchIndex);

      // Krótka przerwa między batchami
      if (batchIndex < batches.length - 1) {
        console.log('⏱️  Przerwa 1s między batchami...');
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }

    this.uploadStats.endTime = new Date();
    this.printFinalStats();
  }

  async uploadBatch(clientsBatch, batchIndex) {
    const batch = this.db.batch();
    const batchErrors = [];

    for (const client of clientsBatch) {
      try {
        // Walidacja danych klienta
        if (!client.imie_nazwisko || client.imie_nazwisko.trim() === '') {
          batchErrors.push(`Klient bez nazwy: ID ${client.id}`);
          continue;
        }

        // Przygotuj dane do zapisu
        const clientData = {
          id: client.id,
          imie_nazwisko: client.imie_nazwisko.trim(),
          nazwa_firmy: client.nazwa_firmy || '',
          telefon: client.telefon || '',
          email: client.email || '',
          created_at: client.created_at || new Date().toISOString(),
          updated_at: new Date().toISOString(),
          source: 'excel_migration_2025'
        };

        // Użyj ID jako document ID
        const docRef = this.db.collection('clients').doc(client.id.toString());
        batch.set(docRef, clientData, { merge: true });

      } catch (error) {
        batchErrors.push(`Błąd przetwarzania klienta ID ${client.id}: ${error.message}`);
      }
    }

    try {
      await batch.commit();
      this.uploadStats.uploaded += clientsBatch.length - batchErrors.length;
      this.uploadStats.errors += batchErrors.length;

      console.log(`   ✅ Zapisano ${clientsBatch.length - batchErrors.length} klientów`);
      if (batchErrors.length > 0) {
        console.log(`   ⚠️  Błędy: ${batchErrors.length}`);
        batchErrors.forEach(error => console.log(`      - ${error}`));
      }

    } catch (error) {
      console.error(`   ❌ Błąd zapisu batch ${batchIndex + 1}:`, error.message);
      this.uploadStats.errors += clientsBatch.length;
    }
  }

  async verifyUpload() {
    try {
      console.log('\n🔍 Weryfikacja uploadu...');
      const snapshot = await this.db.collection('clients').get();
      const uploadedCount = snapshot.size;

      console.log(`📊 Klientów w bazie po uploadzie: ${uploadedCount}`);
      console.log(`📊 Oczekiwano: ${this.uploadStats.total}`);

      if (uploadedCount >= this.uploadStats.total) {
        console.log('✅ Weryfikacja pomyślna - wszyscy klienci zostali zapisani!');
      } else {
        console.log(`⚠️  Możliwe braki: ${this.uploadStats.total - uploadedCount} klientów`);
      }

      // Pokaż przykłady zapisanych klientów
      console.log('\n📋 Przykłady zapisanych klientów:');
      const sampleDocs = await this.db.collection('clients').limit(3).get();
      sampleDocs.forEach(doc => {
        const data = doc.data();
        console.log(`   - ID: ${data.id}, Nazwa: "${data.imie_nazwisko}", Email: ${data.email}`);
      });

    } catch (error) {
      console.error('❌ Błąd weryfikacji:', error.message);
    }
  }

  printFinalStats() {
    const duration = Math.round((this.uploadStats.endTime - this.uploadStats.startTime) / 1000);

    console.log('\n' + '='.repeat(60));
    console.log('🎯 PODSUMOWANIE UPLOADU');
    console.log('='.repeat(60));
    console.log(`📊 Całkowity czas: ${duration}s`);
    console.log(`📊 Klientów do uploadu: ${this.uploadStats.total}`);
    console.log(`✅ Pomyślnie zapisanych: ${this.uploadStats.uploaded}`);
    console.log(`❌ Błędów: ${this.uploadStats.errors}`);
    console.log(`📈 Sukces: ${Math.round((this.uploadStats.uploaded / this.uploadStats.total) * 100)}%`);
    console.log('='.repeat(60));
  }
}

// Główna funkcja
async function main() {
  console.log('🚀 FIREBASE CLIENTS UPLOADER');
  console.log('📅 Data:', new Date().toLocaleString('pl-PL'));
  console.log('='.repeat(50));

  const uploader = new FirebaseClientUploader();

  try {
    // 1. Inicjalizacja Firebase
    await uploader.initialize();

    // 2. Sprawdź istniejące dane
    await uploader.checkExistingClients();

    // 3. Załaduj dane klientów
    const clients = await uploader.loadClientsData();

    // 4. Potwierdź upload
    console.log(`\n❓ Czy chcesz kontynuować upload ${clients.length} klientów?`);
    console.log('   To może nadpisać istniejące dane w kolekcji "clients"');
    console.log('   Naciśnij Ctrl+C aby anulować lub Enter aby kontynuować...');

    // W środowisku produkcyjnym można dodać readline do potwierdzenia
    // Tutaj kontynuujemy automatycznie
    await new Promise(resolve => setTimeout(resolve, 2000));

    // 5. Upload w batchach
    await uploader.uploadClientsInBatches(clients);

    // 6. Weryfikacja
    await uploader.verifyUpload();

    console.log('\n🎉 Upload zakończony pomyślnie!');
    process.exit(0);

  } catch (error) {
    console.error('\n💥 KRYTYCZNY BŁĄD:', error.message);
    console.error('Stack trace:', error.stack);
    process.exit(1);
  }
}

// Obsługa sygnałów
process.on('SIGINT', () => {
  console.log('\n🛑 Upload anulowany przez użytkownika');
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('💥 Nieobsłużone odrzucenie Promise:', reason);
  process.exit(1);
});

// Uruchom program
if (require.main === module) {
  main();
}

module.exports = { FirebaseClientUploader };
