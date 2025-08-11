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

class NormalizedClientsUploader {
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
    this.dryRun = false;
    this.cleanup = false;
    this.showReport = false;
  }

  async initialize() {
    try {
      console.log('🔥 Inicjalizacja Firebase Admin...');

      // Spróbuj użyć pliku service account (prostsze i bardziej niezawodne)
      const serviceAccountPath = path.join(__dirname, 'service-account.json');
      if (fs.existsSync(serviceAccountPath)) {
        console.log('📄 Używam pliku service-account.json...');
        const serviceAccountFile = require(serviceAccountPath);
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccountFile),
        });
      } else {
        console.log('⚠️  Brak pliku service-account.json, próbuję zmienne środowiskowe...');

        // Sprawdź czy mamy wszystkie wymagane zmienne środowiskowe
        const requiredVars = ['FIREBASE_PRIVATE_KEY', 'FIREBASE_CLIENT_EMAIL', 'FIREBASE_CLIENT_ID'];
        const missingVars = requiredVars.filter(varName => !process.env[varName]);

        if (missingVars.length > 0) {
          throw new Error(`Brakuje zmiennych środowiskowych: ${missingVars.join(', ')} lub pliku service-account.json`);
        }

        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: serviceAccount.project_id
        });
      }

      this.db = admin.firestore();
      console.log('✅ Firebase zainicjalizowany pomyślnie!');

      // Test połączenia - dopiero po inicjalizacji
      if (!this.dryRun) {
        await this.db.collection('clients').limit(1).get();
        console.log('✅ Połączenie z Firestore potwierdzone!');
      }

    } catch (error) {
      console.error('❌ Błąd inicjalizacji Firebase:', error.message);
      throw error;
    }
  }

  async loadNormalizedClientsData() {
    try {
      console.log('📄 Ładowanie znormalizowanych danych klientów...');
      const filePath = path.join(__dirname, 'split_investment_data_normalized', 'clients_normalized.json');

      if (!fs.existsSync(filePath)) {
        throw new Error(`Plik ${filePath} nie istnieje`);
      }

      const rawData = fs.readFileSync(filePath, 'utf8');
      const clients = JSON.parse(rawData);

      console.log(`✅ Załadowano ${clients.length} klientów z pliku znormalizowanego`);
      this.uploadStats.total = clients.length;

      // Pokaż przykład struktury danych
      if (clients.length > 0) {
        console.log('📋 Przykład struktury danych:');
        const sample = clients[0];
        Object.keys(sample).forEach(key => {
          console.log(`   ${key}: "${sample[key]}"`);
        });
      }

      return clients;
    } catch (error) {
      console.error('❌ Błąd ładowania danych:', error.message);
      throw error;
    }
  }

  async checkExistingClients() {
    if (this.dryRun) {
      console.log('🔍 (DRY RUN) Pomijam sprawdzanie istniejących klientów...');
      return 0;
    }

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

  async cleanupExistingClients() {
    if (this.dryRun) {
      console.log('🧹 (DRY RUN) Symulacja czyszczenia kolekcji clients...');
      return;
    }

    if (!this.cleanup) {
      console.log('⏭️  Pomijam czyszczenie (użyj --cleanup aby wyczyścić)');
      return;
    }

    try {
      console.log('🧹 Czyszczenie istniejącej kolekcji clients...');

      const batchSize = 500;
      const collection = this.db.collection('clients');

      let deletedCount = 0;
      let hasMore = true;

      while (hasMore) {
        const snapshot = await collection.limit(batchSize).get();

        if (snapshot.empty) {
          hasMore = false;
          break;
        }

        const batch = this.db.batch();
        snapshot.docs.forEach(doc => {
          batch.delete(doc.ref);
        });

        await batch.commit();
        deletedCount += snapshot.size;
        console.log(`   🗑️  Usunięto ${deletedCount} dokumentów...`);
      }

      console.log(`✅ Wyczyszczono ${deletedCount} istniejących klientów`);
    } catch (error) {
      console.error('❌ Błąd czyszczenia:', error.message);
      throw error;
    }
  }

  async uploadClientsInBatches(clients) {
    this.uploadStats.startTime = new Date();
    console.log(`🚀 ${this.dryRun ? '(DRY RUN) ' : ''}Rozpoczynam upload ${clients.length} klientów...`);

    const batches = [];
    for (let i = 0; i < clients.length; i += this.batchSize) {
      const batch = clients.slice(i, i + this.batchSize);
      batches.push(batch);
    }

    console.log(`📦 Podzielono na ${batches.length} batchy po ${this.batchSize} klientów`);

    for (let batchIndex = 0; batchIndex < batches.length; batchIndex++) {
      const batch = batches[batchIndex];
      console.log(`\n📤 ${this.dryRun ? '(DRY RUN) ' : ''}Przetwarzam batch ${batchIndex + 1}/${batches.length} (${batch.length} klientów)...`);

      await this.uploadBatch(batch, batchIndex);

      // Krótka przerwa między batchami
      if (batchIndex < batches.length - 1 && !this.dryRun) {
        console.log('⏱️  Przerwa 1s między batchami...');
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }

    this.uploadStats.endTime = new Date();
    this.printFinalStats();
  }

  async uploadBatch(clientsBatch, batchIndex) {
    const batchErrors = [];

    if (this.dryRun) {
      // Symulacja - tylko walidacja danych
      for (const client of clientsBatch) {
        try {
          this.validateAndTransformClient(client);
        } catch (error) {
          batchErrors.push(`Błąd walidacji klienta ID ${client.id}: ${error.message}`);
        }
      }

      this.uploadStats.uploaded += clientsBatch.length - batchErrors.length;
      this.uploadStats.errors += batchErrors.length;

      console.log(`   ✅ (DRY RUN) Zwalidowano ${clientsBatch.length - batchErrors.length} klientów`);
      if (batchErrors.length > 0) {
        console.log(`   ⚠️  Błędy walidacji: ${batchErrors.length}`);
        if (this.showReport || batchErrors.length <= 5) {
          batchErrors.forEach(error => console.log(`      - ${error}`));
        } else {
          console.log(`      - ${batchErrors[0]}`);
          console.log(`      - ${batchErrors[1] || '...'}`);
          console.log(`      ... i ${batchErrors.length - 2} więcej (użyj --report dla pełnej listy)`);
        }
      }
      return;
    }

    // Rzeczywisty upload
    const batch = this.db.batch();

    for (const client of clientsBatch) {
      try {
        const clientData = this.validateAndTransformClient(client);

        // Używaj ID klienta jako document ID w Firestore
        const documentId = client.id.toString();
        const docRef = this.db.collection('clients').doc(documentId);
        batch.set(docRef, clientData, { merge: true });

        // Loguj mapowanie ID dla debugowania (tylko pierwszy w batchu + przykłady spółek)
        if (clientsBatch.indexOf(client) === 0) {
          console.log(`   🔗 Document ID: ${documentId} (używam oryginalnego ID klienta)`);
        }

        // Loguj przykłady spółek (gdy używamy companyName jako fullName)
        const fullName = client.fullName ? client.fullName.trim() : '';
        const companyName = client.companyName ? client.companyName.trim() : '';
        if ((fullName === '' || fullName === ' ') && companyName !== '' && clientsBatch.indexOf(client) < 3) {
          console.log(`   🏢 ID ${client.id}: Spółka "${companyName}" -> fullName`);
        }

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
        if (this.showReport || batchErrors.length <= 5) {
          // Pokaż błędy jeśli jest raport lub mało błędów
          batchErrors.forEach(error => console.log(`      - ${error}`));
        } else {
          // Pokaż tylko kilka pierwszych błędów
          console.log(`      - ${batchErrors[0]}`);
          console.log(`      - ${batchErrors[1] || '...'}`);
          console.log(`      ... i ${batchErrors.length - 2} więcej (użyj --report dla pełnej listy)`);
        }
      }

    } catch (error) {
      console.error(`   ❌ Błąd zapisu batch ${batchIndex + 1}:`, error.message);
      this.uploadStats.errors += clientsBatch.length;
    }
  }

  validateAndTransformClient(client) {
    // Walidacja wymaganych pól
    if (!client.id) {
      throw new Error('Brak pola id');
    }

    // Sprawdź fullName - jeśli puste, użyj companyName
    let fullName = client.fullName ? client.fullName.trim() : '';
    let companyName = client.companyName ? client.companyName.trim() : '';

    if (fullName === '' || fullName === ' ') {
      if (companyName !== '') {
        // Dla spółek użyj companyName jako fullName
        fullName = companyName;
        console.log(`   🏢 ID ${client.id}: Używam companyName "${companyName}" jako fullName`);
      } else {
        throw new Error('Brak fullName i companyName');
      }
    }

    // Transformacja danych zgodna z żądaną strukturą Firebase
    const clientData = {
      // Główne pola - prosta struktura
      id: client.id, // Numeryczne ID
      fullName: fullName,
      companyName: companyName,
      phone: client.phone || "",
      email: client.email || "",

      // Metadane
      dataVersion: "2.0",
      migrationSource: "normalized_json_import",

      // Daty jako Firebase Timestamps
      createdAt: admin.firestore.Timestamp.fromDate(
        client.created_at ? new Date(client.created_at) : new Date()
      ),
      uploadedAt: admin.firestore.Timestamp.fromDate(new Date())
    };

    return clientData;
  }

  async verifyUpload() {
    if (this.dryRun) {
      console.log('\n🔍 (DRY RUN) Symulacja weryfikacji zakończona');
      return;
    }

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
      if (this.showReport) {
        console.log('\n📋 Przykłady zapisanych klientów:');
        const sampleDocs = await this.db.collection('clients').limit(5).get();
        sampleDocs.forEach((doc, index) => {
          const data = doc.data();
          console.log(`   ${index + 1}. Document ID: ${doc.id}`);
          console.log(`      id: ${data.id} (number)`);
          console.log(`      fullName: "${data.fullName}"`);
          console.log(`      companyName: "${data.companyName}"`);
          console.log(`      email: "${data.email}"`);
          console.log(`      phone: "${data.phone}"`);
          console.log(`      dataVersion: "${data.dataVersion}"`);
          console.log(`      migrationSource: "${data.migrationSource}"`);
          console.log('');
        });
      }

    } catch (error) {
      console.error('❌ Błąd weryfikacji:', error.message);
    }
  }

  async generateReport() {
    if (!this.showReport) return;

    try {
      console.log('\n📊 SZCZEGÓŁOWY RAPORT:');
      console.log('='.repeat(50));

      if (this.dryRun) {
        console.log('🔍 TRYB DRY RUN - dane nie zostały zapisane');
      } else {
        const snapshot = await this.db.collection('clients').get();

        // Statystyki emaili
        let withEmail = 0;
        let withPhone = 0;
        let withCompany = 0;
        let uniqueEmails = new Set();

        snapshot.forEach(doc => {
          const data = doc.data();
          if (data.email && data.email.trim() !== '') {
            withEmail++;
            uniqueEmails.add(data.email.toLowerCase());
          }
          if (data.phone && data.phone.trim() !== '') {
            withPhone++;
          }
          if (data.companyName && data.companyName.trim() !== '') {
            withCompany++;
          }
        });

        console.log(`📧 Klienci z emailem: ${withEmail} (${Math.round(withEmail / snapshot.size * 100)}%)`);
        console.log(`📱 Klienci z telefonem: ${withPhone} (${Math.round(withPhone / snapshot.size * 100)}%)`);
        console.log(`🏢 Klienci z firmą: ${withCompany} (${Math.round(withCompany / snapshot.size * 100)}%)`);
        console.log(`🔄 Unikalne emaile: ${uniqueEmails.size}`);

        if (withEmail !== uniqueEmails.size) {
          console.log(`⚠️  Duplikaty emaili: ${withEmail - uniqueEmails.size}`);
        }

        // Analiza błędów jeśli były
        if (this.uploadStats.errors > 0) {
          console.log('\n🔍 ANALIZA BŁĘDÓW:');
          await this.analyzeFailedRecords();
        }
      }

    } catch (error) {
      console.error('❌ Błąd generowania raportu:', error.message);
    }
  }

  async analyzeFailedRecords() {
    try {
      console.log('📋 Sprawdzanie które rekordy nie zostały zapisane...');

      // Załaduj oryginalne dane
      const originalClients = await this.loadNormalizedClientsData();

      // Pobierz zapisane ID z Firebase
      const snapshot = await this.db.collection('clients').get();
      const savedIds = new Set();

      snapshot.forEach(doc => {
        savedIds.add(parseInt(doc.id));
      });

      // Znajdź brakujące rekordy
      const missingRecords = originalClients.filter(client => !savedIds.has(client.id));

      console.log(`❌ Rekordy nie zapisane (${missingRecords.length}):`);
      missingRecords.slice(0, 10).forEach(client => {
        console.log(`   ID: ${client.id}, Nazwa: "${client.fullName}"`);

        // Sprawdź co mogło być nie tak
        const issues = [];
        if (!client.fullName || client.fullName.trim() === '') issues.push('brak fullName');
        if (!client.id) issues.push('brak id');
        if (typeof client.id !== 'number') issues.push('id nie jest liczbą');

        if (issues.length > 0) {
          console.log(`      Problemy: ${issues.join(', ')}`);
        }
      });

      if (missingRecords.length > 10) {
        console.log(`   ... i ${missingRecords.length - 10} więcej`);
      }

      // Sugestie naprawy
      if (missingRecords.length > 0) {
        console.log('\n💡 SUGESTIE NAPRAWY:');
        console.log('   1. Uruchom ponownie upload - niektóre błędy mogą być przejściowe');
        console.log('   2. Sprawdź czy brakujące rekordy mają prawidłowe dane');
        console.log('   3. Użyj --cleanup aby wyczyścić i spróbować ponownie');
      }

    } catch (error) {
      console.error('❌ Błąd analizy błędnych rekordów:', error.message);
    }
  }

  printFinalStats() {
    const duration = this.uploadStats.endTime && this.uploadStats.startTime ?
      Math.round((this.uploadStats.endTime - this.uploadStats.startTime) / 1000) : 0;

    console.log('\n' + '='.repeat(60));
    console.log(`🎯 PODSUMOWANIE ${this.dryRun ? '(DRY RUN) ' : ''}UPLOADU ZNORMALIZOWANYCH KLIENTÓW`);
    console.log('='.repeat(60));
    console.log(`📊 Całkowity czas: ${duration}s`);
    console.log(`📊 Klientów do uploadu: ${this.uploadStats.total}`);
    console.log(`✅ Pomyślnie ${this.dryRun ? 'zwalidowanych' : 'zapisanych'}: ${this.uploadStats.uploaded}`);
    console.log(`❌ Błędów: ${this.uploadStats.errors}`);
    console.log(`📈 Sukces: ${this.uploadStats.total > 0 ? Math.round((this.uploadStats.uploaded / this.uploadStats.total) * 100) : 0}%`);
    console.log('');
    console.log('🔗 STRUKTURA DANYCH:');
    console.log('   • Źródło: split_investment_data_normalized/clients_normalized.json');
    console.log('   • Document ID: Oryginalne ID klienta (string)');
    console.log('   • id: Numeryczne ID (number)');
    console.log('   • fullName: Pełna nazwa klienta (string)');
    console.log('   • companyName: Nazwa firmy (string)');
    console.log('   • phone: Telefon (string)');
    console.log('   • email: Email (string)');
    console.log('   • dataVersion: "2.0" (string)');
    console.log('   • migrationSource: "normalized_json_import" (string)');
    console.log('   • createdAt/uploadedAt: Firebase Timestamps');
    console.log('');
    console.log('💡 UŻYCIE:');
    console.log('   node upload_normalized_clients.js                 # Normalny upload');
    console.log('   node upload_normalized_clients.js --dry-run       # Symulacja (bez zapisu)');
    console.log('   node upload_normalized_clients.js --cleanup       # Wyczyść przed uploadem');
    console.log('   node upload_normalized_clients.js --report        # Szczegółowy raport');
    console.log('   node upload_normalized_clients.js --cleanup --report # Pełny tryb');
    console.log('='.repeat(60));
  }
}

// Główna funkcja
async function main() {
  console.log('🚀 NORMALIZED CLIENTS UPLOADER v1.0');
  console.log('📅 Data:', new Date().toLocaleString('pl-PL'));
  console.log('='.repeat(50));

  // Sprawdź argumenty wiersza poleceń
  const args = process.argv.slice(2);

  const uploader = new NormalizedClientsUploader();
  uploader.dryRun = args.includes('--dry-run');
  uploader.cleanup = args.includes('--cleanup');
  uploader.showReport = args.includes('--report');

  if (uploader.dryRun) {
    console.log('🔧 Tryb DRY RUN: symulacja bez zapisu do bazy');
  }
  if (uploader.cleanup && !uploader.dryRun) {
    console.log('🧹 Tryb CLEANUP: wyczyszczenie kolekcji przed uploadem');
  }
  if (uploader.showReport) {
    console.log('📊 Tryb REPORT: szczegółowe raporty i statystyki');
  }

  try {
    // 1. Inicjalizacja Firebase
    await uploader.initialize();

    // 2. Sprawdź istniejące dane
    await uploader.checkExistingClients();

    // 3. Czyszczenie (jeśli wymagane)
    await uploader.cleanupExistingClients();

    // 4. Załaduj znormalizowane dane klientów
    const clients = await uploader.loadNormalizedClientsData();

    // 5. Potwierdź upload (jeśli nie dry run)
    if (!uploader.dryRun) {
      console.log(`\n❓ Czy chcesz kontynuować upload ${clients.length} znormalizowanych klientów?`);
      console.log('   Naciśnij Ctrl+C aby anulować lub Enter aby kontynuować...');
      // W środowisku produkcyjnym można dodać readline do potwierdzenia
      await new Promise(resolve => setTimeout(resolve, 2000));
    }

    // 6. Upload w batchach
    await uploader.uploadClientsInBatches(clients);

    // 7. Weryfikacja
    await uploader.verifyUpload();

    // 8. Szczegółowy raport
    await uploader.generateReport();

    console.log(`\n🎉 ${uploader.dryRun ? 'Symulacja' : 'Upload'} zakończon${uploader.dryRun ? 'a' : 'y'} pomyślnie!`);
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

module.exports = { NormalizedClientsUploader };
