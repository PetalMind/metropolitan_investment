#!/usr/bin/env node
/**
 * Skrypt do uploadowania klientów z clients_normalized.json do Firebase Firestore
 * Używa Service Account do autoryzacji i zachowuje strukturę zgodną z istniejącymi dokumentami
 */

const admin = require('firebase-admin');
const fs = require('fs').promises;
const path = require('path');

// Inicjalizacja Firebase Admin SDK
const serviceAccount = require('./ServiceAccount.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'metropolitan-investment'
});

const db = admin.firestore();

/**
 * Konwertuje string timestamp na Firebase Timestamp
 * @param {string} dateString - Data w formacie ISO string
 * @returns {admin.firestore.Timestamp} Firebase Timestamp
 */
function convertToFirebaseTimestamp(dateString) {
  if (!dateString) return null;
  try {
    const date = new Date(dateString);
    return admin.firestore.Timestamp.fromDate(date);
  } catch (error) {
    console.warn(`Błąd konwersji daty: ${dateString}`, error);
    return admin.firestore.Timestamp.now();
  }
}

/**
 * Mapuje dane klienta z JSON na format Firebase zgodny z istniejącą strukturą
 * @param {Object} client - Dane klienta z JSON
 * @returns {Object} Dane klienta w formacie Firebase
 */
function mapClientToFirebaseFormat(client) {
  const now = new Date();
  const nowTimestamp = admin.firestore.Timestamp.now();
  const nowString = now.toISOString();

  return {
    // Podstawowe identyfikatory
    documentId: client.id || '',
    original_id: client.id || '',
    excelId: client.excelId || client.id || '',

    // Dane osobowe - wersje angielskie
    fullName: client.fullName || '',
    name: client.name || client.fullName || '',
    email: client.email || '',
    phone: client.phone || '',
    address: client.address || '',
    pesel: client.pesel,
    companyName: client.companyName,
    type: client.type || 'individual',
    notes: client.notes || '',

    // Dane osobowe - wersje polskie (dla kompatybilności)
    imie_nazwisko: client.fullName || client.name || '',
    nazwa_firmy: client.companyName || '',
    telefon: client.phone || '',

    // Metadane systemu
    isActive: client.isActive !== undefined ? client.isActive : true,
    colorCode: client.colorCode || '#FFFFFF',
    votingStatus: client.votingStatus || 'undecided',

    // Timestampy - wersje Timestamp
    createdAt: convertToFirebaseTimestamp(client.createdAt),
    updatedAt: convertToFirebaseTimestamp(client.updatedAt),
    uploadedAt_timestamp: nowTimestamp,

    // Timestampy - wersje string
    created_at: client.createdAt || nowString,
    uploadedAt: client.updatedAt || nowString,
    uploaded_at: client.updatedAt || nowString,

    // Metadane uploadu
    uploadedBy: 'batch_upload_script_normalized',
    sourceFile: 'clients_normalized.json',
    source_file: 'clients_normalized.json',

    // Inwestycje nieważne
    unviableInvestments: client.unviableInvestments || [],

    // Dodatkowe informacje
    additionalInfo: {
      originalClientId: client.id || '',
      extractedAt: client.createdAt || nowString,
      sourceFile: 'clients_normalized.json',
      ...((client.additionalInfo && typeof client.additionalInfo === 'object') ? client.additionalInfo : {})
    }
  };
}

/**
 * Ładuje dane klientów z pliku JSON
 * @param {string} filePath - Ścieżka do pliku JSON
 * @returns {Promise<Array>} Tablica klientów
 */
async function loadClientsData(filePath) {
  try {
    console.log(`📂 Ładowanie danych z: ${filePath}`);
    const data = await fs.readFile(filePath, 'utf8');
    const clients = JSON.parse(data);

    // Filtrowanie pustych obiektów
    const validClients = clients.filter(client =>
      client &&
      typeof client === 'object' &&
      client.id &&
      client.fullName
    );

    console.log(`✅ Załadowano ${validClients.length} prawidłowych klientów (z ${clients.length} rekordów)`);
    return validClients;
  } catch (error) {
    console.error('❌ Błąd podczas ładowania pliku:', error);
    throw error;
  }
}

/**
 * Sprawdza czy klient już istnieje w Firestore
 * @param {string} clientId - ID klienta
 * @returns {Promise<boolean>} True jeśli istnieje
 */
async function clientExists(clientId) {
  try {
    const doc = await db.collection('clients').doc(clientId).get();
    return doc.exists;
  } catch (error) {
    console.warn(`⚠️ Błąd sprawdzania istnienia klienta ${clientId}:`, error);
    return false;
  }
}

/**
 * Dodaje pojedynczego klienta do Firestore
 * @param {Object} clientData - Dane klienta
 * @param {boolean} overwrite - Czy nadpisywać istniejące dokumenty
 * @returns {Promise<Object>} Wynik operacji
 */
async function addClientToFirestore(clientData, overwrite = false) {
  try {
    const clientId = clientData.documentId;

    // Sprawdzenie czy klient już istnieje
    if (!overwrite) {
      const exists = await clientExists(clientId);
      if (exists) {
        return {
          success: false,
          clientId,
          reason: 'already_exists'
        };
      }
    }

    // Dodanie/aktualizacja klienta
    await db.collection('clients').doc(clientId).set(clientData, { merge: overwrite });

    return {
      success: true,
      clientId,
      action: overwrite ? 'updated' : 'created'
    };

  } catch (error) {
    console.error(`❌ Błąd dodawania klienta ${clientData.documentId}:`, error);
    return {
      success: false,
      clientId: clientData.documentId,
      reason: 'error',
      error: error.message
    };
  }
}

/**
 * Główna funkcja uploadująca wszystkich klientów
 * @param {Object} options - Opcje uploadu
 */
async function uploadAllClients(options = {}) {
  const {
    overwrite = false,
    batchSize = 50,
    dryRun = false
  } = options;

  console.log('🚀 Rozpoczynanie uploadu klientów do Firebase...');
  console.log(`📋 Opcje: overwrite=${overwrite}, batchSize=${batchSize}, dryRun=${dryRun}`);

  try {
    // Ładowanie danych
    const clientsFile = path.join(__dirname, 'split_investment_data_normalized', 'clients_normalized.json');
    const clients = await loadClientsData(clientsFile);

    if (clients.length === 0) {
      console.log('⚠️ Brak klientów do przetworzenia');
      return;
    }

    // Statystyki
    const stats = {
      total: clients.length,
      processed: 0,
      created: 0,
      updated: 0,
      skipped: 0,
      errors: 0
    };

    console.log(`\n📊 Rozpoczynanie przetwarzania ${stats.total} klientów...`);

    // Przetwarzanie w batches
    for (let i = 0; i < clients.length; i += batchSize) {
      const batch = clients.slice(i, i + batchSize);

      console.log(`\n📦 Batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(clients.length / batchSize)} (${batch.length} klientów)`);

      // Przetwarzanie każdego klienta w batch
      const batchPromises = batch.map(async (client, index) => {
        try {
          const clientData = mapClientToFirebaseFormat(client);

          if (dryRun) {
            console.log(`🔍 [DRY RUN] Klient ${client.id}: ${client.fullName}`);
            return { success: true, clientId: client.id, action: 'dry_run' };
          }

          const result = await addClientToFirestore(clientData, overwrite);

          // Logowanie postępu
          if (result.success) {
            const action = result.action === 'created' ? '✅' : '🔄';
            console.log(`${action} ${client.id}: ${client.fullName}`);
          } else if (result.reason === 'already_exists') {
            console.log(`⏭️ ${client.id}: ${client.fullName} (już istnieje)`);
          } else {
            console.log(`❌ ${client.id}: ${client.fullName} (błąd: ${result.reason})`);
          }

          return result;

        } catch (error) {
          console.error(`❌ Błąd przetwarzania klienta ${client.id}:`, error);
          return {
            success: false,
            clientId: client.id,
            reason: 'processing_error',
            error: error.message
          };
        }
      });

      // Czekanie na zakończenie batch
      const batchResults = await Promise.all(batchPromises);

      // Aktualizacja statystyk
      batchResults.forEach(result => {
        stats.processed++;
        if (result.success) {
          if (result.action === 'created') stats.created++;
          else if (result.action === 'updated') stats.updated++;
        } else {
          if (result.reason === 'already_exists') stats.skipped++;
          else stats.errors++;
        }
      });

      // Krótka przerwa między batches
      if (i + batchSize < clients.length) {
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }

    // Podsumowanie
    console.log('\n' + '='.repeat(50));
    console.log('📊 PODSUMOWANIE UPLOADU');
    console.log('='.repeat(50));
    console.log(`📋 Łącznie przetworzonych: ${stats.processed}/${stats.total}`);
    console.log(`✅ Utworzonych: ${stats.created}`);
    console.log(`🔄 Zaktualizowanych: ${stats.updated}`);
    console.log(`⏭️ Pominiętych (już istnieją): ${stats.skipped}`);
    console.log(`❌ Błędów: ${stats.errors}`);
    console.log('='.repeat(50));

    if (stats.errors === 0) {
      console.log('🎉 Upload zakończony pomyślnie!');
    } else {
      console.log('⚠️ Upload zakończony z błędami. Sprawdź logi powyżej.');
    }

  } catch (error) {
    console.error('💥 Krytyczny błąd podczas uploadu:', error);
    process.exit(1);
  }
}

/**
 * Funkcja testowa - sprawdza połączenie z Firebase
 */
async function testFirebaseConnection() {
  try {
    console.log('🔍 Testowanie połączenia z Firebase...');

    // Test zapisu
    const testDoc = db.collection('test').doc('connection_test');
    await testDoc.set({
      timestamp: admin.firestore.Timestamp.now(),
      message: 'Test connection'
    });

    // Test odczytu
    const doc = await testDoc.get();
    if (doc.exists) {
      console.log('✅ Połączenie z Firebase działa poprawnie');

      // Usunięcie dokumentu testowego
      await testDoc.delete();
      return true;
    }

    return false;
  } catch (error) {
    console.error('❌ Błąd połączenia z Firebase:', error);
    return false;
  }
}

// Uruchomienie skryptu
async function main() {
  // Parsowanie argumentów
  const args = process.argv.slice(2);
  const options = {
    overwrite: args.includes('--overwrite') || args.includes('-o'),
    dryRun: args.includes('--dry-run') || args.includes('-d'),
    test: args.includes('--test') || args.includes('-t'),
    batchSize: 50
  };

  // Wyświetlenie pomocy
  if (args.includes('--help') || args.includes('-h')) {
    console.log(`
📚 Skrypt uploadu klientów do Firebase

Użycie:
  node upload_clients_to_firebase.js [opcje]

Opcje:
  --overwrite, -o     Nadpisuj istniejące dokumenty
  --dry-run, -d       Symulacja (bez zapisywania)
  --test, -t          Tylko test połączenia
  --help, -h          Pokaż tę pomoc

Przykłady:
  node upload_clients_to_firebase.js                    # Normalny upload (pomija istniejące)
  node upload_clients_to_firebase.js --dry-run          # Symulacja
  node upload_clients_to_firebase.js --overwrite        # Z nadpisywaniem
  node upload_clients_to_firebase.js --test             # Test połączenia
    `);
    process.exit(0);
  }

  try {
    // Test połączenia jeśli wymagany
    if (options.test) {
      const connected = await testFirebaseConnection();
      process.exit(connected ? 0 : 1);
    }

    // Test połączenia przed głównym uploadem
    console.log('🔍 Sprawdzanie połączenia z Firebase...');
    const connected = await testFirebaseConnection();
    if (!connected) {
      console.error('❌ Nie można nawiązać połączenia z Firebase. Sprawdź konfigurację.');
      process.exit(1);
    }

    // Główny upload
    await uploadAllClients(options);

  } catch (error) {
    console.error('💥 Nieoczekiwany błąd:', error);
    process.exit(1);
  } finally {
    // Zakończenie połączenia
    console.log('👋 Zamykanie połączenia...');
    process.exit(0);
  }
}

// Export funkcji dla użycia jako moduł
module.exports = {
  uploadAllClients,
  mapClientToFirebaseFormat,
  testFirebaseConnection
};

// Uruchomienie jeśli skrypt wywołany bezpośrednio
if (require.main === module) {
  main();
}
